import 'package:flutter/foundation.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// Domain model representing a product in the offline POS catalog.
///
/// Follows Clean Architecture and maps to SQLite `products` table
/// as specified in sections 2.3, 4.1, and 4.2 of IMPLEMENTATION_PLAN.md.
/// Prices are stored as integer values in Rupiah (no floating-point).
@immutable
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    this.categoryName = '',
    this.sku = '',
    this.barcode = '',
    required this.name,
    this.description = '',
    this.unit = 'pcs',
    required this.sellingPrice,
    this.costPrice = 0,
    this.stock = 0,
    this.minStock = 5,
    this.trackStock = true,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier (UUID).
  final String id;

  /// Foreign key referencing the parent Category ID.
  final String categoryId;

  /// Cached category name for display convenience without joins.
  final String categoryName;

  /// Stock Keeping Unit (e.g. 'PRD-001', 'KOP-02').
  final String sku;

  /// Optional barcode / UPC scanned by camera or barcode reader.
  final String barcode;

  /// Product display name (Nama Produk).
  final String name;

  /// Description or notes (e.g. ingredients, size).
  final String description;

  /// Unit of measurement (e.g. 'pcs', 'porsi', 'cup', 'botol', 'kg').
  final String unit;

  /// Selling price in integer Rupiah (Harga Jual).
  final int sellingPrice;

  /// Cost of goods sold (COGS / HPP / Harga Modal) in integer Rupiah.
  final int costPrice;

  /// Current physical inventory count (Stok).
  final int stock;

  /// Low stock threshold for alerts.
  final int minStock;

  /// Whether sales reduce inventory count. Non-stock products (e.g. services) set to false.
  final bool trackStock;

  /// Whether the product is active in the POS grid.
  final bool isActive;

  /// Optional local image path or placeholder.
  final String? imageUrl;

  /// Timestamp when created.
  final DateTime createdAt;

  /// Timestamp of last modification.
  final DateTime? updatedAt;

  /// Whether stock is depleted.
  bool get isOutOfStock => trackStock && stock <= 0;

  /// Whether stock is below minimum threshold but not yet empty.
  bool get isLowStock => trackStock && stock > 0 && stock <= minStock;

  /// Formatted selling price in Rupiah (e.g. 'Rp25.000').
  String get formattedSellingPrice => CurrencyFormatter.formatRupiah(sellingPrice);

  /// Formatted cost price in Rupiah (e.g. 'Rp15.000').
  String get formattedCostPrice => CurrencyFormatter.formatRupiah(costPrice);

  /// Gross profit per unit (selling price - cost price).
  int get unitProfit => sellingPrice - costPrice;

  /// Profit margin percentage (e.g. 40.0 for 40%).
  double get profitMarginPercentage {
    if (sellingPrice <= 0) return 0.0;
    return (unitProfit / sellingPrice) * 100.0;
  }

  /// Creates a copy of this product with modified values.
  Product copyWith({
    String? id,
    String? categoryId,
    String? categoryName,
    String? sku,
    String? barcode,
    String? name,
    String? description,
    String? unit,
    int? sellingPrice,
    int? costPrice,
    int? stock,
    int? minStock,
    bool? trackStock,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      trackStock: trackStock ?? this.trackStock,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialization to Map for SQLite database persistence or JSON backup.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'category_name': categoryName,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'description': description,
      'unit': unit,
      'selling_price': sellingPrice,
      'cost_price': costPrice,
      'stock': stock,
      'min_stock': minStock,
      'track_stock': trackStock ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Deserialization from Map.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      categoryId: map['category_id'] as String? ?? '',
      categoryName: map['category_name'] as String? ?? '',
      sku: map['sku'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      unit: map['unit'] as String? ?? 'pcs',
      sellingPrice: (map['selling_price'] as num?)?.toInt() ?? 0,
      costPrice: (map['cost_price'] as num?)?.toInt() ?? 0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      minStock: (map['min_stock'] as num?)?.toInt() ?? 5,
      trackStock: (map['track_stock'] as int? ?? 1) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      imageUrl: map['image_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Realistic Indonesian business dummy products across multiple categories.
  static List<Product> initialProducts() {
    final now = DateTime.now();
    return [
      Product(
        id: 'prd-01',
        categoryId: 'cat-makanan-01',
        categoryName: 'Makanan',
        sku: 'MKN-001',
        barcode: '8991001001',
        name: 'Nasi Goreng Spesial',
        description: 'Nasi goreng dengan telur, suwir ayam, dan kerupuk',
        unit: 'porsi',
        sellingPrice: 25000,
        costPrice: 15000,
        stock: 35,
        minStock: 10,
        trackStock: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Product(
        id: 'prd-02',
        categoryId: 'cat-makanan-01',
        categoryName: 'Makanan',
        sku: 'MKN-002',
        barcode: '8991001002',
        name: 'Mie Goreng Seafood',
        description: 'Mie telur dengan udang, cumi, dan sayuran',
        unit: 'porsi',
        sellingPrice: 28000,
        costPrice: 17000,
        stock: 4, // Low stock example
        minStock: 5,
        trackStock: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 18)),
      ),
      Product(
        id: 'prd-03',
        categoryId: 'cat-minuman-02',
        categoryName: 'Minuman',
        sku: 'MNM-001',
        barcode: '8992001001',
        name: 'Kopi Susu Gula Aren',
        description: 'Espresso double shot dengan fresh milk dan gula aren asli',
        unit: 'cup',
        sellingPrice: 18000,
        costPrice: 8500,
        stock: 50,
        minStock: 15,
        trackStock: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 16)),
      ),
      Product(
        id: 'prd-04',
        categoryId: 'cat-minuman-02',
        categoryName: 'Minuman',
        sku: 'MNM-002',
        barcode: '8992001002',
        name: 'Es Teh Manis Jumbo',
        description: 'Teh melati wangi dengan es batu segar porsi jumbo',
        unit: 'cup',
        sellingPrice: 7000,
        costPrice: 2500,
        stock: 0, // Out of stock example
        minStock: 10,
        trackStock: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Product(
        id: 'prd-05',
        categoryId: 'cat-snack-03',
        categoryName: 'Snack & Camilan',
        sku: 'SNK-001',
        barcode: '8993001001',
        name: 'Kentang Goreng Keju',
        description: 'French fries renyah dengan taburan keju gurih',
        unit: 'porsi',
        sellingPrice: 16000,
        costPrice: 7000,
        stock: 25,
        minStock: 8,
        trackStock: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 12)),
      ),
      Product(
        id: 'prd-06',
        categoryId: 'cat-paket-04',
        categoryName: 'Paket Hemat',
        sku: 'PKT-001',
        barcode: '8994001001',
        name: 'Paket Kenyang (Nasi + Es Teh)',
        description: 'Nasi goreng spesial lengkap dengan es teh manis',
        unit: 'paket',
        sellingPrice: 30000,
        costPrice: 17500,
        stock: 20,
        minStock: 5,
        trackStock: true,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Product(
        id: 'prd-07',
        categoryId: 'cat-jasa-06',
        categoryName: 'Jasa & Layanan',
        sku: 'JSA-001',
        barcode: '',
        name: 'Biaya Ongkos Kirim Lokal',
        description: 'Pengantaran pesanan radius hingga 3 km',
        unit: 'layanan',
        sellingPrice: 10000,
        costPrice: 0,
        stock: 0,
        minStock: 0,
        trackStock: false, // Non-inventory service example
        isActive: true,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          categoryId == other.categoryId &&
          sku == other.sku &&
          barcode == other.barcode &&
          name == other.name &&
          description == other.description &&
          unit == other.unit &&
          sellingPrice == other.sellingPrice &&
          costPrice == other.costPrice &&
          stock == other.stock &&
          minStock == other.minStock &&
          trackStock == other.trackStock &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      categoryId.hashCode ^
      sku.hashCode ^
      barcode.hashCode ^
      name.hashCode ^
      description.hashCode ^
      unit.hashCode ^
      sellingPrice.hashCode ^
      costPrice.hashCode ^
      stock.hashCode ^
      minStock.hashCode ^
      trackStock.hashCode ^
      isActive.hashCode;
}
