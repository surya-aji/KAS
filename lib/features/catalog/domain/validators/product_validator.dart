import 'package:flutter/foundation.dart';

/// Stock warning and availability status evaluated from stock counts.
enum ProductStockLevel {
  /// Stock tracking is disabled for this product (e.g. services, digital items).
  notTracked,

  /// Stock is above minimum threshold and safely available.
  inStock,

  /// Stock is non-zero but at or below the minimum warning threshold.
  lowStock,

  /// Stock is completely depleted (zero or below).
  outOfStock,
}

/// Domain validator for product pricing, inventory stock, and validation business rules.
///
/// Complies with the offline-first single-device architecture specifications:
/// - Monetary amounts stored strictly as integer rupiah (no floating-point).
/// - Stock quantities are non-negative integers when stock tracking is active.
/// - Minimum stock provides proactive low-stock warnings for offline merchants.
@immutable
class ProductValidator {
  const ProductValidator._();

  /// Maximum realistic price in Indonesian Rupiah (Rp 1.000.000.000 / 1 Miliar).
  /// Prevents accidental overflows and absurd values.
  static const int maxPrice = 1000000000;

  /// Maximum allowable stock count (999.999 units).
  static const int maxStock = 999999;

  /// Validates selling price (Harga Jual).
  ///
  /// Selling price is mandatory, must be strictly greater than 0,
  /// and cannot exceed [maxPrice].
  static String? validateSellingPrice(int? price, {String? rawText}) {
    if (rawText != null && rawText.trim().isEmpty) {
      return 'Harga jual wajib diisi';
    }
    if (price == null || price <= 0) {
      return 'Harga jual harus lebih besar dari Rp 0';
    }
    if (price > maxPrice) {
      return 'Harga jual maksimal Rp 1.000.000.000';
    }
    return null;
  }

  /// Validates cost price (Harga Modal / HPP).
  ///
  /// Cost price is optional. If provided, it cannot be negative
  /// and cannot exceed [maxPrice].
  static String? validateCostPrice(int? price, {String? rawText}) {
    if (price == null || (rawText != null && rawText.trim().isEmpty)) {
      return null;
    }
    if (price < 0) {
      return 'Harga modal tidak boleh kurang dari Rp 0';
    }
    if (price > maxPrice) {
      return 'Harga modal maksimal Rp 1.000.000.000';
    }
    return null;
  }

  /// Validates current inventory stock (Jumlah Stok Saat Ini).
  ///
  /// When [trackStock] is enabled:
  /// - Field is mandatory
  /// - Must be a valid non-negative integer
  /// - Cannot exceed [maxStock]
  static String? validateStock(String? value, {required bool trackStock}) {
    if (!trackStock) return null;

    if (value == null || value.trim().isEmpty) {
      return 'Jumlah stok wajib diisi';
    }

    final trimmed = value.trim();
    final parsed = int.tryParse(trimmed);

    if (parsed == null) {
      return 'Jumlah stok harus berupa angka bulat';
    }

    if (parsed < 0) {
      return 'Jumlah stok tidak boleh kurang dari 0';
    }

    if (parsed > maxStock) {
      return 'Jumlah stok maksimal 999.999';
    }

    return null;
  }

  /// Validates minimum stock alert threshold (Batas Minimum Stok).
  ///
  /// When [trackStock] is enabled:
  /// - Field is mandatory
  /// - Must be a valid non-negative integer
  /// - Cannot exceed [maxStock]
  static String? validateMinStock(String? value, {required bool trackStock}) {
    if (!trackStock) return null;

    if (value == null || value.trim().isEmpty) {
      return 'Batas stok minimum wajib diisi';
    }

    final trimmed = value.trim();
    final parsed = int.tryParse(trimmed);

    if (parsed == null) {
      return 'Batas stok minimum harus berupa angka bulat';
    }

    if (parsed < 0) {
      return 'Batas stok minimum tidak boleh kurang dari 0';
    }

    if (parsed > maxStock) {
      return 'Batas stok minimum maksimal 999.999';
    }

    return null;
  }

  /// Determines whether the cost price exceeds selling price, creating a potential operating loss.
  static bool isPotentialLoss(int sellingPrice, int costPrice) {
    return sellingPrice > 0 && costPrice > 0 && costPrice > sellingPrice;
  }

  /// Evaluates real-time inventory stock level for UI feedback.
  static ProductStockLevel evaluateStockStatus({
    required bool trackStock,
    required int stock,
    required int minStock,
  }) {
    if (!trackStock) return ProductStockLevel.notTracked;
    if (stock <= 0) return ProductStockLevel.outOfStock;
    if (stock <= minStock) return ProductStockLevel.lowStock;
    return ProductStockLevel.inStock;
  }
}
