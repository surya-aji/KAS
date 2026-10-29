import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/features/business_settings/data/repositories/mock_business_profile_repository.dart';
import 'package:kas_usaha/features/business_settings/domain/models/business_profile.dart';
import 'package:kas_usaha/features/business_settings/domain/repositories/business_profile_repository.dart';

/// Status lifecycle for the business profile form and state.
enum BusinessProfileStatus {
  initial,
  loading,
  loaded,
  saving,
  success,
  error,
}

/// State representation for Business Profile presentation.
class BusinessProfileState {
  const BusinessProfileState({
    required this.status,
    required this.profile,
    this.errorMessage,
  });

  final BusinessProfileStatus status;
  final BusinessProfile profile;
  final String? errorMessage;

  bool get isLoading => status == BusinessProfileStatus.loading;
  bool get isSaving => status == BusinessProfileStatus.saving;
  bool get isSuccess => status == BusinessProfileStatus.success;
  bool get hasError => status == BusinessProfileStatus.error;

  factory BusinessProfileState.initial() {
    return BusinessProfileState(
      status: BusinessProfileStatus.initial,
      profile: BusinessProfile.initial(),
    );
  }

  BusinessProfileState copyWith({
    BusinessProfileStatus? status,
    BusinessProfile? profile,
    String? errorMessage,
  }) {
    return BusinessProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessProfileState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          profile == other.profile &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      status.hashCode ^ profile.hashCode ^ errorMessage.hashCode;
}

/// Riverpod Notifier managing business profile state operations.
class BusinessProfileNotifier extends Notifier<BusinessProfileState> {
  @override
  BusinessProfileState build() {
    return BusinessProfileState.initial();
  }

  BusinessProfileRepository get _repository =>
      ref.read(businessProfileRepositoryProvider);

  /// Loads business profile from repository.
  Future<void> loadProfile() async {
    state = state.copyWith(status: BusinessProfileStatus.loading);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(
        status: BusinessProfileStatus.loaded,
        profile: profile,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: BusinessProfileStatus.error,
        errorMessage: 'Gagal memuat profil usaha: $e',
      );
    }
  }

  /// Validates and saves updated business profile.
  /// Returns `true` if save succeeded.
  Future<bool> saveProfile(BusinessProfile updatedProfile) async {
    // Basic domain validation
    if (updatedProfile.name.trim().isEmpty) {
      state = state.copyWith(
        status: BusinessProfileStatus.error,
        errorMessage: 'Nama usaha tidak boleh kosong.',
      );
      return false;
    }

    if (updatedProfile.taxRate < 0 || updatedProfile.taxRate > 100) {
      state = state.copyWith(
        status: BusinessProfileStatus.error,
        errorMessage: 'Persentase pajak harus antara 0% dan 100%.',
      );
      return false;
    }

    if (updatedProfile.defaultDiscountRate < 0 ||
        updatedProfile.defaultDiscountRate > 100) {
      state = state.copyWith(
        status: BusinessProfileStatus.error,
        errorMessage: 'Persentase diskon harus antara 0% dan 100%.',
      );
      return false;
    }

    state = state.copyWith(status: BusinessProfileStatus.saving);
    try {
      await _repository.saveProfile(updatedProfile);
      state = state.copyWith(
        status: BusinessProfileStatus.success,
        profile: updatedProfile,
        errorMessage: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: BusinessProfileStatus.error,
        errorMessage: 'Gagal menyimpan profil usaha: $e',
      );
      return false;
    }
  }

  /// Resets status back to loaded after displaying feedback.
  void resetStatus() {
    if (state.status == BusinessProfileStatus.success ||
        state.status == BusinessProfileStatus.error) {
      state = state.copyWith(status: BusinessProfileStatus.loaded);
    }
  }
}

/// Provider for the BusinessProfileRepository instance.
final businessProfileRepositoryProvider =
    Provider<BusinessProfileRepository>((ref) {
  final repo = MockBusinessProfileRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// NotifierProvider for accessing and mutating business profile state.
final businessProfileProvider =
    NotifierProvider<BusinessProfileNotifier, BusinessProfileState>(
  BusinessProfileNotifier.new,
);
