import 'package:flutter/material.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// Available payment method types in the POS application (Task T2.4).
enum PaymentMethodType {
  /// Cash payment with change calculation.
  cash(
    code: 'tunai',
    name: 'Tunai',
    label: 'Tunai (Cash)',
    description: 'Pembayaran uang tunai fisik & kalkulasi kembalian otomatis',
    icon: Icons.payments_rounded,
  ),

  /// Bank transfer payment with account info and reference number.
  transfer(
    code: 'transfer',
    name: 'Transfer',
    label: 'Transfer Bank',
    description: 'Transfer ke rekening bank usaha dengan bukti referensi',
    icon: Icons.account_balance_rounded,
  ),

  /// Digital QRIS payment standard (GoPay, OVO, Dana, ShopeePay, BCA, etc.).
  qris(
    code: 'qris',
    name: 'QRIS',
    label: 'QRIS Digital',
    description: 'Scan kode QRIS standar Bank Indonesia & e-Wallet',
    icon: Icons.qr_code_scanner_rounded,
  );

  const PaymentMethodType({
    required this.code,
    required this.name,
    required this.label,
    required this.description,
    required this.icon,
  });

  /// Unique lowercase code identifier.
  final String code;

  /// Short display name.
  final String name;

  /// Full descriptive label.
  final String label;

  /// Brief explanation of the payment method.
  final String description;

  /// Icon representing this payment method.
  final IconData icon;

  /// Whether this method is cash payment.
  bool get isCash => this == PaymentMethodType.cash;

  /// Whether this method is bank transfer.
  bool get isTransfer => this == PaymentMethodType.transfer;

  /// Whether this method is QRIS digital payment.
  bool get isQris => this == PaymentMethodType.qris;

  /// Parses from code string safely, falling back to [cash].
  static PaymentMethodType fromCode(String? code) {
    switch (code?.toLowerCase().trim()) {
      case 'transfer':
      case 'bank_transfer':
        return PaymentMethodType.transfer;
      case 'qris':
        return PaymentMethodType.qris;
      case 'tunai':
      case 'cash':
      default:
        return PaymentMethodType.cash;
    }
  }
}

/// Helper to generate intuitive quick cash nominal suggestions for cashiers (Task T2.4).
class QuickCashHelper {
  QuickCashHelper._();

  /// Generates clean ascending cash suggestion amounts in integer Rupiah
  /// based on standard Indonesian currency denominations.
  static List<int> generateSuggestions(int totalAmount) {
    if (totalAmount <= 0) {
      return const [10000, 20000, 50000, 100000];
    }

    final suggestions = <int>{};

    // 1. Uang Pas (Exact Amount) is always the first suggestion
    suggestions.add(totalAmount);

    // 2. Standard Indonesian paper banknote denominations
    const denominations = [
      1000,
      2000,
      5000,
      10000,
      20000,
      50000,
      100000,
      200000,
      500000,
    ];

    // Find the next round denominations directly above totalAmount
    for (final denom in denominations) {
      if (denom > totalAmount) {
        suggestions.add(denom);
      } else {
        // Round up to nearest multiple of this denomination
        final rounded = ((totalAmount + denom - 1) ~/ denom) * denom;
        if (rounded > totalAmount) {
          suggestions.add(rounded);
        }
      }
    }

    final sorted = suggestions.toList()..sort();
    // Return at most 5 practical ascending suggestions
    return sorted.take(5).toList();
  }
}

/// Immutable record of a processed or selected payment detail (Task T2.4).
class PaymentResult {
  PaymentResult({
    String? id,
    required this.method,
    required this.totalPayable,
    required this.amountPaid,
    int? changeAmount,
    this.bankName,
    this.referenceNumber,
    this.note,
    DateTime? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        changeAmount = changeAmount ??
            (amountPaid > totalPayable ? amountPaid - totalPayable : 0),
        timestamp = timestamp ?? DateTime.now();

  /// Unique identifier for this payment record.
  final String id;

  /// Selected payment method.
  final PaymentMethodType method;

  /// Total bill amount payable in integer Rupiah.
  final int totalPayable;

  /// Actual nominal amount received / paid by the customer in integer Rupiah.
  final int amountPaid;

  /// Change to return to customer (calculated automatically if not supplied).
  final int changeAmount;

  /// Selected bank destination (only applicable for [PaymentMethodType.transfer]).
  final String? bankName;

  /// Transaction reference number, transfer proof note, or QRIS RRN.
  final String? referenceNumber;

  /// Additional notes for payment audit.
  final String? note;

  /// Timestamp when the payment selection/confirmation was made.
  final DateTime timestamp;

  /// Whether the paid amount is sufficient to cover the total payable amount.
  bool get isSufficient => amountPaid >= totalPayable;

  /// Whether the customer paid with exact amount (no change needed).
  bool get isExactAmount => amountPaid == totalPayable;

  /// Amount lacking if payment is insufficient in Rupiah.
  int get shortageAmount => isSufficient ? 0 : totalPayable - amountPaid;

  /// Formatted total payable currency string (e.g. 'Rp75.000').
  String get formattedTotalPayable =>
      CurrencyFormatter.formatRupiah(totalPayable);

  /// Formatted amount paid currency string (e.g. 'Rp100.000').
  String get formattedAmountPaid => CurrencyFormatter.formatRupiah(amountPaid);

  /// Formatted change amount currency string (e.g. 'Rp25.000').
  String get formattedChangeAmount =>
      CurrencyFormatter.formatRupiah(changeAmount);

  /// Formatted shortage amount currency string.
  String get formattedShortageAmount =>
      CurrencyFormatter.formatRupiah(shortageAmount);

  /// Creates a copy with specified fields replaced.
  PaymentResult copyWith({
    String? id,
    PaymentMethodType? method,
    int? totalPayable,
    int? amountPaid,
    int? changeAmount,
    String? bankName,
    String? referenceNumber,
    String? note,
    DateTime? timestamp,
  }) {
    return PaymentResult(
      id: id ?? this.id,
      method: method ?? this.method,
      totalPayable: totalPayable ?? this.totalPayable,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
      bankName: bankName ?? this.bankName,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts this record to a Map for database persistence or backup.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method.code,
      'totalPayable': totalPayable,
      'amountPaid': amountPaid,
      'changeAmount': changeAmount,
      'bankName': bankName,
      'referenceNumber': referenceNumber,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Recreates a [PaymentResult] instance from a Map.
  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      id: map['id'] as String?,
      method: PaymentMethodType.fromCode(map['method'] as String?),
      totalPayable: (map['totalPayable'] as num?)?.toInt() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toInt() ?? 0,
      changeAmount: (map['changeAmount'] as num?)?.toInt(),
      bankName: map['bankName'] as String?,
      referenceNumber: map['referenceNumber'] as String?,
      note: map['note'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          method == other.method &&
          totalPayable == other.totalPayable &&
          amountPaid == other.amountPaid &&
          changeAmount == other.changeAmount &&
          bankName == other.bankName &&
          referenceNumber == other.referenceNumber &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
        id,
        method,
        totalPayable,
        amountPaid,
        changeAmount,
        bankName,
        referenceNumber,
        note,
      );
}

