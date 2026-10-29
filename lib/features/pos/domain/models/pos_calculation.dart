import 'package:flutter/foundation.dart';
import 'package:kas_usaha/features/pos/domain/models/discount_type.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// Immutable domain model encapsulating real-time financial calculations of a POS transaction.
///
/// Follows Clean Architecture and strict offline-first integer arithmetic in Indonesian Rupiah
/// to eliminate any floating-point accumulation or rounding discrepancy (Task T2.3).
@immutable
class PosCalculation {
  const PosCalculation({
    this.totalQuantity = 0,
    this.grossSubtotal = 0,
    this.itemDiscounts = 0,
    this.subtotalAfterItemDiscounts = 0,
    this.transactionDiscountType = DiscountType.percentage,
    this.transactionDiscountValue = 0.0,
    this.transactionDiscountAmount = 0,
    this.totalDiscounts = 0,
    this.taxableAmount = 0,
    this.isTaxEnabled = false,
    this.taxRate = 11.0,
    this.taxAmount = 0,
    this.grandTotal = 0,
  });

  /// Total count of physical item units in the cart.
  final int totalQuantity;

  /// Total gross sum of item selling price × quantity (Subtotal Kotor) in integer Rupiah.
  final int grossSubtotal;

  /// Total sum of all individual item discounts (Total Diskon Item) in integer Rupiah.
  final int itemDiscounts;

  /// Subtotal after item-level discounts: `grossSubtotal - itemDiscounts` in integer Rupiah.
  final int subtotalAfterItemDiscounts;

  /// Discount unit type for transaction/order-level discount (% or fixed Rp).
  final DiscountType transactionDiscountType;

  /// Transaction-level discount input value (e.g. 10.0 for 10% or 20000 for Rp20.000).
  final double transactionDiscountValue;

  /// Actual computed integer Rupiah discount for transaction (Diskon Transaksi/Nota).
  final int transactionDiscountAmount;

  /// Combined total discounts: `itemDiscounts + transactionDiscountAmount` in integer Rupiah.
  final int totalDiscounts;

  /// Net taxable base amount / DPP (Dasar Pengenaan Pajak) in integer Rupiah.
  final int taxableAmount;

  /// Whether tax (PPN) is enabled and applied to this transaction.
  final bool isTaxEnabled;

  /// Tax rate percentage (e.g. 11.0 for PPN 11%).
  final double taxRate;

  /// Actual computed integer Rupiah tax amount (Nilai Pajak/PPN).
  final int taxAmount;

  /// Final payable amount in integer Rupiah (Grand Total / Total Tagihan).
  final int grandTotal;

  // Convenient boolean indicators
  /// Whether at least one line item has a discount applied.
  bool get hasItemDiscounts => itemDiscounts > 0;

  /// Whether a transaction-level discount is active.
  bool get hasTransactionDiscount => transactionDiscountAmount > 0;

  /// Whether any discount (item or transaction) is applied.
  bool get hasAnyDiscount => totalDiscounts > 0;

  /// Whether tax is active and results in a non-zero amount.
  bool get hasTax => isTaxEnabled && taxAmount > 0;

  // Formatted string getters in Indonesian Rupiah
  String get formattedGrossSubtotal =>
      CurrencyFormatter.formatRupiah(grossSubtotal);
  String get formattedItemDiscounts =>
      CurrencyFormatter.formatRupiah(itemDiscounts);
  String get formattedSubtotalAfterItemDiscounts =>
      CurrencyFormatter.formatRupiah(subtotalAfterItemDiscounts);
  String get formattedTransactionDiscountAmount =>
      CurrencyFormatter.formatRupiah(transactionDiscountAmount);
  String get formattedTotalDiscounts =>
      CurrencyFormatter.formatRupiah(totalDiscounts);
  String get formattedTaxableAmount =>
      CurrencyFormatter.formatRupiah(taxableAmount);
  String get formattedTaxAmount => CurrencyFormatter.formatRupiah(taxAmount);
  String get formattedGrandTotal => CurrencyFormatter.formatRupiah(grandTotal);

  /// Human-readable label for transaction discount (e.g. "Diskon Transaksi (10%)").
  String get transactionDiscountLabel {
    if (transactionDiscountType == DiscountType.percentage) {
      final formattedRate = transactionDiscountValue % 1 == 0
          ? transactionDiscountValue.toInt().toString()
          : transactionDiscountValue.toStringAsFixed(1);
      return 'Diskon Transaksi ($formattedRate%)';
    }
    return 'Diskon Transaksi';
  }

  /// Human-readable label for tax (e.g. "Pajak / PPN (11%)").
  String get taxLabel {
    final formattedRate = taxRate % 1 == 0
        ? taxRate.toInt().toString()
        : taxRate.toStringAsFixed(1);
    return 'Pajak / PPN ($formattedRate%)';
  }

  /// Default empty calculation.
  factory PosCalculation.zero() => const PosCalculation();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosCalculation &&
          runtimeType == other.runtimeType &&
          totalQuantity == other.totalQuantity &&
          grossSubtotal == other.grossSubtotal &&
          itemDiscounts == other.itemDiscounts &&
          subtotalAfterItemDiscounts == other.subtotalAfterItemDiscounts &&
          transactionDiscountType == other.transactionDiscountType &&
          transactionDiscountValue == other.transactionDiscountValue &&
          transactionDiscountAmount == other.transactionDiscountAmount &&
          totalDiscounts == other.totalDiscounts &&
          taxableAmount == other.taxableAmount &&
          isTaxEnabled == other.isTaxEnabled &&
          taxRate == other.taxRate &&
          taxAmount == other.taxAmount &&
          grandTotal == other.grandTotal;

  @override
  int get hashCode =>
      totalQuantity.hashCode ^
      grossSubtotal.hashCode ^
      itemDiscounts.hashCode ^
      subtotalAfterItemDiscounts.hashCode ^
      transactionDiscountType.hashCode ^
      transactionDiscountValue.hashCode ^
      transactionDiscountAmount.hashCode ^
      totalDiscounts.hashCode ^
      taxableAmount.hashCode ^
      isTaxEnabled.hashCode ^
      taxRate.hashCode ^
      taxAmount.hashCode ^
      grandTotal.hashCode;
}
