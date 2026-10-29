import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/business_settings/data/repositories/mock_business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/domain/repositories/business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';
import 'package:kas_usaha/features/business_settings/presentation/screens/business_profile_screen.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';

void main() {
  Widget buildTestWidget({
    BusinessProfileRepository? repository,
  }) {
    final mockRepo = repository ??
        MockBusinessProfileRepository(
          initialProfile: const BusinessProfile(
            id: 'test-id',
            name: 'Toko Test UI',
            address: 'Jl. Testing No. 123',
            phone: '081122334455',
            email: 'test@toko.com',
            currencyCode: 'IDR',
            currencySymbol: 'Rp',
            isTaxEnabled: true,
            taxRate: 11.0,
            isDiscountEnabled: false,
            defaultDiscountRate: 0.0,
            receiptFooterMessage: 'Terima kasih telah berbelanja!',
          ),
        );

    return ProviderScope(
      overrides: [
        businessProfileRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const BusinessProfileScreen(),
      ),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('BusinessProfileScreen Widget', () {
    testWidgets('renders all section headers and form inputs', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('Profil Usaha'), findsOneWidget);

      // Section titles
      expect(find.text('Identitas Usaha'), findsOneWidget);
      expect(find.text('Mata Uang & Format'), findsOneWidget);
      expect(find.text('Pajak & Diskon Standar'), findsOneWidget);
      expect(find.text('Pengaturan Struk'), findsOneWidget);

      // Initial populated values
      expect(find.text('Toko Test UI'), findsWidgets);
      expect(find.text('Jl. Testing No. 123'), findsOneWidget);
      expect(find.text('081122334455'), findsWidgets);

      // Save button
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text('Simpan Profil Usaha'), findsOneWidget);
    });

    testWidgets('validates required business name field', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the name field and clear it
      final nameField = find.widgetWithText(TextFormField, 'Toko Test UI');
      expect(nameField, findsOneWidget);

      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Tap save button
      final saveBtn = find.byType(AppButton);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Form validation error appears
      expect(find.text('Nama usaha wajib diisi'), findsOneWidget);
    });

    testWidgets('successfully saves updated name and shows feedback snackbar',
        (tester) async {
      configureViewport(tester);
      final mockRepo = MockBusinessProfileRepository();
      await tester.pumpWidget(buildTestWidget(repository: mockRepo));
      await tester.pumpAndSettle();

      // Find business name field and edit it
      final nameFinder = find.byType(TextFormField).first;
      await tester.enterText(nameFinder, 'Warung Berkah Digital');
      await tester.pumpAndSettle();

      // Tap save button
      final saveBtn = find.byType(AppButton);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(); // Start save async

      // Wait for repository save delay and pump frame for snackbar presentation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify success snackbar appears
      expect(
        find.text('Profil usaha berhasil disimpan secara offline.'),
        findsOneWidget,
      );

      // Verify repository was updated
      expect(mockRepo.currentProfile.name, 'Warung Berkah Digital');
    });

    testWidgets('toggling tax switch reveals tax rate input field',
        (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially tax is enabled in our test profile, so Persentase Pajak is visible
      expect(find.text('Persentase Pajak (%)'), findsOneWidget);

      // Tap tax switch to disable
      final taxSwitch = find.widgetWithText(
        SwitchListTile,
        'Terapkan Pajak (PPN)',
      );
      await tester.ensureVisible(taxSwitch);
      await tester.tap(taxSwitch);
      await tester.pumpAndSettle();

      // Tax rate field should be hidden
      expect(find.text('Persentase Pajak (%)'), findsNothing);

      // Tap again to enable
      await tester.tap(taxSwitch);
      await tester.pumpAndSettle();

      // Tax rate field reappears
      expect(find.text('Persentase Pajak (%)'), findsOneWidget);
    });
  });
}
