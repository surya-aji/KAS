import 'package:flutter/foundation.dart';
import 'package:kas_usaha/shared/constants/app_constants.dart';

/// Domain model representing the business identity and default financial rules.
///
/// Offline-first & local-first: stored in SQLite `business_settings` table.
/// Single-business per installation as specified in section 1.1 of the architecture.
@immutable
class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.currencyCode = AppConstants.defaultCurrencyCode,
    this.currencySymbol = AppConstants.defaultCurrencySymbol,
    this.isTaxEnabled = false,
    this.taxRate = 11.0,
    this.isDiscountEnabled = false,
    this.defaultDiscountRate = 0.0,
    this.receiptFooterMessage = 'Terima kasih telah berbelanja!',
    this.updatedAt,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Business / store trade name (Nama Usaha).
  final String name;

  /// Physical address of the store (Alamat).
  final String address;

  /// Contact phone number or WhatsApp (Nomor Telepon).
  final String phone;

  /// Optional email address for official communication.
  final String email;

  /// ISO 4217 currency code (e.g. 'IDR').
  final String currencyCode;

  /// Visual currency symbol (e.g. 'Rp').
  final String currencySymbol;

  /// Whether tax is applied to transactions by default.
  final bool isTaxEnabled;

  /// Default tax percentage rate (e.g., 11.0 for PPN 11%).
  final double taxRate;

  /// Whether global/default discount is enabled.
  final bool isDiscountEnabled;

  /// Default global discount percentage rate (e.g., 5.0 for 5%).
  final double defaultDiscountRate;

  /// Custom note printed at the bottom of customer receipts.
  final String receiptFooterMessage;

  /// Timestamp of the last update.
  final DateTime? updatedAt;

  /// Calculated effective tax multiplier (e.g. 0.11 for 11%).
  double get effectiveTaxMultiplier => isTaxEnabled ? (taxRate / 100.0) : 0.0;

  /// Calculated effective discount multiplier (e.g. 0.05 for 5%).
  double get effectiveDiscountMultiplier =>
      isDiscountEnabled ? (defaultDiscountRate / 100.0) : 0.0;

  /// Default initial profile for new installations.
  factory BusinessProfile.initial() {
    return BusinessProfile(
      id: 'default-profile-id',
      name: 'Toko Kas Usaha',
      address: 'Jl. Bisnis Raya No. 1, Jakarta',
      phone: '081234567890',
      email: 'kontak@tokokasusaha.com',
      currencyCode: AppConstants.defaultCurrencyCode,
      currencySymbol: AppConstants.defaultCurrencySymbol,
      isTaxEnabled: true,
      taxRate: 11.0,
      isDiscountEnabled: false,
      defaultDiscountRate: 0.0,
      receiptFooterMessage: 'Terima kasih telah berbelanja!',
      updatedAt: DateTime.now(),
    );
  }

  /// Create a copy with modified properties.
  BusinessProfile copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    String? currencyCode,
    String? currencySymbol,
    bool? isTaxEnabled,
    double? taxRate,
    bool? isDiscountEnabled,
    double? defaultDiscountRate,
    String? receiptFooterMessage,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      taxRate: taxRate ?? this.taxRate,
      isDiscountEnabled: isDiscountEnabled ?? this.isDiscountEnabled,
      defaultDiscountRate: defaultDiscountRate ?? this.defaultDiscountRate,
      receiptFooterMessage: receiptFooterMessage ?? this.receiptFooterMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialization to Map for SQLite storage or JSON backup.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'is_tax_enabled': isTaxEnabled ? 1 : 0,
      'tax_rate': taxRate,
      'is_discount_enabled': isDiscountEnabled ? 1 : 0,
      'default_discount_rate': defaultDiscountRate,
      'receipt_footer_message': receiptFooterMessage,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Deserialization from Map.
  factory BusinessProfile.fromMap(Map<String, dynamic> map) {
    return BusinessProfile(
      id: map['id'] as String? ?? 'default-profile-id',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      currencyCode: map['currency_code'] as String? ?? AppConstants.defaultCurrencyCode,
      currencySymbol: map['currency_symbol'] as String? ?? AppConstants.defaultCurrencySymbol,
      isTaxEnabled: (map['is_tax_enabled'] as int? ?? 0) == 1,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 11.0,
      isDiscountEnabled: (map['is_discount_enabled'] as int? ?? 0) == 1,
      defaultDiscountRate: (map['default_discount_rate'] as num?)?.toDouble() ?? 0.0,
      receiptFooterMessage: map['receipt_footer_message'] as String? ?? 'Terima kasih telah berbelanja!',
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          address == other.address &&
          phone == other.phone &&
          email == other.email &&
          currencyCode == other.currencyCode &&
          currencySymbol == other.currencySymbol &&
          isTaxEnabled == other.isTaxEnabled &&
          taxRate == other.taxRate &&
          isDiscountEnabled == other.isDiscountEnabled &&
          defaultDiscountRate == other.defaultDiscountRate &&
          receiptFooterMessage == other.receiptFooterMessage;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      address.hashCode ^
      phone.hashCode ^
      email.hashCode ^
      currencyCode.hashCode ^
      currencySymbol.hashCode ^
      isTaxEnabled.hashCode ^
      taxRate.hashCode ^
      isDiscountEnabled.hashCode ^
      defaultDiscountRate.hashCode ^
      receiptFooterMessage.hashCode;
}
