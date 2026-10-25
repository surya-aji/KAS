// Currency and number formatting utilities.
//
// Uses integer-based rupiah values (no floating-point)
// as specified in the implementation plan (section 4.2).

import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final _rupiahFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Formats an integer amount (in rupiah) to display string.
  ///
  /// Example: `1500000` → `Rp1.500.000`
  static String formatRupiah(int amount) {
    return _rupiahFormat.format(amount);
  }

  /// Formats a number with thousands separator.
  ///
  /// Example: `1500000` → `1.500.000`
  static String formatNumber(int value) {
    return NumberFormat('#,###', 'id_ID').format(value);
  }
}
