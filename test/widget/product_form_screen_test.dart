import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_currency_field.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

void main() {
  Widget buildTestWidget({
    Product? product,
    MockProductRepository? productRepo,
    MockCategoryRepository? categoryRepo,
  }) {
    final pRepo = productRepo ??
        MockProductRepository(
          initialProducts: [],
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
          ],
        );

    return ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(pRepo),
        categoryRepositoryProvider.overrideWithValue(cRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: ProductFormScreen(product: product),
      ),
    );
  }

  void setTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('ProductFormScreen Price & Stock Validations', () {
    testWidgets('shows validation error when selling price is empty or zero', (tester) async {
      setTestViewport(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter product name
      final nameField = find.descendant(
        of: find.widgetWithText(AppTextField, 'Nama Produk *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameField, 'Bakso Sapi');
      await tester.pumpAndSettle();

      // Tap submit with selling price = 0
      final submitButton = find.widgetWithText(AppButton, 'Tambah Produk');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect selling price required error
      expect(find.text('Harga jual wajib diisi'), findsOneWidget);
    });

    testWidgets('shows validation error when stock or minimum stock is empty', (tester) async {
      setTestViewport(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter product name
      final nameField = find.descendant(
        of: find.widgetWithText(AppTextField, 'Nama Produk *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameField, 'Es Teh Manis');

      // Enter valid selling price
      final sellingField = find.descendant(
        of: find.widgetWithText(AppCurrencyField, 'Harga Jual *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(sellingField, '5000');
      await tester.pumpAndSettle();

      // Clear current stock field
      final stockField = find.descendant(
        of: find.widgetWithText(AppTextField, 'Jumlah Stok Saat Ini *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(stockField, '');
      await tester.pumpAndSettle();

      // Submit
      final submitButton = find.widgetWithText(AppButton, 'Tambah Produk');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Stock validation error should be visible
      expect(find.text('Jumlah stok wajib diisi'), findsOneWidget);
    });

    testWidgets('displays warning banner when cost price exceeds selling price', (tester) async {
      setTestViewport(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final sellingField = find.descendant(
        of: find.widgetWithText(AppCurrencyField, 'Harga Jual *'),
        matching: find.byType(TextFormField),
      );
      final costField = find.descendant(
        of: find.widgetWithText(AppCurrencyField, 'Harga Modal / HPP (Opsional)'),
        matching: find.byType(TextFormField),
      );

      // Selling price: Rp 10.000
      await tester.enterText(sellingField, '10000');
      await tester.pumpAndSettle();

      // Cost price: Rp 15.000 (higher than selling price)
      await tester.enterText(costField, '15000');
      await tester.pumpAndSettle();

      // Expect potential loss warning banner
      expect(
        find.textContaining('Perhatian: Harga modal lebih tinggi dari harga jual'),
        findsOneWidget,
      );
    });

    testWidgets('displays real-time stock status indicator based on stock vs minStock', (tester) async {
      setTestViewport(tester);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // By default stock is 0 -> should display 'Stok Habis'
      expect(
        find.textContaining('Stok Habis: Produk memiliki stok 0'),
        findsOneWidget,
      );

      // Find stock field and enter 3 (with minStock = 5) -> should display 'Peringatan Stok Menipis'
      final stockField = find.descendant(
        of: find.widgetWithText(AppTextField, 'Jumlah Stok Saat Ini *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(stockField, '3');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Peringatan Stok Menipis: Stok (3) berada pada atau di bawah batas minimum (5)'),
        findsOneWidget,
      );

      // Enter 20 (stock > minStock) -> should display 'Stok Aman'
      await tester.enterText(stockField, '20');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Stok Aman: Stok saat ini (20) mencukupi di atas batas minimum (5)'),
        findsOneWidget,
      );
    });

    testWidgets('allows successful form submission when inputs are valid', (tester) async {
      setTestViewport(tester);

      final mockRepo = MockProductRepository(initialProducts: []);

      await tester.pumpWidget(buildTestWidget(productRepo: mockRepo));
      await tester.pumpAndSettle();

      // Enter Name
      final nameField = find.descendant(
        of: find.widgetWithText(AppTextField, 'Nama Produk *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameField, 'Sate Ayam');

      // Enter Selling Price
      final sellingField = find.descendant(
        of: find.widgetWithText(AppCurrencyField, 'Harga Jual *'),
        matching: find.byType(TextFormField),
      );
      final costField = find.descendant(
        of: find.widgetWithText(AppCurrencyField, 'Harga Modal / HPP (Opsional)'),
        matching: find.byType(TextFormField),
      );

      await tester.enterText(sellingField, '25000');
      await tester.enterText(costField, '15000');
      await tester.pumpAndSettle();

      // Enter Stock and MinStock
      final stockField = find.descendant(
        of: find.widgetWithText(AppTextField, 'Jumlah Stok Saat Ini *'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(stockField, '50');
      await tester.pumpAndSettle();

      // Tap Submit
      final submitButton = find.widgetWithText(AppButton, 'Tambah Produk');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify product was created in repository
      final products = await mockRepo.getProducts();
      expect(products.length, 1);
      expect(products.first.name, 'Sate Ayam');
      expect(products.first.sellingPrice, 25000);
      expect(products.first.costPrice, 15000);
      expect(products.first.stock, 50);
      expect(products.first.minStock, 5);
    });
  });
}
