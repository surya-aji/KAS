import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/domain/models/discount_type.dart';
import 'package:kas_usaha/features/pos/domain/models/pos_calculation.dart';

/// Pure domain service calculating real-time financial totals, discounts, and taxes for a POS order.
///
/// Follows Clean Architecture and strict offline-first integer arithmetic in Indonesian Rupiah
/// as specified in section 4.2 of IMPLEMENTATION_PLAN.md.
class TransactionCalculator {
  const TransactionCalculator._();

  /// Calculates real-time breakdown of a POS transaction.
  ///
  /// Guarantees integer arithmetic for all currency outputs (no float rounding bugs).
  static PosCalculation calculate({
    required List<CartItem> cartItems,
    DiscountType transactionDiscountType = DiscountType.percentage,
    double transactionDiscountValue = 0.0,
    bool isTaxEnabled = false,
    double taxRate = 11.0,
  }) {
    if (cartItems.isEmpty) {
      return PosCalculation(
        isTaxEnabled: isTaxEnabled,
        taxRate: taxRate,
        transactionDiscountType: transactionDiscountType,
        transactionDiscountValue: transactionDiscountValue,
      );
    }

    int totalQuantity = 0;
    int grossSubtotal = 0;
    int totalItemDiscounts = 0;

    for (final item in cartItems) {
      totalQuantity += item.quantity;
      grossSubtotal += item.grossSubtotal;
      totalItemDiscounts += item.discountAmount;
    }

    // Subtotal after item-level discounts
    final subtotalAfterItemDiscounts =
        (grossSubtotal - totalItemDiscounts).clamp(0, grossSubtotal);

    // Calculate transaction-level discount
    int transactionDiscountAmount = 0;
    if (transactionDiscountValue > 0 && subtotalAfterItemDiscounts > 0) {
      if (transactionDiscountType == DiscountType.percentage) {
        final clampedRate = transactionDiscountValue.clamp(0.0, 100.0);
        transactionDiscountAmount =
            ((subtotalAfterItemDiscounts * clampedRate) / 100.0).round();
      } else {
        transactionDiscountAmount = transactionDiscountValue
            .round()
            .clamp(0, subtotalAfterItemDiscounts);
      }
    }

    final totalDiscounts = totalItemDiscounts + transactionDiscountAmount;

    // Taxable base amount / DPP (Dasar Pengenaan Pajak)
    final taxableAmount =
        (subtotalAfterItemDiscounts - transactionDiscountAmount)
            .clamp(0, subtotalAfterItemDiscounts);

    // Calculate tax (PPN)
    int taxAmount = 0;
    if (isTaxEnabled && taxRate > 0 && taxableAmount > 0) {
      final clampedTaxRate = taxRate.clamp(0.0, 100.0);
      taxAmount = ((taxableAmount * clampedTaxRate) / 100.0).round();
    }

    // Grand total
    final grandTotal = taxableAmount + taxAmount;

    return PosCalculation(
      totalQuantity: totalQuantity,
      grossSubtotal: grossSubtotal,
      itemDiscounts: totalItemDiscounts,
      subtotalAfterItemDiscounts: subtotalAfterItemDiscounts,
      transactionDiscountType: transactionDiscountType,
      transactionDiscountValue: transactionDiscountValue,
      transactionDiscountAmount: transactionDiscountAmount,
      totalDiscounts: totalDiscounts,
      taxableAmount: taxableAmount,
      isTaxEnabled: isTaxEnabled,
      taxRate: taxRate,
      taxAmount: taxAmount,
      grandTotal: grandTotal,
    );
  }
}
