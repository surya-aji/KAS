import 'package:flutter/foundation.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// Domain model representing an item in the POS cashier order / cart.
///
/// Prepares for Task T2.2 (interactive cart) and T2.3 (calculations)
/// while adhering to Clean Architecture and offline-first principles.
@immutable
class CartItem {
  const CartItem({
    required this.product,
    this.quantity = 1,
    this.notes = '',
  });

  /// The associated catalog product snapshot.
  final Product product;

  /// Ordered quantity (integer, at least 1).
  final int quantity;

  /// Optional specific notes or customer requests (e.g. "Tanpa gula", "Bungkus").
  final String notes;

  /// Subtotal price in integer Rupiah for this line item.
  int get subtotal => product.sellingPrice * quantity;

  /// Formatted subtotal string (e.g. 'Rp50.000').
  String get formattedSubtotal => CurrencyFormatter.formatRupiah(subtotal);

  /// Creates a copy of this cart item with updated fields.
  CartItem copyWith({
    Product? product,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity &&
          notes == other.notes;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode ^ notes.hashCode;
}
