import 'dart:async';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/domain/repositories/business_profile_repository.dart';

/// In-memory mock implementation of [BusinessProfileRepository]
/// for the Frontend-First development milestone (T1.1).
///
/// Simulates offline local storage without requiring Drift SQLite tables yet.
class MockBusinessProfileRepository implements BusinessProfileRepository {
  MockBusinessProfileRepository({BusinessProfile? initialProfile})
      : _currentProfile = initialProfile ?? BusinessProfile.initial() {
    _streamController = StreamController<BusinessProfile>.broadcast();
    _streamController.add(_currentProfile);
  }

  BusinessProfile _currentProfile;
  late final StreamController<BusinessProfile> _streamController;

  /// Synchronous access to current profile state.
  BusinessProfile get currentProfile => _currentProfile;

  @override
  Future<BusinessProfile> getProfile() async {
    return _currentProfile;
  }

  @override
  Future<void> saveProfile(BusinessProfile profile) async {
    _currentProfile = profile.copyWith(updatedAt: DateTime.now());
    _streamController.add(_currentProfile);
  }

  @override
  Stream<BusinessProfile> watchProfile() {
    return _streamController.stream;
  }

  /// Clean up resources when repository is disposed.
  void dispose() {
    _streamController.close();
  }
}
