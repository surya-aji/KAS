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

void main() {
  group('PosPaymentModal Widget Tests (Task T2.4)', () {
    testWidgets('Renders modal header, total amount banner, and 3 payment methods (Tunai, Transfer, QRIS)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: PosPaymentModal(
              totalAmount: 50000,
              totalQuantity: 2,
              businessName: 'Toko Berkah',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header and total banner
      expect(find.text('Metode Pembayaran'), findsOneWidget);
      expect(find.text('TOTAL TAGIHAN'), findsOneWidget);
      expect(find.text('Rp50.000'), findsWidgets);
      expect(find.text('2 item dalam pesanan'), findsOneWidget);

      // Check the 3 payment methods
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('QRIS'), findsOneWidget);

      // Check action buttons
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Konfirmasi Tunai'), findsOneWidget);
    });

    testWidgets('Tunai View: Quick cash suggestions, change calculation, and shortage detection',
        (tester) async {
      PaymentResult? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PosPaymentModal(
              totalAmount: 35000,
              totalQuantity: 3,
              businessName: 'Toko Berkah',
              onPaymentConfirmed: (res) => confirmedResult = res,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By default, initial cash is exact amount (Rp35.000)
      expect(find.text('Uang Pas'), findsOneWidget);
      expect(find.text('Tidak ada kembalian'), findsOneWidget);

      // Quick cash chip for Uang Pas and higher denomination
      expect(find.text('Uang Pas (Rp35.000)'), findsOneWidget);
      final chip50k = find.text('Rp50.000');
      expect(chip50k, findsOneWidget);

      // Tap on Rp50.000 quick cash chip
      await tester.tap(chip50k);
      await tester.pumpAndSettle();

      // Real-time change calculation: Rp50.000 - Rp35.000 = Rp15.000
      expect(find.text('Kembalian Tunai'), findsOneWidget);
      expect(find.text('Rp15.000'), findsOneWidget);

      // Tap confirmation
      await tester.tap(find.text('Konfirmasi Tunai'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.method, PaymentMethodType.cash);
      expect(confirmedResult!.amountPaid, 50000);
      expect(confirmedResult!.changeAmount, 15000);
    });

    testWidgets('Tunai View: Manual input underpayment displays warning and disables confirm button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: PosPaymentModal(
              totalAmount: 50000,
              totalQuantity: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter 20000 into the currency field
      final textFieldFinder = find.byType(TextField).first;
      await tester.tap(textFieldFinder);
      await tester.enterText(textFieldFinder, '20000');
      await tester.pumpAndSettle();

      // Check shortage display
      expect(find.text('Pembayaran Kurang'), findsOneWidget);
      expect(find.text('Rp30.000'), findsOneWidget);
      expect(find.text('Kurang Rp30.000'), findsOneWidget);

      // Tapping the disabled button should not trigger confirm
      final confirmButton = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Kurang Rp30.000'),
      );
      expect(confirmButton.onPressed, isNull);
    });

    testWidgets('Transfer View: Bank selection, copy account button, and reference number',
        (tester) async {
      PaymentResult? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PosPaymentModal(
              totalAmount: 75000,
              totalQuantity: 2,
              businessName: 'Usaha Berkah',
              onPaymentConfirmed: (res) => confirmedResult = res,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Transfer tab
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      // Verify Bank selection chips
      expect(find.text('Pilih Bank Tujuan Transfer'), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.text('Mandiri'), findsOneWidget);
      expect(find.text('BRI'), findsOneWidget);
      expect(find.text('BNI'), findsOneWidget);

      // Tap on Mandiri bank chip
      await tester.tap(find.text('Mandiri'));
      await tester.pumpAndSettle();

      expect(find.text('Rekening Bank Mandiri'), findsOneWidget);
      expect(find.text('137-00-1928-3829'), findsOneWidget);

      // Test Salin (copy) button
      expect(find.text('Salin'), findsOneWidget);
      await tester.tap(find.text('Salin'));
      await tester.pump();
      expect(find.textContaining('137-00-1928-3829 berhasil disalin'), findsOneWidget);
      // Dismiss SnackBar so it does not obscure bottom action button
      ScaffoldMessenger.of(tester.element(find.byType(PosPaymentModal))).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      // Enter reference number
      final refFieldFinder = find.widgetWithText(
        TextField,
        'Contoh: TRF-902381 / Budi Santoso',
      );
      expect(refFieldFinder, findsOneWidget);
      await tester.enterText(refFieldFinder, 'TRF-TEST-999');
      await tester.pumpAndSettle();

      // Confirm payment
      await tester.tap(find.text('Konfirmasi Transfer'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.method, PaymentMethodType.transfer);
      expect(confirmedResult!.bankName, 'Mandiri');
      expect(confirmedResult!.referenceNumber, 'TRF-TEST-999');
      expect(confirmedResult!.amountPaid, 75000);
      expect(confirmedResult!.changeAmount, 0);
    });

    testWidgets('QRIS View: Header, NMID, simulated QR code, scan instructions, and confirmation',
        (tester) async {
      PaymentResult? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: PosPaymentModal(
              totalAmount: 42000,
              totalQuantity: 1,
              businessName: 'Warung Kopi Senja',
              onPaymentConfirmed: (res) => confirmedResult = res,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to QRIS tab
      await tester.tap(find.text('QRIS'));
      await tester.pumpAndSettle();

      // Verify QRIS elements
      expect(find.text('Standar Pembayaran Nasional'), findsOneWidget);
      expect(find.text('NMID: ID1020030040'), findsOneWidget);
      expect(find.text('Warung Kopi Senja'), findsOneWidget);
      expect(find.text('Tagihan: Rp42.000'), findsOneWidget);
      expect(find.textContaining('Scan via GoPay, OVO, Dana, ShopeePay'), findsOneWidget);
      expect(find.text('Pembayaran QRIS Berhasil'), findsOneWidget);

      // Enter QRIS RRN
      final rrnField = find.widgetWithText(
        TextField,
        'Contoh: RRN-892182910',
      );
      expect(rrnField, findsOneWidget);
      await tester.enterText(rrnField, 'RRN-554433');
      await tester.pumpAndSettle();

      // Confirm QRIS payment
      await tester.tap(find.text('Konfirmasi QRIS'));
      await tester.pumpAndSettle();

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.method, PaymentMethodType.qris);
      expect(confirmedResult!.referenceNumber, 'RRN-554433');
      expect(confirmedResult!.amountPaid, 42000);
      expect(confirmedResult!.changeAmount, 0);
    });

    testWidgets('PaymentMethodScreen renders as standalone scaffold page',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const PaymentMethodScreen(
            totalAmount: 100000,
            totalQuantity: 4,
            businessName: 'Toko Sukses Mandiri',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Metode Pembayaran'), findsWidgets);
      expect(find.text('Rp100.000'), findsWidgets);
      expect(find.text('4 item dalam pesanan'), findsOneWidget);
    });
  });

  group('POS Cashier Integration Tests with Payment Modal (Task T2.4)', () {
    Widget buildPosTestApp() {
      final pRepo = MockProductRepository(
        initialProducts: [
          Product(
            id: 'p-1',
            categoryId: 'c-food',
            categoryName: 'Makanan',
            sku: 'MKN-01',
            name: 'Nasi Goreng',
            sellingPrice: 20000,
            costPrice: 12000,
            stock: 20,
            minStock: 2,
            trackStock: true,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ],
      );

      final cRepo = MockCategoryRepository(
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

      final profRepo = MockBusinessProfileRepository(
        initialProfile: BusinessProfile(
          id: 'prof-test',
          name: 'Kafe Berkah',
          address: 'Jl. Melati No. 1',
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

    testWidgets('Tablet: Adding item to cart and tapping checkout opens PosPaymentModal dialog',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPosTestApp());
      await tester.pumpAndSettle();

      // Add product to cart
      await tester.tap(find.text('Nasi Goreng'));
      await tester.pumpAndSettle();

      // Checkout button in sidebar is active: "Lanjut Pembayaran (Rp20.000)"
      final checkoutBtn = find.text('Lanjut Pembayaran (Rp20.000)');
      expect(checkoutBtn, findsOneWidget);

      await tester.tap(checkoutBtn);
      await tester.pumpAndSettle();

      // Payment modal should open as dialog
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Metode Pembayaran'), findsOneWidget);
      expect(find.text('Tunai'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('QRIS'), findsOneWidget);

      // Confirm Cash payment
      await tester.tap(find.text('Konfirmasi Tunai'));
      await tester.pumpAndSettle();

      // Dialog closed and confirmation snackbar shown
      expect(find.byType(Dialog), findsNothing);
      expect(find.textContaining('Pembayaran Tunai (Cash) berhasil: Rp20.000'), findsOneWidget);
    });

    testWidgets('Mobile: Adding item, opening cart sheet, and tapping Bayar Sekarang opens Payment Modal',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPosTestApp());
      await tester.pumpAndSettle();

      // Add product to cart
      await tester.tap(find.text('Nasi Goreng'));
      await tester.pumpAndSettle();

      // Tap "Lihat Pesanan" on bottom bar
      await tester.tap(find.text('Lihat Pesanan'));
      await tester.pumpAndSettle();

      // Cart modal sheet is shown
      expect(find.text('Rincian Pesanan'), findsOneWidget);
      expect(find.text('Bayar Sekarang'), findsOneWidget);

      // Tap "Bayar Sekarang"
      await tester.tap(find.text('Bayar Sekarang'));
      await tester.pumpAndSettle();

      // Payment modal is displayed
      expect(find.text('Metode Pembayaran'), findsOneWidget);
      expect(find.text('Pilih Metode Pembayaran'), findsOneWidget);

      // Switch to QRIS and confirm
      await tester.tap(find.text('QRIS'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Konfirmasi QRIS'));
      await tester.pumpAndSettle();

      // Success SnackBar is displayed
      expect(find.textContaining('Pembayaran QRIS Digital berhasil: Rp20.000'), findsOneWidget);
    });
  });
}
