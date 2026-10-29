import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/business_settings/data/repositories/mock_business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';
import 'package:kas_usaha/features/pos/pos.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/dialogs/app_confirm_dialog.dart';

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
              stock: 10,
              minStock: 2,
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
              name: 'Es Teh Manis',
              sellingPrice: 5000,
              costPrice: 2000,
              stock: 5,
              minStock: 2,
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
            name: 'Kedai Kopi Berkah',
            address: 'Jl. Ahmad Yani No. 5',
            phone: '08123456789',
            currencyCode: 'IDR',
            taxRate: 0,
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

  group('Interactive Cart Belanja Widget Tests (Task T2.2)', () {
    testWidgets('Tablet: Increment (+), decrement (-), and delete item in cart sidebar',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Add Nasi Goreng
      final nasiCard = find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial');
      await tester.tap(nasiCard);
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Rp25.000'), findsWidgets);

      // 2. Increment item using (+) button inside PosCartSidebar
      final plusBtn = find.descendant(
        of: find.byType(PosCartSidebar),
        matching: find.byTooltip('Tambah Kuantitas'),
      );
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      expect(find.text('2 item'), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);

      // 3. Decrement item using (-) button
      final minusBtn = find.descendant(
        of: find.byType(PosCartSidebar),
        matching: find.byTooltip('Kurangi Kuantitas'),
      );
      await tester.tap(minusBtn);
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);
      expect(find.text('Rp25.000'), findsWidgets);

      // 4. Delete item using Delete button
      final deleteBtn = find.descendant(
        of: find.byType(PosCartSidebar),
        matching: find.byTooltip('Hapus Item'),
      );
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      expect(find.text('0 item'), findsOneWidget);
      expect(find.text('Keranjang Kosong'), findsNWidgets(2));
    });

    testWidgets('Tablet: Directly edit quantity and notes via PosQuantityEditDialog',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add Nasi Goreng to cart
      await tester.tap(find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial'));
      await tester.pumpAndSettle();

      // Tap on quantity badge or edit button to open PosQuantityEditDialog
      final editBtn = find.descendant(
        of: find.byType(PosCartSidebar),
        matching: find.byTooltip('Ubah Jumlah & Catatan'),
      );
      expect(editBtn, findsOneWidget);
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // PosQuantityEditDialog is rendered
      expect(find.byType(PosQuantityEditDialog), findsOneWidget);
      expect(find.text('Atur Pesanan & Kuantitas'), findsOneWidget);
      expect(find.text('Nasi Goreng Spesial'), findsWidgets);
      expect(find.text('Stok: 10 pcs'), findsOneWidget);

      // Tap +5 preset chip
      final preset5 = find.widgetWithText(ActionChip, '+5');
      expect(preset5, findsOneWidget);
      await tester.tap(preset5);
      await tester.pumpAndSettle();

      // Subtotal preview should reflect 6 items
      expect(find.text('Rp150.000'), findsWidgets);

      // Add custom notes
      final notesField = find.widgetWithText(TextFormField, 'Contoh: Pedas sedang, tanpa es batu...');
      await tester.enterText(notesField, 'Pedas level 3, ekstra kerupuk');
      await tester.pumpAndSettle();

      // Tap Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(PosQuantityEditDialog), findsNothing);

      // Cart sidebar now displays 6 items and custom notes
      expect(find.text('6 item'), findsOneWidget);
      expect(find.text('Rp150.000'), findsWidgets);
      expect(find.text('Pedas level 3, ekstra kerupuk'), findsOneWidget);
    });

    testWidgets('Tablet: PosQuantityEditDialog enforces stock limits and disallows invalid quantities',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add Nasi Goreng (stock: 10)
      await tester.tap(find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial'));
      await tester.pumpAndSettle();

      // Open quantity dialog
      await tester.tap(find.byTooltip('Ubah Jumlah & Catatan'));
      await tester.pumpAndSettle();

      // Enter 15 (> stock 10)
      final qtyInput = find.descendant(
        of: find.byType(PosQuantityEditDialog),
        matching: find.byType(TextField),
      ).first;
      await tester.enterText(qtyInput, '15');
      await tester.pumpAndSettle();

      // Validation error displayed
      expect(find.textContaining('Melebihi stok tersedia'), findsOneWidget);

      // Simpan button should be disabled
      final saveBtn = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Simpan'),
      );
      expect(saveBtn.onPressed, isNull);

      // Close dialog via Batal
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('1 item'), findsOneWidget);
    });

    testWidgets('Clear cart button displays confirmation dialog before emptying items',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add 2 products
      await tester.tap(find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PosProductCard, 'Es Teh Manis'));
      await tester.pumpAndSettle();

      expect(find.text('2 item'), findsOneWidget);

      // Tap Kosongkan Keranjang icon button
      final clearCartBtn = find.descendant(
        of: find.byType(PosCartSidebar),
        matching: find.byTooltip('Kosongkan Keranjang'),
      );
      await tester.tap(clearCartBtn);
      await tester.pumpAndSettle();

      // AppConfirmDialog appears
      expect(find.byType(AppConfirmDialog), findsOneWidget);
      expect(find.text('Kosongkan Keranjang?'), findsOneWidget);

      // Tap 'Batal' -> cart is NOT emptied
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('2 item'), findsOneWidget);

      // Tap Kosongkan Keranjang again -> Tap 'Kosongkan'
      await tester.tap(clearCartBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kosongkan'));
      await tester.pumpAndSettle();

      // Cart is now empty
      expect(find.text('0 item'), findsOneWidget);
      expect(find.text('Keranjang Kosong'), findsNWidgets(2));
    });

    testWidgets('Mobile: PosCartModalSheet provides interactive stepper and edit quantity',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add Es Teh Manis (Rp5.000, stock: 5)
      await tester.tap(find.widgetWithText(PosProductCard, 'Es Teh Manis'));
      await tester.pumpAndSettle();

      // Tap 'Lihat Pesanan' on bottom bar
      await tester.tap(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();

      // PosCartModalSheet is visible
      expect(find.byType(PosCartModalSheet), findsOneWidget);
      expect(find.text('Rincian Pesanan'), findsOneWidget);

      // Increment (+) inside modal
      final plusBtn = find.descendant(
        of: find.byType(PosCartModalSheet),
        matching: find.byTooltip('Tambah Kuantitas'),
      );
      await tester.tap(plusBtn);
      await tester.pumpAndSettle();

      expect(find.text('2 item'), findsOneWidget);
      expect(find.text('Rp10.000'), findsWidgets);

      // Tap edit button to open PosQuantityEditDialog
      final editBtn = find.descendant(
        of: find.byType(PosCartModalSheet),
        matching: find.byTooltip('Ubah Jumlah & Catatan'),
      );
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PosQuantityEditDialog), findsOneWidget);

      // Tap 'Maks (5)' preset
      await tester.tap(find.text('Maks (5)'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Modal sheet now shows 5 items
      expect(find.text('5 item'), findsOneWidget);
      expect(find.text('Rp25.000'), findsWidgets);

      // Close modal
      await tester.tap(find.text('Tutup Keranjang'));
      await tester.pumpAndSettle();
      expect(find.byType(PosCartModalSheet), findsNothing);
    });
  });
}
