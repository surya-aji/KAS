/// Represents the unit type of a discount: percentage (%) or fixed nominal in Indonesian Rupiah (Rp).
enum DiscountType {
  /// Percentage-based discount (e.g. 10.0 for 10%).
  percentage,

  /// Fixed nominal Rupiah discount (e.g. 5000 for Rp5.000).
  fixed;

  /// Whether this discount type is percentage.
  bool get isPercentage => this == DiscountType.percentage;

  /// Whether this discount type is fixed nominal Rupiah.
  bool get isFixed => this == DiscountType.fixed;

  /// Visual symbol ('%' or 'Rp').
  String get symbol => isPercentage ? '%' : 'Rp';

  /// Human-readable label for UI selection.
  String get label => isPercentage ? 'Persentase (%)' : 'Nominal (Rp)';
}
