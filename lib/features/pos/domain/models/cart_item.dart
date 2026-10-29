import 'package:flutter/foundation.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/pos/domain/models/discount_type.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// Domain model representing an item in the POS cashier order / cart.
///
/// Supports real-time financial calculations (Task T2.3) including item-level
/// discounts (percentage or fixed nominal) with integer arithmetic in Rupiah.
@immutable
class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
    this.notes = '',
    this.discountType = DiscountType.percentage,
    this.discountValue = 0.0,
  });

  /// The associated catalog product snapshot.
  final Product product;

  /// Ordered quantity (integer, at least 1).
  final int quantity;

  /// Optional specific notes or customer requests (e.g. "Tanpa gula", "Bungkus").
  final String notes;

  /// Unit type of item-level discount (percentage or fixed nominal).
  final DiscountType discountType;

  /// Item-level discount input value (e.g. 10.0 for 10% or 5000 for Rp5.000).
  final double discountValue;

  /// Gross subtotal price before item discount in integer Rupiah.
  int get grossSubtotal => product.sellingPrice * quantity;

  /// Effective discount amount for this line item in integer Rupiah.
  ///
  /// Guarantees integer arithmetic and clamps discount between 0 and [grossSubtotal].
  int get discountAmount {
    if (discountValue <= 0) return 0;

    if (discountType == DiscountType.percentage) {
      final clampedPercent = discountValue.clamp(0.0, 100.0);
      return ((grossSubtotal * clampedPercent) / 100.0).round();
    } else {
      return discountValue.round().clamp(0, grossSubtotal);
    }
  }

  /// Net subtotal price after item discount in integer Rupiah.
  ///
  /// Preserves backward-compatibility with callers referencing [subtotal].
  int get subtotal => (grossSubtotal - discountAmount).clamp(0, grossSubtotal);

  /// Explicit alias for net subtotal.
  int get netSubtotal => subtotal;

  /// Formatted gross subtotal string (e.g. 'Rp50.000').
  String get formattedGrossSubtotal =>
      CurrencyFormatter.formatRupiah(grossSubtotal);

  /// Formatted discount amount string (e.g. 'Rp5.000').
  String get formattedDiscountAmount =>
      CurrencyFormatter.formatRupiah(discountAmount);

  /// Formatted net subtotal string (e.g. 'Rp45.000').
  String get formattedSubtotal => CurrencyFormatter.formatRupiah(subtotal);

  /// Whether this item has an active discount applied.
  bool get hasDiscount => discountAmount > 0;

  /// Human-friendly discount description label (e.g. "Diskon 10%" or "Diskon Rp5.000").
  String get discountDescription {
    if (!hasDiscount) return '';
    if (discountType == DiscountType.percentage) {
      final formattedRate = discountValue % 1 == 0
          ? discountValue.toInt().toString()
          : discountValue.toStringAsFixed(1);
      return 'Diskon $formattedRate%';
    } else {
      return 'Diskon ${CurrencyFormatter.formatRupiah(discountAmount)}';
    }
  }

  /// Whether this item has custom notes or special requests.
  bool get hasNotes => notes.trim().isNotEmpty;

  /// Creates a copy of this cart item with updated fields.
  CartItem copyWith({
    Product? product,
    int? quantity,
    String? notes,
    DiscountType? discountType,
    double? discountValue,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity &&
          notes == other.notes &&
          discountType == other.discountType &&
          discountValue == other.discountValue;

  @override
  int get hashCode =>
      product.hashCode ^
      quantity.hashCode ^
      notes.hashCode ^
      discountType.hashCode ^
      discountValue.hashCode;
}
