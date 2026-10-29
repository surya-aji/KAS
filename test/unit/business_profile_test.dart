import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/business_settings/data/repositories/mock_business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';

void main() {
  group('BusinessProfile Domain Model', () {
    test('initial factory provides sensible defaults', () {
      final profile = BusinessProfile.initial();
      expect(profile.name, isNotEmpty);
      expect(profile.currencyCode, 'IDR');
      expect(profile.currencySymbol, 'Rp');
      expect(profile.isTaxEnabled, isTrue);
      expect(profile.taxRate, 11.0);
      expect(profile.effectiveTaxMultiplier, 0.11);
    });

    test('effective multipliers calculate accurately', () {
      const p1 = BusinessProfile(
        id: '1',
        name: 'Test',
        isTaxEnabled: true,
        taxRate: 10.0,
        isDiscountEnabled: true,
        defaultDiscountRate: 5.0,
      );
      expect(p1.effectiveTaxMultiplier, 0.10);
      expect(p1.effectiveDiscountMultiplier, 0.05);

      const p2 = BusinessProfile(
        id: '2',
        name: 'Test 2',
        isTaxEnabled: false,
        taxRate: 10.0,
        isDiscountEnabled: false,
        defaultDiscountRate: 5.0,
      );
      expect(p2.effectiveTaxMultiplier, 0.0);
      expect(p2.effectiveDiscountMultiplier, 0.0);
    });

    test('serialization toMap and fromMap roundtrip matches', () {
      final original = BusinessProfile.initial().copyWith(
        name: 'Warung Kopi Mantap',
        address: 'Jl. Merdeka No. 10',
        phone: '081299998888',
        email: 'warkop@test.com',
      );

      final map = original.toMap();
      final deserialized = BusinessProfile.fromMap(map);

      expect(deserialized.name, original.name);
      expect(deserialized.address, original.address);
      expect(deserialized.phone, original.phone);
      expect(deserialized.email, original.email);
      expect(deserialized.currencyCode, original.currencyCode);
      expect(deserialized.currencySymbol, original.currencySymbol);
      expect(deserialized.isTaxEnabled, original.isTaxEnabled);
      expect(deserialized.taxRate, original.taxRate);
    });
  });

  group('BusinessProfileNotifier & Mock Repository', () {
    test('loads profile successfully upon initialization', () async {
      final repository = MockBusinessProfileRepository();
      final container = ProviderContainer(
        overrides: [
          businessProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      // Initial state is loading or initial
      final notifier = container.read(businessProfileProvider.notifier);
      await notifier.loadProfile();

      final state = container.read(businessProfileProvider);
      expect(state.status, BusinessProfileStatus.loaded);
      expect(state.profile.name, isNotEmpty);
    });

    test('saves updated profile successfully', () async {
      final repository = MockBusinessProfileRepository();
      final container = ProviderContainer(
        overrides: [
          businessProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(businessProfileProvider.notifier);
      await notifier.loadProfile();

      final current = container.read(businessProfileProvider).profile;
      final updated = current.copyWith(name: 'Toko Sukses Sejahtera');

      final success = await notifier.saveProfile(updated);
      expect(success, isTrue);

      final state = container.read(businessProfileProvider);
      expect(state.status, BusinessProfileStatus.success);
      expect(state.profile.name, 'Toko Sukses Sejahtera');

      // Verify repository was updated
      final fromRepo = await repository.getProfile();
      expect(fromRepo.name, 'Toko Sukses Sejahtera');
    });

    test('rejects empty business name with error', () async {
      final repository = MockBusinessProfileRepository();
      final container = ProviderContainer(
        overrides: [
          businessProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(businessProfileProvider.notifier);
      await notifier.loadProfile();

      final current = container.read(businessProfileProvider).profile;
      final invalid = current.copyWith(name: '   ');

      final success = await notifier.saveProfile(invalid);
      expect(success, isFalse);

      final state = container.read(businessProfileProvider);
      expect(state.status, BusinessProfileStatus.error);
      expect(state.errorMessage, contains('Nama usaha tidak boleh kosong'));
    });

    test('rejects out-of-range tax rate with error', () async {
      final repository = MockBusinessProfileRepository();
      final container = ProviderContainer(
        overrides: [
          businessProfileRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(businessProfileProvider.notifier);
      await notifier.loadProfile();

      final current = container.read(businessProfileProvider).profile;
      final invalid = current.copyWith(taxRate: 150.0);

      final success = await notifier.saveProfile(invalid);
      expect(success, isFalse);

      final state = container.read(businessProfileProvider);
      expect(state.status, BusinessProfileStatus.error);
      expect(state.errorMessage, contains('Persentase pajak harus antara 0% dan 100%'));
    });
  });
}
