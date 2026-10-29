import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/business_settings/data/repositories/mock_business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';
import 'package:kas_usaha/features/pos/pos.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_search_field.dart';

void main() {
  Widget buildTestWidget({
    MockProductRepository? productRepo,
    MockCategoryRepository? categoryRepo,
    MockBusinessProfileRepository? profileRepo,
  }) {
    final pRepo = productRepo ??
        MockProductRepository(
          initialProducts: [
            Product(
              id: 'p-1',
              categoryId: 'c-food',
              categoryName: 'Makanan',
              sku: 'MKN-01',
              barcode: '111111',
              name: 'Nasi Goreng Spesial',
              sellingPrice: 25000,
              costPrice: 15000,
              stock: 20,
              minStock: 5,
              trackStock: true,
              isActive: true,
              createdAt: DateTime.now(),
            ),
            Product(
              id: 'p-2',
              categoryId: 'c-drink',
              categoryName: 'Minuman',
              sku: 'MNM-01',
              barcode: '222222',
              name: 'Es Kopi Susu',
              sellingPrice: 18000,
              costPrice: 9000,
              stock: 3,
              minStock: 5,
              trackStock: true,
              isActive: true,
              createdAt: DateTime.now(),
            ),
            Product(
              id: 'p-3',
              categoryId: 'c-drink',
              categoryName: 'Minuman',
              sku: 'MNM-02',
              barcode: '333333',
              name: 'Es Teh Manis',
              sellingPrice: 5000,
              costPrice: 2000,
              stock: 0, // Out of stock
              minStock: 5,
              trackStock: true,
              isActive: true,
              createdAt: DateTime.now(),
            ),
            Product(
              id: 'p-4',
              categoryId: 'c-food',
              categoryName: 'Makanan',
              sku: 'MKN-02',
              barcode: '444444',
              name: 'Mie Rebus Jawa (Nonaktif)',
              sellingPrice: 20000,
              costPrice: 10000,
              stock: 10,
              minStock: 5,
              trackStock: true,
              isActive: false, // Inactive
              createdAt: DateTime.now(),
            ),
          ],
        );

    final cRepo = categoryRepo ??
        MockCategoryRepository(
          initialCategories: [
            Category(
              id: 'c-food',
              name: 'Makanan',
              colorHex: '#137547',
              isActive: true,
              createdAt: DateTime.now(),
            ),
            Category(
              id: 'c-drink',
              name: 'Minuman',
              colorHex: '#0D9488',
              isActive: true,
              createdAt: DateTime.now(),
            ),
          ],
        );

    final profRepo = profileRepo ??
        MockBusinessProfileRepository(
          initialProfile: BusinessProfile(
            id: 'prof-test',
            name: 'Warung Berkah Jaya',
            address: 'Jl. Malioboro No. 10',
            phone: '08123456789',
            currencyCode: 'IDR',
            taxRate: 10,
            defaultDiscountRate: 0,
            updatedAt: DateTime.now(),
          ),
        );

    return ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(pRepo),
        categoryRepositoryProvider.overrideWithValue(cRepo),
        businessProfileRepositoryProvider.overrideWithValue(profRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const PosScreen(),
      ),
    );
  }

  group('PosScreen Responsive Layout & UI Tests (Task T2.1)', () {
    testWidgets('Smartphone layout renders search, category selector, 2-col grid, and bottom cart bar',
        (tester) async {
      // Mobile phone screen dimensions (400 x 800)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Kasir (POS)'), findsOneWidget);
      expect(find.text('Warung Berkah Jaya'), findsOneWidget);

      // Search bar
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(find.text('Cari nama, SKU, atau barcode...'), findsOneWidget);

      // Category filter chips
      expect(find.byType(PosCategorySelector), findsOneWidget);
      expect(find.text('Semua (3)'), findsOneWidget); // 3 active products
      expect(find.text('Makanan'), findsWidgets);
      expect(find.text('Minuman'), findsWidgets);

      // Product Grid (only active products p-1, p-2, p-3)
      expect(find.byType(PosProductCard), findsNWidgets(3));
      expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
      expect(find.text('Es Kopi Susu'), findsOneWidget);
      expect(find.text('Es Teh Manis'), findsOneWidget);
      expect(find.text('Mie Rebus Jawa (Nonaktif)'), findsNothing);

      // Sticky Bottom Cart Bar
      expect(find.byType(PosCartBottomBar), findsOneWidget);
      expect(find.text('Keranjang kosong'), findsOneWidget);
      expect(find.text('Lihat Pesanan'), findsOneWidget);
      // Tablet sidebar should NOT be rendered on phone
      expect(find.byType(PosCartSidebar), findsNothing);
    });

    testWidgets('Tablet layout renders dual-pane with product grid on left and order sidebar on right',
        (tester) async {
      // Tablet landscape dimensions (1024 x 768)
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tablet split pane contains PosCartSidebar on the right
      expect(find.byType(PosCartSidebar), findsOneWidget);
      expect(find.text('Pesanan Aktif'), findsOneWidget);
      expect(find.text('Keranjang Kosong'), findsNWidgets(2));
      expect(find.text('Total Pembayaran'), findsOneWidget);

      // Bottom cart bar should NOT be rendered on tablet
      expect(find.byType(PosCartBottomBar), findsNothing);

      // Left column contains search, category chips, and product grid
      expect(find.byType(AppSearchField), findsOneWidget);
      expect(find.byType(PosCategorySelector), findsOneWidget);
      expect(find.byType(PosProductCard), findsNWidgets(3));
    });

    testWidgets('Real-time search filters product grid and handles empty search state',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Search by product name 'kopi'
      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'kopi');
      await tester.pumpAndSettle();

      expect(find.text('Es Kopi Susu'), findsOneWidget);
      expect(find.text('Nasi Goreng Spesial'), findsNothing);
      expect(find.text('Es Teh Manis'), findsNothing);
      expect(find.byType(PosProductCard), findsNWidgets(1));

      // Search for non-existing query
      await tester.enterText(searchInput, 'none_existent_product');
      await tester.pumpAndSettle();

      expect(find.text('Produk Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Reset Filter & Pencarian'), findsOneWidget);

      // Tap Reset button restores active products
      await tester.tap(find.text('Reset Filter & Pencarian'));
      await tester.pumpAndSettle();
      expect(find.byType(PosProductCard), findsNWidgets(3));
    });

    testWidgets('Category chips filter products in POS grid',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select 'Makanan' category chip
      final makananChip = find.widgetWithText(ChoiceChip, 'Makanan');
      await tester.tap(makananChip);
      await tester.pumpAndSettle();

      expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
      expect(find.text('Es Kopi Susu'), findsNothing);
      expect(find.text('Es Teh Manis'), findsNothing);
      expect(find.byType(PosProductCard), findsNWidgets(1));

      // Tap 'Semua' restores all active products
      final semuaChip = find.widgetWithText(ChoiceChip, 'Semua (3)');
      await tester.tap(semuaChip);
      await tester.pumpAndSettle();
      expect(find.byType(PosProductCard), findsNWidgets(3));
    });

    testWidgets('Tapping product adds to cart and updates UI elements',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Nasi Goreng Spesial
      final nasiGorengCard = find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial');
      await tester.tap(nasiGorengCard);
      await tester.pumpAndSettle();

      // Cart sidebar now displays the item and updated total
      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Subtotal (1 item):'), findsOneWidget);
      expect(find.text('Rp25.000'), findsWidgets);

      // Tap same card again (increments quantity to 2)
      await tester.tap(nasiGorengCard);
      await tester.pumpAndSettle();

      expect(find.text('2 item'), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);
    });

    testWidgets('Tapping out of stock product triggers warning feedback',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Es Teh Manis' which has stock: 0
      final outOfStockCard = find.widgetWithText(PosProductCard, 'Es Teh Manis');
      await tester.tap(outOfStockCard);
      await tester.pumpAndSettle();

      // SnackBar with warning appears
      expect(find.text('Stok "Es Teh Manis" telah habis.'), findsOneWidget);
      // Cart should remain 0
      expect(find.text('0 item'), findsOneWidget);
    });

    testWidgets('Mobile bottom bar opens cart modal sheet on tap',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Nasi Goreng to add to cart
      final card = find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial');
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Bottom bar shows 1 item
      expect(find.text('1 item terpilih'), findsOneWidget);

      // Tap 'Lihat Pesanan'
      await tester.tap(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();

      // Bottom modal sheet appears
      expect(find.text('Rincian Pesanan'), findsOneWidget);
      expect(find.text('Tutup Keranjang'), findsOneWidget);

      // Close sheet
      await tester.tap(find.text('Tutup Keranjang'));
      await tester.pumpAndSettle();
      expect(find.text('Rincian Pesanan'), findsNothing);
    });
  });
}
