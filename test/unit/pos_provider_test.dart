import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';
import 'package:kas_usaha/features/pos/pos.dart';

void main() {
  group('POS State Management & Providers Unit Tests', () {
    late ProviderContainer container;
    late MockProductRepository mockProductRepo;

    final testProducts = [
      Product(
        id: 'prod-01',
        categoryId: 'cat-01',
        categoryName: 'Makanan',
        sku: 'MKN-01',
        barcode: '111111',
        name: 'Nasi Goreng Spesial',
        sellingPrice: 25000,
        costPrice: 15000,
        stock: 10,
        trackStock: true,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-02',
        categoryId: 'cat-02',
        categoryName: 'Minuman',
        sku: 'MNM-01',
        barcode: '222222',
        name: 'Es Teh Manis',
        sellingPrice: 5000,
        costPrice: 2000,
        stock: 2, // Low stock
        trackStock: true,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-03',
        categoryId: 'cat-02',
        categoryName: 'Minuman',
        sku: 'MNM-02',
        barcode: '333333',
        name: 'Kopi Tubruk Panas',
        sellingPrice: 8000,
        costPrice: 3000,
        stock: 0, // Out of stock
        trackStock: true,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-04',
        categoryId: 'cat-03',
        categoryName: 'Jasa',
        sku: 'JSA-01',
        barcode: '',
        name: 'Ongkir Pengantaran',
        sellingPrice: 10000,
        costPrice: 0,
        stock: 0,
        trackStock: false, // Service, non-stock
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Product(
        id: 'prod-05',
        categoryId: 'cat-01',
        categoryName: 'Makanan',
        sku: 'MKN-02',
        barcode: '555555',
        name: 'Mie Ayam Bakso (Nonaktif)',
        sellingPrice: 20000,
        costPrice: 10000,
        stock: 15,
        trackStock: true,
        isActive: false, // Inactive product
        createdAt: DateTime.now(),
      ),
    ];

    setUp(() async {
      mockProductRepo = MockProductRepository(initialProducts: testProducts);
      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockProductRepo),
        ],
      );
      // Load products into productProvider
      await container.read(productProvider.notifier).loadProducts();
    });

    tearDown(() {
      container.dispose();
    });

    test('posFilteredProductsProvider only includes active products', () {
      final filtered = container.read(posFilteredProductsProvider);
      // Should include prod-01, prod-02, prod-03, prod-04, but NOT prod-05 (inactive)
      expect(filtered.length, 4);
      expect(filtered.any((p) => p.id == 'prod-05'), isFalse);
    });

    test('setCategory filters products by category ID', () {
      container.read(posProvider.notifier).setCategory('cat-01');
      var filtered = container.read(posFilteredProductsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'prod-01');

      // Clear category
      container.read(posProvider.notifier).setCategory(null);
      filtered = container.read(posFilteredProductsProvider);
      expect(filtered.length, 4);
    });

    test('setSearchQuery matches by name, SKU, and barcode', () {
      // 1. By name
      container.read(posProvider.notifier).setSearchQuery('teh');
      var filtered = container.read(posFilteredProductsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'prod-02');

      // 2. By SKU
      container.read(posProvider.notifier).setSearchQuery('mkn-01');
      filtered = container.read(posFilteredProductsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'prod-01');

      // 3. By barcode
      container.read(posProvider.notifier).setSearchQuery('222222');
      filtered = container.read(posFilteredProductsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'prod-02');

      // 4. Non-matching
      container.read(posProvider.notifier).setSearchQuery('xyz_not_found');
      filtered = container.read(posFilteredProductsProvider);
      expect(filtered.isEmpty, isTrue);
    });

    test('addToCart successfully adds active product and calculates amounts', () {
      final p1 = testProducts[0]; // Nasi Goreng Rp25.000
      final result1 = container.read(posProvider.notifier).addToCart(p1);
      expect(result1, isTrue);

      var state = container.read(posProvider);
      expect(state.cartItems.length, 1);
      expect(state.totalQuantity, 1);
      expect(state.totalAmount, 25000);
      expect(state.getCartQuantity(p1.id), 1);
      expect(state.isInCart(p1.id), isTrue);

      // Add same product again (increments quantity)
      final result2 = container.read(posProvider.notifier).addToCart(p1);
      expect(result2, isTrue);

      state = container.read(posProvider);
      expect(state.cartItems.length, 1);
      expect(state.totalQuantity, 2);
      expect(state.totalAmount, 50000);
      expect(state.getCartQuantity(p1.id), 2);

      // Add service product (non-stock)
      final pService = testProducts[3]; // Ongkir Rp10.000
      container.read(posProvider.notifier).addToCart(pService);

      state = container.read(posProvider);
      expect(state.cartItems.length, 2);
      expect(state.totalQuantity, 3);
      expect(state.totalAmount, 60000);
    });

    test('addToCart rejects out-of-stock product and inactive product', () {
      final pOutOfStock = testProducts[2]; // stock: 0
      final resultOut = container.read(posProvider.notifier).addToCart(pOutOfStock);
      expect(resultOut, isFalse);
      expect(container.read(posProvider).errorMessage, contains('telah habis'));

      final pInactive = testProducts[4]; // isActive: false
      final resultInactive = container.read(posProvider.notifier).addToCart(pInactive);
      expect(resultInactive, isFalse);
      expect(container.read(posProvider).errorMessage, contains('dinonaktifkan'));
    });

    test('addToCart enforces tracked inventory stock limits', () {
      final pLimited = testProducts[1]; // Es Teh Manis, stock: 2

      // 1st add -> OK
      expect(container.read(posProvider.notifier).addToCart(pLimited), isTrue);
      // 2nd add -> OK (qty: 2)
      expect(container.read(posProvider.notifier).addToCart(pLimited), isTrue);
      // 3rd add -> FAILS (exceeds stock 2)
      final resultExceeded =
          container.read(posProvider.notifier).addToCart(pLimited);
      expect(resultExceeded, isFalse);
      expect(container.read(posProvider).errorMessage,
          contains('tidak mencukupi'));
      expect(container.read(posProvider).getCartQuantity(pLimited.id), 2);
    });

    test('removeFromCart, deleteItem, and clearCart operate accurately', () {
      final p1 = testProducts[0];
      final p2 = testProducts[1];

      container.read(posProvider.notifier).addToCart(p1);
      container.read(posProvider.notifier).addToCart(p1);
      container.read(posProvider.notifier).addToCart(p2);

      expect(container.read(posProvider).totalQuantity, 3);

      // Decrement p1
      container.read(posProvider.notifier).removeFromCart(p1.id);
      expect(container.read(posProvider).getCartQuantity(p1.id), 1);
      expect(container.read(posProvider).totalQuantity, 2);

      // Decrement p1 again (removes p1 from cart)
      container.read(posProvider.notifier).removeFromCart(p1.id);
      expect(container.read(posProvider).isInCart(p1.id), isFalse);
      expect(container.read(posProvider).totalQuantity, 1);

      // Delete p2
      container.read(posProvider.notifier).deleteItem(p2.id);
      expect(container.read(posProvider).cartItems.isEmpty, isTrue);

      // Add and clearCart
      container.read(posProvider.notifier).addToCart(p1);
      expect(container.read(posProvider).hasItems, isTrue);
      container.read(posProvider.notifier).clearCart();
      expect(container.read(posProvider).hasItems, isFalse);
    });

    test('resetFilters clears search query and selected category', () {
      container.read(posProvider.notifier).setSearchQuery('kopi');
      container.read(posProvider.notifier).setCategory('cat-02');

      expect(container.read(posProvider).searchQuery, 'kopi');
      expect(container.read(posProvider).selectedCategoryId, 'cat-02');

      container.read(posProvider.notifier).resetFilters();

      expect(container.read(posProvider).searchQuery, '');
      expect(container.read(posProvider).selectedCategoryId, isNull);
    });
  });
}
