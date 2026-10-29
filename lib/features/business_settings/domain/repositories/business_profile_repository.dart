import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';

/// Abstract contract for managing business profile persistence.
///
/// Follows Clean Architecture to decouple domain logic from SQLite / Drift data source.
abstract class BusinessProfileRepository {
  /// Fetches the current business profile.
  Future<BusinessProfile> getProfile();

  /// Persists the updated business profile.
  Future<void> saveProfile(BusinessProfile profile);

  /// Emits reactive updates whenever business settings change.
  Stream<BusinessProfile> watchProfile();
}
