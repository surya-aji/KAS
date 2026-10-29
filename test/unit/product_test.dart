import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/catalog/data/repositories/mock_product_repository.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/product_provider.dart';

void main() {
  group('Product Domain Model', () {
    test('instantiates with defaults and calculates profits accurately', () {
      final now = DateTime.now();
      final product = Product(
        id: 'p-1',
        categoryId: 'cat-1',
        categoryName: 'Makanan',
        name: 'Nasi Goreng',
        sellingPrice: 20000,
        costPrice: 12000,
        stock: 15,
        minStock: 5,
        trackStock: true,
        createdAt: now,
      );

      expect(product.id, 'p-1');
      expect(product.sellingPrice, 20000);
      expect(product.costPrice, 12000);
      expect(product.unitProfit, 8000);
      expect(product.profitMarginPercentage, 40.0);
      expect(product.formattedSellingPrice, 'Rp20.000');
      expect(product.formattedCostPrice, 'Rp12.000');
      expect(product.isOutOfStock, isFalse);
      expect(product.isLowStock, isFalse);
    });

    test('stock conditions correctly identify low stock and out of stock', () {
      final now = DateTime.now();
      final lowStock = Product(
        id: 'p-low',
        categoryId: 'c-1',
        name: 'Mie Ayam',
        sellingPrice: 15000,
        stock: 3,
        minStock: 5,
        trackStock: true,
        createdAt: now,
      );
      expect(lowStock.isLowStock, isTrue);
      expect(lowStock.isOutOfStock, isFalse);

      final emptyStock = Product(
        id: 'p-empty',
        categoryId: 'c-1',
        name: 'Es Jeruk',
        sellingPrice: 5000,
        stock: 0,
        minStock: 5,
        trackStock: true,
        createdAt: now,
      );
      expect(emptyStock.isLowStock, isFalse);
      expect(emptyStock.isOutOfStock, isTrue);

      final service = Product(
        id: 'p-service',
        categoryId: 'c-1',
        name: 'Jasa Kirim',
        sellingPrice: 10000,
        stock: 0,
        trackStock: false,
        createdAt: now,
      );
      expect(service.isLowStock, isFalse);
      expect(service.isOutOfStock, isFalse);
    });

    test('serializes toMap and deserializes fromMap accurately', () {
      final now = DateTime(2026, 10, 29, 9, 0, 0);
      final product = Product(
        id: 'prd-full',
        categoryId: 'cat-minuman',
        categoryName: 'Minuman',
        sku: 'MNM-001',
        barcode: '8992001',
        name: 'Kopi Susu Aren',
        description: 'Kopi susu gula aren 500ml',
        unit: 'botol',
        sellingPrice: 22000,
        costPrice: 11000,
        stock: 20,
        minStock: 5,
        trackStock: true,
        isActive: true,
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 30)),
      );

      final map = product.toMap();
      expect(map['id'], 'prd-full');
      expect(map['category_id'], 'cat-minuman');
      expect(map['category_name'], 'Minuman');
      expect(map['sku'], 'MNM-001');
      expect(map['barcode'], '8992001');
      expect(map['selling_price'], 22000);
      expect(map['cost_price'], 11000);
      expect(map['stock'], 20);
      expect(map['track_stock'], 1);
      expect(map['is_active'], 1);

      final reconstituted = Product.fromMap(map);
      expect(reconstituted, equals(product));
    });
  });

  group('MockProductRepository Queries & CRUD', () {
    late MockProductRepository repository;

    setUp(() {
      repository = MockProductRepository(
        initialProducts: [
          Product(
            id: 'p1',
            categoryId: 'c-food',
            categoryName: 'Makanan',
            sku: 'F01',
            barcode: '111',
            name: 'Nasi Uduk',
            sellingPrice: 15000,
            stock: 20,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          Product(
            id: 'p2',
            categoryId: 'c-drink',
            categoryName: 'Minuman',
            sku: 'D01',
            barcode: '222',
            name: 'Es Cincau',
            sellingPrice: 8000,
            stock: 0,
            isActive: false,
            createdAt: DateTime.now(),
          ),
        ],
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('getProducts filters by categoryId and activeOnly', () async {
      final all = await repository.getProducts();
      expect(all.length, 2);

      final active = await repository.getProducts(activeOnly: true);
      expect(active.length, 1);
      expect(active.first.id, 'p1');

      final drinks = await repository.getProducts(categoryId: 'c-drink');
      expect(drinks.length, 1);
      expect(drinks.first.id, 'p2');
    });

    test('getProductBySku and getProductByBarcode return matching items', () async {
      final bySku = await repository.getProductBySku('f01');
      expect(bySku, isNotNull);
      expect(bySku!.name, 'Nasi Uduk');

      final byBarcode = await repository.getProductByBarcode('222');
      expect(byBarcode, isNotNull);
      expect(byBarcode!.name, 'Es Cincau');
    });

    test('creates, updates, and deletes products reactively', () async {
      final newProd = Product(
        id: 'p3',
        categoryId: 'c-food',
        name: 'Ayam Bakar',
        sellingPrice: 25000,
        createdAt: DateTime.now(),
      );

      await repository.createProduct(newProd);
      var list = await repository.getProducts();
      expect(list.length, 3);

      final updatedProd = newProd.copyWith(name: 'Ayam Bakar Madu');
      await repository.updateProduct(updatedProd);
      final fetched = await repository.getProductById('p3');
      expect(fetched!.name, 'Ayam Bakar Madu');

      await repository.deleteProduct('p3');
      list = await repository.getProducts();
      expect(list.length, 2);
    });
  });

  group('ProductNotifier & State Management', () {
    late ProviderContainer container;
    late MockProductRepository mockRepo;

    setUp(() {
      mockRepo = MockProductRepository(
        initialProducts: [
          Product(
            id: 'p1',
            categoryId: 'c-food',
            categoryName: 'Makanan',
            sku: 'F01',
            barcode: '111',
            name: 'Nasi Liwet Komplit',
            sellingPrice: 28000,
            costPrice: 16000,
            stock: 12,
            minStock: 5,
            trackStock: true,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          Product(
            id: 'p2',
            categoryId: 'c-food',
            categoryName: 'Makanan',
            sku: 'F02',
            barcode: '112',
            name: 'Tahu Tempe Goreng',
            sellingPrice: 6000,
            costPrice: 3000,
            stock: 2, // low stock
            minStock: 5,
            trackStock: true,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          Product(
            id: 'p3',
            categoryId: 'c-drink',
            categoryName: 'Minuman',
            sku: 'D01',
            barcode: '221',
            name: 'Jus Alpukat',
            sellingPrice: 15000,
            costPrice: 7000,
            stock: 0, // out of stock
            minStock: 5,
            trackStock: true,
            isActive: false,
            createdAt: DateTime.now(),
          ),
        ],
      );

      container = ProviderContainer(
        overrides: [
          productRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockRepo.dispose();
    });

    test('loadProducts populates products and computes summary metrics', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      final state = container.read(productProvider);
      expect(state.status, ProductStatus.loaded);
      expect(state.totalCount, 3);
      expect(state.activeCount, 2);
      expect(state.lowStockCount, 1);
      expect(state.outOfStockCount, 1);
    });

    test('setSearchQuery filters by name, SKU, and barcode', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      notifier.setSearchQuery('liwet');
      var filtered = container.read(productProvider).filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Nasi Liwet Komplit');

      notifier.setSearchQuery('D01');
      filtered = container.read(productProvider).filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Jus Alpukat');

      notifier.setSearchQuery('112');
      filtered = container.read(productProvider).filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Tahu Tempe Goreng');
    });

    test('setCategoryFilter and setStockFilter isolate items properly', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      // Category filter
      notifier.setCategoryFilter('c-food');
      var filtered = container.read(productProvider).filteredProducts;
      expect(filtered.length, 2);

      // Stock filter: low stock
      notifier.setStockFilter(ProductStockFilter.lowStock);
      filtered = container.read(productProvider).filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Tahu Tempe Goreng');

      // Stock filter: out of stock
      notifier.setCategoryFilter(null);
      notifier.setStockFilter(ProductStockFilter.outOfStock);
      filtered = container.read(productProvider).filteredProducts;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Jus Alpukat');
    });

    test('createProduct validates required fields and SKU uniqueness', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      // Empty name
      final emptyName = await notifier.createProduct(
        name: '   ',
        categoryId: 'c-food',
        sellingPrice: 10000,
      );
      expect(emptyName, isFalse);
      expect(container.read(productProvider).hasError, isTrue);

      // Missing category
      final emptyCat = await notifier.createProduct(
        name: 'Kue Lapis',
        categoryId: '',
        sellingPrice: 10000,
      );
      expect(emptyCat, isFalse);

      // Negative selling price
      final negativePrice = await notifier.createProduct(
        name: 'Kue Lapis',
        categoryId: 'c-food',
        sellingPrice: -500,
      );
      expect(negativePrice, isFalse);

      // Duplicate SKU
      final duplicateSku = await notifier.createProduct(
        name: 'Kue Lapis',
        categoryId: 'c-food',
        sku: 'f01',
        sellingPrice: 10000,
      );
      expect(duplicateSku, isFalse);
      expect(container.read(productProvider).errorMessage, contains('sudah digunakan'));

      // Valid creation
      final valid = await notifier.createProduct(
        name: 'Kue Lapis Legit',
        categoryId: 'c-food',
        categoryName: 'Makanan',
        sku: 'SNK-01',
        sellingPrice: 12000,
        costPrice: 6000,
        stock: 30,
      );
      expect(valid, isTrue);
      expect(container.read(productProvider).totalCount, 4);
    });

    test('updateProduct modifies product and prevents duplicate SKU collisions', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      final existing = container.read(productProvider).products.first;

      // Duplicate SKU collision with p2
      final collision = await notifier.updateProduct(
        existing.copyWith(sku: 'F02'),
      );
      expect(collision, isFalse);

      // Valid update
      final valid = await notifier.updateProduct(
        existing.copyWith(
          name: 'Nasi Liwet Gurih Solo',
          sellingPrice: 30000,
        ),
      );
      expect(valid, isTrue);
      final updated = container.read(productProvider).products.firstWhere((p) => p.id == existing.id);
      expect(updated.name, 'Nasi Liwet Gurih Solo');
      expect(updated.sellingPrice, 30000);
    });

    test('deleteProduct removes product from state', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      final success = await notifier.deleteProduct('p1');
      expect(success, isTrue);
      expect(container.read(productProvider).totalCount, 2);
    });

    test('toggleProductActive toggles active status', () async {
      final notifier = container.read(productProvider.notifier);
      await notifier.loadProducts();

      final prod = container.read(productProvider).products.first;
      expect(prod.isActive, isTrue);

      await notifier.toggleProductActive(prod);
      final toggled = container.read(productProvider).products.firstWhere((p) => p.id == prod.id);
      expect(toggled.isActive, isFalse);
    });
  });
}
