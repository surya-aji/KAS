import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';

void main() {
  Widget buildTestWidget({MockCategoryRepository? repository}) {
    final repo = repository ??
        MockCategoryRepository(
          initialCategories: [
            Category(
              id: 'c-1',
              name: 'Makanan Tradisional',
              description: 'Nasi goreng dan soto',
              colorHex: '#137547',
              productCount: 10,
              isActive: true,
              createdAt: DateTime.now(),
            ),
            Category(
              id: 'c-2',
              name: 'Minuman Dingin',
              description: 'Aneka jus dan es',
              colorHex: '#0D9488',
              productCount: 0,
              isActive: true,
              createdAt: DateTime.now(),
            ),
          ],
        );

    return ProviderScope(
      overrides: [
        categoryRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const CategoryListScreen(),
      ),
    );
  }

  group('CategoryListScreen Widget Tests', () {
    testWidgets('renders screen headers, search field, summary and categories',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Screen title and headers
      expect(find.text('Kategori Produk'), findsOneWidget);
      expect(find.text('Total Kategori'), findsOneWidget);
      expect(find.text('Kategori Aktif'), findsOneWidget);
      expect(find.text('Total Produk'), findsOneWidget);

      // Search field
      expect(
        find.text('Cari nama atau deskripsi kategori...'),
        findsOneWidget,
      );

      // Category items rendered
      expect(find.text('Makanan Tradisional'), findsOneWidget);
      expect(find.text('Minuman Dingin'), findsOneWidget);
      expect(find.byType(CategoryCard), findsNWidgets(2));

      // FAB
      expect(find.text('Tambah Kategori'), findsOneWidget);
    });

    testWidgets('search field dynamically filters category list',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter search query 'jus'
      final searchField =
          find.widgetWithText(TextField, 'Cari nama atau deskripsi kategori...');
      await tester.enterText(searchField, 'jus');
      await tester.pumpAndSettle();

      // 'Minuman Dingin' matches 'jus' in description, 'Makanan' does not
      expect(find.text('Minuman Dingin'), findsOneWidget);
      expect(find.text('Makanan Tradisional'), findsNothing);

      // Search for non-existent item triggers empty state
      await tester.enterText(searchField, 'xyz_not_found');
      await tester.pumpAndSettle();

      expect(find.text('Kategori Tidak Ditemukan'), findsOneWidget);
      expect(find.text('Hapus Pencarian'), findsOneWidget);

      // Clear search restores list
      await tester.tap(find.text('Hapus Pencarian'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryCard), findsNWidgets(2));
    });

    testWidgets('opens Add Category sheet and successfully creates new category',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap on FAB to open bottom sheet
      await tester.tap(find.text('Tambah Kategori'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and live preview
      expect(find.text('Tambah Kategori Baru'), findsOneWidget);
      expect(find.text('Nama Kategori *'), findsOneWidget);

      // Enter new category name
      final nameField = find.widgetWithText(TextFormField, '');
      await tester.enterText(nameField.first, 'Camilan Gurih');
      await tester.pumpAndSettle();

      // Tap 'Tambah Kategori' submit button in the modal sheet
      final submitButton = find.descendant(
        of: find.byType(CategoryFormSheet),
        matching: find.text('Tambah Kategori'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Bottom sheet should dismiss and new category appears in list
      expect(find.text('Tambah Kategori Baru'), findsNothing);
      expect(find.text('Camilan Gurih'), findsOneWidget);
      expect(find.byType(CategoryCard), findsNWidgets(3));
    });

    testWidgets('deleting zero-product category opens confirmation and removes it',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Minuman Dingin has 0 products
      // Find its delete button via tooltip
      final deleteButtons = find.byTooltip('Hapus');
      expect(deleteButtons, findsWidgets);

      // Tap delete on second category (Minuman Dingin)
      await tester.tap(deleteButtons.last);
      await tester.pumpAndSettle();

      // Verify confirmation dialog
      expect(find.text('Hapus Kategori?'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();

      // Minuman Dingin should be removed
      expect(find.text('Minuman Dingin'), findsNothing);
      expect(find.byType(CategoryCard), findsNWidgets(1));
    });
  });
}
