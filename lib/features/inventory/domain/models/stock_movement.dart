import 'package:flutter/material.dart';
import 'package:kas_usaha/shared/formatters/date_time_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';

/// Semantic classification of inventory stock changes.
///
/// Follows SQLite `stock_movements` table specification in section 4.1
/// and business consistency rules in section 6.2 of IMPLEMENTATION_PLAN.md.
enum StockMovementType {
  /// Stock reduction caused by POS sale transaction.
  sale,

  /// Stock addition from supplier purchase / restock.
  restock,

  /// Stock addition from physical audit / stock opname correction.
  adjustmentIn,

  /// Stock deduction from physical audit / stock opname correction.
  adjustmentOut,

  /// Stock deduction due to damaged goods, spoilage, or expiration.
  damaged,

  /// Stock addition restored from voided / returned transaction.
  returned;

  /// User-friendly Indonesian title for UI presentation.
  String get displayName {
    switch (this) {
      case StockMovementType.sale:
        return 'Penjualan';
      case StockMovementType.restock:
        return 'Restok Masuk';
      case StockMovementType.adjustmentIn:
        return 'Koreksi Tambah';
      case StockMovementType.adjustmentOut:
        return 'Koreksi Kurang';
      case StockMovementType.damaged:
        return 'Barang Rusak / Expired';
      case StockMovementType.returned:
        return 'Retur Penjualan';
    }
  }

  /// Whether this movement increases physical inventory.
  bool get isPositive {
    switch (this) {
      case StockMovementType.restock:
      case StockMovementType.adjustmentIn:
      case StockMovementType.returned:
        return true;
      case StockMovementType.sale:
      case StockMovementType.adjustmentOut:
      case StockMovementType.damaged:
        return false;
    }
  }

  /// Associated icon for visual log identification.
  IconData get icon {
    switch (this) {
      case StockMovementType.sale:
        return Icons.shopping_bag_outlined;
      case StockMovementType.restock:
        return Icons.add_business_rounded;
      case StockMovementType.adjustmentIn:
        return Icons.trending_up_rounded;
      case StockMovementType.adjustmentOut:
        return Icons.trending_down_rounded;
      case StockMovementType.damaged:
        return Icons.remove_circle_outline_rounded;
      case StockMovementType.returned:
        return Icons.assignment_return_rounded;
    }
  }

  /// Visual badge style variant.
  AppBadgeVariant get badgeVariant {
    switch (this) {
      case StockMovementType.sale:
        return AppBadgeVariant.info;
      case StockMovementType.restock:
      case StockMovementType.adjustmentIn:
        return AppBadgeVariant.success;
      case StockMovementType.adjustmentOut:
        return AppBadgeVariant.warning;
      case StockMovementType.damaged:
        return AppBadgeVariant.error;
      case StockMovementType.returned:
        return AppBadgeVariant.info;
    }
  }

  /// String value used in SQLite persistence and backup JSON serialization.
  String toStringValue() {
    switch (this) {
      case StockMovementType.sale:
        return 'sale';
      case StockMovementType.restock:
        return 'restock';
      case StockMovementType.adjustmentIn:
        return 'adjustment_in';
      case StockMovementType.adjustmentOut:
        return 'adjustment_out';
      case StockMovementType.damaged:
        return 'damaged';
      case StockMovementType.returned:
        return 'returned';
    }
  }

  /// Parses string value into [StockMovementType].
  static StockMovementType fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'restock':
      case 'in':
        return StockMovementType.restock;
      case 'adjustment_in':
      case 'adj_in':
        return StockMovementType.adjustmentIn;
      case 'adjustment_out':
      case 'adj_out':
        return StockMovementType.adjustmentOut;
      case 'damaged':
      case 'waste':
      case 'expired':
        return StockMovementType.damaged;
      case 'returned':
      case 'return':
      case 'void':
        return StockMovementType.returned;
      case 'sale':
      default:
        return StockMovementType.sale;
    }
  }
}

/// Domain model representing a single inventory stock movement record.
///
/// Maps directly to SQLite `stock_movements` table as defined in sections 4.1
/// and 6.2 of IMPLEMENTATION_PLAN.md.
@immutable
class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    this.productSku = '',
    this.unit = 'pcs',
    required this.type,
    required this.quantity,
    required this.previousStock,
    required this.currentStock,
    this.referenceNumber = '',
    this.notes = '',
    required this.createdAt,
  });

  /// Unique record identifier (UUID).
  final String id;

  /// Foreign key referencing the affected Product ID.
  final String productId;

  /// Snapshot of the product name at the time of movement.
  final String productName;

  /// Snapshot of the product SKU.
  final String productSku;

  /// Unit of measurement (e.g. 'pcs', 'porsi', 'cup').
  final String unit;

  /// Movement type (sale, restock, adjustment, etc.).
  final StockMovementType type;

  /// Magnitude of inventory change (always positive integer).
  final int quantity;

  /// Snapshot of inventory count before this movement.
  final int previousStock;

  /// Snapshot of inventory count after this movement.
  final int currentStock;

  /// Reference code (e.g. Transaction ID, PO number, or Adjustment Code).
  final String referenceNumber;

  /// Reason, explanation, or audit notes for this movement.
  final String notes;

  /// Timestamp when the movement occurred (stored in UTC).
  final DateTime createdAt;

  /// Signed quantity change: positive for incoming, negative for outgoing.
  int get signedQuantity => type.isPositive ? quantity : -quantity;

  /// User-friendly formatted quantity with sign and unit (e.g. '+20 porsi', '-5 cup').
  String get formattedQuantity {
    final prefix = type.isPositive ? '+' : '-';
    return '$prefix$quantity $unit';
  }

  /// Formatted stock transition (e.g. '15 → 35 porsi').
  String get formattedStockTransition {
    return '$previousStock → $currentStock $unit';
  }

  /// Local date-time display string (e.g. '29/10/2026 12:30').
  String get formattedDate => DateTimeFormatter.formatDateTime(createdAt);

  /// Full localized date-time display string (e.g. '29 Oktober 2026, 12:30').
  String get formattedFullDate => DateTimeFormatter.formatFullDateTime(createdAt);

  /// Creates a copy of this stock movement with modified fields.
  StockMovement copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productSku,
    String? unit,
    StockMovementType? type,
    int? quantity,
    int? previousStock,
    int? currentStock,
    String? referenceNumber,
    String? notes,
    DateTime? createdAt,
  }) {
    return StockMovement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productSku: productSku ?? this.productSku,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      previousStock: previousStock ?? this.previousStock,
      currentStock: currentStock ?? this.currentStock,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts model to Map for SQLite database or JSON export.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_sku': productSku,
      'unit': unit,
      'type': type.toStringValue(),
      'quantity': quantity,
      'previous_stock': previousStock,
      'current_stock': currentStock,
      'reference_number': referenceNumber,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor creating a [StockMovement] from Map.
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as String,
      productId: map['product_id'] as String? ?? '',
      productName: map['product_name'] as String? ?? '',
      productSku: map['product_sku'] as String? ?? '',
      unit: map['unit'] as String? ?? 'pcs',
      type: StockMovementType.fromString(map['type'] as String? ?? 'sale'),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (map['previous_stock'] as num?)?.toInt() ?? 0,
      currentStock: (map['current_stock'] as num?)?.toInt() ?? 0,
      referenceNumber: map['reference_number'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Realistic dummy stock history records matching initial catalog products.
  static List<StockMovement> initialMovements() {
    final now = DateTime.now();

    return [
      // 1. Nasi Goreng Spesial (prd-01) - Sale today
      StockMovement(
        id: 'mov-001',
        productId: 'prd-01',
        productName: 'Nasi Goreng Spesial',
        productSku: 'MKN-001',
        unit: 'porsi',
        type: StockMovementType.sale,
        quantity: 5,
        previousStock: 40,
        currentStock: 35,
        referenceNumber: 'TRX-20261029-003',
        notes: 'Penjualan kasir shift makan siang (Meja 4 & Takeaway)',
        createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
      ),

      // 2. Kopi Susu Gula Aren (prd-03) - Sale today
      StockMovement(
        id: 'mov-002',
        productId: 'prd-03',
        productName: 'Kopi Susu Gula Aren',
        productSku: 'MNM-001',
        unit: 'cup',
        type: StockMovementType.sale,
        quantity: 10,
        previousStock: 60,
        currentStock: 50,
        referenceNumber: 'TRX-20261029-002',
        notes: 'Pesanan take-away rombongan kantor',
        createdAt: now.subtract(const Duration(hours: 3, minutes: 5)),
      ),

      // 3. Mie Goreng Seafood (prd-02) - Damaged goods today
      StockMovement(
        id: 'mov-003',
        productId: 'prd-02',
        productName: 'Mie Goreng Seafood',
        productSku: 'MKN-002',
        unit: 'porsi',
        type: StockMovementType.damaged,
        quantity: 2,
        previousStock: 6,
        currentStock: 4,
        referenceNumber: 'ADJ-20261029-01',
        notes: 'Bahan udang & seafood rusak/tidak segar saat dicek pagi',
        createdAt: now.subtract(const Duration(hours: 5, minutes: 10)),
      ),

      // 4. Es Teh Manis Jumbo (prd-04) - Stock opname adjustment today
      StockMovement(
        id: 'mov-004',
        productId: 'prd-04',
        productName: 'Es Teh Manis Jumbo',
        productSku: 'MNM-002',
        unit: 'cup',
        type: StockMovementType.adjustmentOut,
        quantity: 5,
        previousStock: 5,
        currentStock: 0,
        referenceNumber: 'ADJ-20261029-02',
        notes: 'Koreksi stok opname harian - wadah sirup teh tumpah',
        createdAt: now.subtract(const Duration(hours: 6, minutes: 45)),
      ),

      // 5. Nasi Goreng Spesial (prd-01) - Restock yesterday
      StockMovement(
        id: 'mov-005',
        productId: 'prd-01',
        productName: 'Nasi Goreng Spesial',
        productSku: 'MKN-001',
        unit: 'porsi',
        type: StockMovementType.restock,
        quantity: 20,
        previousStock: 20,
        currentStock: 40,
        referenceNumber: 'PO-20261028-01',
        notes: 'Penerimaan bahan beras dan telur dari Toko Sumber Rejeki',
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),

      // 6. Es Teh Manis Jumbo (prd-04) - Big Sale yesterday
      StockMovement(
        id: 'mov-006',
        productId: 'prd-04',
        productName: 'Es Teh Manis Jumbo',
        productSku: 'MNM-002',
        unit: 'cup',
        type: StockMovementType.sale,
        quantity: 15,
        previousStock: 20,
        currentStock: 5,
        referenceNumber: 'TRX-20261028-024',
        notes: 'Penjualan ramai minuman sore hari',
        createdAt: now.subtract(const Duration(days: 1, hours: 4, minutes: 30)),
      ),

      // 7. Paket Kenyang (prd-06) - Customer return / voided yesterday
      StockMovement(
        id: 'mov-007',
        productId: 'prd-06',
        productName: 'Paket Kenyang (Nasi + Es Teh)',
        productSku: 'PKT-001',
        unit: 'paket',
        type: StockMovementType.returned,
        quantity: 2,
        previousStock: 18,
        currentStock: 20,
        referenceNumber: 'RET-20261028-01',
        notes: 'Pembatalan transaksi kasir #TRX-20261028-015 oleh pelanggan',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
      ),

      // 8. Kopi Susu Gula Aren (prd-03) - Restock 2 days ago
      StockMovement(
        id: 'mov-008',
        productId: 'prd-03',
        productName: 'Kopi Susu Gula Aren',
        productSku: 'MNM-001',
        unit: 'cup',
        type: StockMovementType.restock,
        quantity: 40,
        previousStock: 20,
        currentStock: 60,
        referenceNumber: 'PO-20261027-02',
        notes: 'Restok biji kopi arabika & susu UHT segar dari Supplier Kopi',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),

      // 9. Kentang Goreng Keju (prd-05) - Restock 2 days ago
      StockMovement(
        id: 'mov-009',
        productId: 'prd-05',
        productName: 'Kentang Goreng Keju',
        productSku: 'SNK-001',
        unit: 'porsi',
        type: StockMovementType.restock,
        quantity: 15,
        previousStock: 10,
        currentStock: 25,
        referenceNumber: 'PO-20261027-03',
        notes: 'Penerimaan kentang beku impor dan bubuk keju',
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
      ),

      // 10. Mie Goreng Seafood (prd-02) - Sale 3 days ago
      StockMovement(
        id: 'mov-010',
        productId: 'prd-02',
        productName: 'Mie Goreng Seafood',
        productSku: 'MKN-002',
        unit: 'porsi',
        type: StockMovementType.sale,
        quantity: 4,
        previousStock: 10,
        currentStock: 6,
        referenceNumber: 'TRX-20261026-012',
        notes: 'Penjualan santap di tempat jam makan malam',
        createdAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),

      // 11. Paket Kenyang (prd-06) - Sale 3 days ago
      StockMovement(
        id: 'mov-011',
        productId: 'prd-06',
        productName: 'Paket Kenyang (Nasi + Es Teh)',
        productSku: 'PKT-001',
        unit: 'paket',
        type: StockMovementType.sale,
        quantity: 6,
        previousStock: 24,
        currentStock: 18,
        referenceNumber: 'TRX-20261026-008',
        notes: 'Pesanan promo makan hemat pelanggan',
        createdAt: now.subtract(const Duration(days: 3, hours: 4)),
      ),

      // 12. Nasi Goreng Spesial (prd-01) - Stock audit adjustment 5 days ago
      StockMovement(
        id: 'mov-012',
        productId: 'prd-01',
        productName: 'Nasi Goreng Spesial',
        productSku: 'MKN-001',
        unit: 'porsi',
        type: StockMovementType.adjustmentIn,
        quantity: 5,
        previousStock: 15,
        currentStock: 20,
        referenceNumber: 'ADJ-20261024-01',
        notes: 'Penyesuaian stok opname mingguan - kelebihan bahan sisa',
        createdAt: now.subtract(const Duration(days: 5, hours: 1)),
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId &&
          productName == other.productName &&
          productSku == other.productSku &&
          unit == other.unit &&
          type == other.type &&
          quantity == other.quantity &&
          previousStock == other.previousStock &&
          currentStock == other.currentStock &&
          referenceNumber == other.referenceNumber &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      productId.hashCode ^
      productName.hashCode ^
      productSku.hashCode ^
      unit.hashCode ^
      type.hashCode ^
      quantity.hashCode ^
      previousStock.hashCode ^
      currentStock.hashCode ^
      referenceNumber.hashCode ^
      notes.hashCode;
}
