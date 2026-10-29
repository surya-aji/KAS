import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';

void main() {
  Widget buildTestWidget({
    MockProductRepository? productRepo,
    MockCategoryRepository? categoryRepo,
  }) {
    final pRepo = productRepo ??
        MockProductRepository(
          initialProducts: [
            Product(
              id: 'p-1',
              categoryId: 'c-food',
              categoryName: 'Makanan',
              sku: 'MKN-01',
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
              name: 'Es Kopi Susu',
              sellingPrice: 18000,
              costPrice: 9000,
              stock: 3, // Low stock
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
              name: 'Es Cincau Hijau',
              sellingPrice: 8000,
              costPrice: 3000,
              stock: 0, // Out of stock
              minStock: 5,
              trackStock: true,
              isActive: true,
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
              createdAt: DateTime.now(),
            ),
            Category(
              id: 'c-drink',
              name: 'Minuman',
              colorHex: '#0D9488',
              createdAt: DateTime.now(),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(pRepo),
        categoryRepositoryProvider.overrideWithValue(cRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ProductListScreen(),
      ),
    );
  }

  group('ProductListScreen Widget Tests', () {
    testWidgets('renders screen headers, search field, summary cards, and products',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Screen title and headers
      expect(find.text('Katalog Produk'), findsOneWidget);
      expect(find.text('Total Produk'), findsOneWidget);
      expect(find.text('Stok Menipis'), findsOneWidget);
      expect(find.text('Stok Habis'), findsOneWidget);

      // Search field
      expect(find.text('Cari nama, SKU, atau barcode...'), findsOneWidget);

      // Category chips
      expect(find.text('Semua Kategori'), findsOneWidget);
      expect(find.text('Makanan'), findsWidgets);
      expect(find.text('Minuman'), findsWidgets);

      // Stock filter chips
      expect(find.text('Semua Stok'), findsOneWidget);
      expect(find.text('Tersedia'), findsOneWidget);
      expect(find.text('Menipis (1)'), findsOneWidget);
      expect(find.text('Habis (1)'), findsOneWidget);

      // Products rendered
      expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
      expect(find.text('Es Kopi Susu'), findsOneWidget);
      expect(find.text('Es Cincau Hijau'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(3));

      // FAB
      expect(find.text('Tambah Produk'), findsOneWidget);
    });

    testWidgets('search field dynamically filters products list',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter search query 'kopi'
      final searchField =
          find.widgetWithText(TextField, 'Cari nama, SKU, atau barcode...');
      await tester.enterText(searchField, 'kopi');
      await tester.pumpAndSettle();

      // Only 'Es Kopi Susu' matches
      expect(find.text('Es Kopi Susu'), findsOneWidget);
      expect(find.text('Nasi Goreng Spesial'), findsNothing);
      expect(find.text('Es Cincau Hijau'), findsNothing);

      // Search for non-existent item triggers empty state
      await tester.enterText(searchField, 'not_found_query');
      await tester.pumpAndSettle();

      expect(find.text('Produk Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Reset Filter & Pencarian'), findsOneWidget);

      // Reset restores list
      await tester.tap(find.text('Reset Filter & Pencarian'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductCard), findsNWidgets(3));
    });

    testWidgets('category chip selection filters products',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Select 'Makanan' category chip
      final makananChip = find.widgetWithText(ChoiceChip, 'Makanan');
      await tester.tap(makananChip);
      await tester.pumpAndSettle();

      // Only 'Nasi Goreng Spesial' belongs to Makanan
      expect(find.text('Nasi Goreng Spesial'), findsOneWidget);
      expect(find.text('Es Kopi Susu'), findsNothing);
      expect(find.text('Es Cincau Hijau'), findsNothing);
      expect(find.byType(ProductCard), findsNWidgets(1));
    });

    testWidgets('stock filter chip filters out-of-stock products',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Habis (1)' stock filter chip
      await tester.tap(find.text('Habis (1)'));
      await tester.pumpAndSettle();

      // Only 'Es Cincau Hijau' is out of stock (stock: 0)
      expect(find.text('Es Cincau Hijau'), findsOneWidget);
      expect(find.text('Nasi Goreng Spesial'), findsNothing);
      expect(find.text('Es Kopi Susu'), findsNothing);
    });

    testWidgets('deleting a product displays confirmation dialog and removes it',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Delete buttons
      final deleteButtons = find.byTooltip('Hapus Produk');
      expect(deleteButtons, findsWidgets);

      // Tap delete on first product (Nasi Goreng Spesial)
      await tester.tap(deleteButtons.first);
      await tester.pumpAndSettle();

      // Confirmation dialog
      expect(find.text('Hapus Produk?'), findsOneWidget);
      expect(find.text('Hapus Produk'), findsWidgets);

      // Confirm deletion in dialog
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Hapus Produk'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Product should be removed
      expect(find.text('Nasi Goreng Spesial'), findsNothing);
      expect(find.byType(ProductCard), findsNWidgets(2));
    });
  });
}
