import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/business_settings/data/repositories/mock_business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';
import 'package:kas_usaha/features/catalog/catalog.dart';
import 'package:kas_usaha/features/pos/pos.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';

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
              name: 'Es Teh Manis',
              sellingPrice: 5000,
              costPrice: 2000,
              stock: 20,
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
              isActive: true,
              createdAt: DateTime.now(),
            ),
          ],
        );

    final profRepo = profileRepo ??
        MockBusinessProfileRepository(
          initialProfile: BusinessProfile(
            id: 'prof-test',
            name: 'Toko Berkah Usaha',
            address: 'Jl. Ahmad Yani No. 10',
            phone: '08123456789',
            currencyCode: 'IDR',
            isTaxEnabled: false,
            taxRate: 11.0,
            isDiscountEnabled: false,
            defaultDiscountRate: 0.0,
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

  group('POS Real-time Transaction Calculation UI Widget Tests (Task T2.3)', () {
    testWidgets('Tablet: Real-time calculation breakdown in PosCartSidebar with items and checkout',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add Nasi Goreng (25.000) twice -> 50.000
      final nasiCard = find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial');
      await tester.tap(nasiCard);
      await tester.pumpAndSettle();
      await tester.tap(nasiCard);
      await tester.pumpAndSettle();

      // Verify PosCartSidebar displays gross subtotal
      expect(find.text('Subtotal (2 item):'), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);
      expect(find.text('Total Pembayaran'), findsOneWidget);
      expect(find.text('Lanjut Pembayaran (Rp50.000)'), findsOneWidget);
    });

    testWidgets('Tablet: Applying item-level discount in PosQuantityEditDialog updates line item and sidebar',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add Nasi Goreng (25.000)
      await tester.tap(find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial'));
      await tester.pumpAndSettle();

      // Open PosQuantityEditDialog via edit button
      final editBtn = find.descendant(
        of: find.byType(PosCartSidebar),
        matching: find.byTooltip('Ubah Jumlah & Catatan'),
      );
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PosQuantityEditDialog), findsOneWidget);
      expect(find.text('Diskon Item'), findsOneWidget);

      // Select 20% quick discount preset chip
      final chip20 = find.widgetWithText(ActionChip, '20%');
      await tester.tap(chip20);
      await tester.pumpAndSettle();

      // In PosQuantityEditDialog live calculation:
      // Gross: 25.000, 20% = 5.000 discount, net subtotal = 20.000
      expect(find.text('-Rp5.000'), findsWidgets);
      expect(find.text('Rp20.000'), findsWidgets);

      // Save changes
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // PosQuantityEditDialog dismissed
      expect(find.byType(PosQuantityEditDialog), findsNothing);

      // Verify PosCartSidebar displays updated figures:
      // Item discount badge: 'Diskon 20%'
      expect(find.widgetWithText(AppBadge, 'Diskon 20%'), findsOneWidget);
      expect(find.text('Diskon Item:'), findsOneWidget);
      expect(find.text('-Rp5.000'), findsOneWidget);
      expect(find.text('Lanjut Pembayaran (Rp20.000)'), findsOneWidget);
    });

    testWidgets('Tablet: PosDiscountTaxDialog applies transaction discount and tax (PPN) with live simulation',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add 2x Nasi Goreng (50.000)
      final nasiCard = find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial');
      await tester.tap(nasiCard);
      await tester.pumpAndSettle();
      await tester.tap(nasiCard);
      await tester.pumpAndSettle();

      // Tap 'Diskon & Pajak' button in PosCartSidebar
      final discTaxBtn = find.text('Diskon & Pajak');
      expect(discTaxBtn, findsOneWidget);
      await tester.tap(discTaxBtn);
      await tester.pumpAndSettle();

      // PosDiscountTaxDialog opens
      expect(find.byType(PosDiscountTaxDialog), findsOneWidget);
      expect(find.text('Atur Diskon & Pajak Transaksi'), findsOneWidget);
      expect(find.text('Simulasi Kalkulasi Real-time'), findsOneWidget);

      // Apply 10% transaction discount chip
      final chip10 = find.widgetWithText(ActionChip, '10%');
      await tester.tap(chip10);
      await tester.pumpAndSettle();

      // Toggle Pajak (PPN) Switch ON
      final taxSwitch = find.widgetWithText(SwitchListTile, 'Kenakan Pajak (PPN)');
      await tester.tap(taxSwitch);
      await tester.pumpAndSettle();

      // In dialog live simulation:
      // Gross: 50.000
      // Transaction Discount (10%): -5.000
      // DPP: 45.000
      // Pajak PPN (11% of 45.000) = 4.950
      // Grand Total = 49.950
      expect(find.text('Rp49.950'), findsWidgets);
      expect(find.text('+Rp4.950'), findsOneWidget);

      // Tap Terapkan button
      final applyBtn = find.widgetWithText(AppButton, 'Terapkan (Rp49.950)');
      expect(applyBtn, findsOneWidget);
      await tester.tap(applyBtn);
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(PosDiscountTaxDialog), findsNothing);

      // Verify PosCartSidebar reflects full breakdown:
      expect(find.text('Subtotal (2 item):'), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);
      expect(find.text('Diskon Transaksi (10%):'), findsOneWidget);
      expect(find.text('-Rp5.000'), findsOneWidget);
      expect(find.text('Dasar Pengenaan Pajak (DPP):'), findsOneWidget);
      expect(find.text('Rp45.000'), findsOneWidget);
      expect(find.text('Pajak / PPN (11%):'), findsOneWidget);
      expect(find.text('+Rp4.950'), findsOneWidget);
      expect(find.text('Rp49.950'), findsWidgets);
      expect(find.text('Lanjut Pembayaran (Rp49.950)'), findsOneWidget);
    });

    testWidgets('Smartphone: Mobile PosCartModalSheet shows complete real-time breakdown',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Add Nasi Goreng
      await tester.tap(find.widgetWithText(PosProductCard, 'Nasi Goreng Spesial'));
      await tester.pumpAndSettle();

      // Verify bottom cart bar displays subtotal
      expect(find.text('Rp25.000'), findsWidgets);
      expect(find.text('1 item terpilih'), findsOneWidget);

      // Tap Lihat Pesanan
      await tester.tap(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();

      // Mobile sheet opens
      expect(find.byType(PosCartModalSheet), findsOneWidget);
      expect(find.text('Rincian Pesanan'), findsOneWidget);
      expect(find.text('Subtotal (1 item):'), findsOneWidget);
      expect(find.text('Total Pembayaran'), findsOneWidget);
      expect(find.text('Atur Diskon & Pajak'), findsOneWidget);
    });
  });
}
