import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';

/// Domain model representing a product category in the offline POS system.
///
/// Follows Clean Architecture and is prepared for Drift SQLite table mapping
/// (`categories` table in section 4.1 of IMPLEMENTATION_PLAN.md).
/// Also used for JSON backup serialization and cashier POS filtering.
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    this.description = '',
    this.colorHex = defaultColorHex,
    this.iconCodePoint,
    this.productCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  /// Default color hex string (Emerald brand color).
  static const String defaultColorHex = '#137547';

  /// Default icon code point (Icons.category_rounded).
  static final int defaultIconCodePoint = Icons.category_rounded.codePoint;

  /// Unique identifier (UUID).
  final String id;

  /// Display name of the category (e.g. 'Makanan', 'Minuman').
  final String name;

  /// Optional description or operational notes.
  final String description;

  /// Hex color code string (e.g. '#137547' or '#0D9488') for badges & chips.
  final String colorHex;

  /// Code point of the Material icon for visual recognition on POS grid.
  final int? iconCodePoint;

  /// Cached count of active products associated with this category.
  final int productCount;

  /// Whether this category is active and visible in the POS checkout grid.
  final bool isActive;

  /// Timestamp when the category was created.
  final DateTime createdAt;

  /// Timestamp when the category was last modified.
  final DateTime? updatedAt;

  /// Converts the hex string to a [Color] instance safely.
  Color get color {
    try {
      final cleanHex = colorHex.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('0xFF$cleanHex'));
      } else if (cleanHex.length == 8) {
        return Color(int.parse('0x$cleanHex'));
      }
    } catch (_) {
      // Fallback on invalid format
    }
    return AppColors.primary500;
  }

  /// Converts the [iconCodePoint] to an [IconData] safely.
  IconData get icon {
    if (iconCodePoint != null) {
      return IconData(
        // ignore: non_const_argument_for_const_parameter
        iconCodePoint!,
        fontFamily: 'MaterialIcons',
      );
    }
    return Icons.category_rounded;
  }

  /// Creates a copy of this category with updated values.
  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? colorHex,
    int? iconCodePoint,
    int? productCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      productCount: productCount ?? this.productCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes category to Map for SQLite persistence or JSON backup.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color_hex': colorHex,
      'icon_code_point': iconCodePoint,
      'product_count': productCount,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Deserializes category from Map (SQLite row or JSON).
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      colorHex: map['color_hex'] as String? ?? defaultColorHex,
      iconCodePoint: map['icon_code_point'] as int?,
      productCount: (map['product_count'] as num?)?.toInt() ?? 0,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'] as String)
          : null,
    );
  }

  /// Pre-populated realistic categories for initial Indonesian business state.
  static List<Category> initialCategories() {
    final now = DateTime.now();
    return [
      Category(
        id: 'cat-makanan-01',
        name: 'Makanan',
        description: 'Menu utama makanan berat dan porsi makan',
        colorHex: '#137547', // Emerald
        iconCodePoint: Icons.restaurant_rounded.codePoint,
        productCount: 12,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      Category(
        id: 'cat-minuman-02',
        name: 'Minuman',
        description: 'Kopi, teh, jus buah, dan minuman segar',
        colorHex: '#0D9488', // Teal
        iconCodePoint: Icons.local_cafe_rounded.codePoint,
        productCount: 8,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      Category(
        id: 'cat-snack-03',
        name: 'Snack & Camilan',
        description: 'Makanan ringan, pastry, dan gorengan',
        colorHex: '#D97706', // Amber
        iconCodePoint: Icons.fastfood_rounded.codePoint,
        productCount: 15,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      Category(
        id: 'cat-paket-04',
        name: 'Paket Hemat',
        description: 'Kombinasi bundling makanan dan minuman hemat',
        colorHex: '#2563EB', // Blue
        iconCodePoint: Icons.loyalty_rounded.codePoint,
        productCount: 5,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      Category(
        id: 'cat-bahan-05',
        name: 'Bahan Baku',
        description: 'Stok bahan baku dapur dan inventori dasar',
        colorHex: '#475569', // Slate
        iconCodePoint: Icons.inventory_2_rounded.codePoint,
        productCount: 6,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      Category(
        id: 'cat-jasa-06',
        name: 'Jasa & Layanan',
        description: 'Biaya kirim, sewa tempat, dan layanan kustom',
        colorHex: '#7C3AED', // Purple
        iconCodePoint: Icons.build_rounded.codePoint,
        productCount: 2,
        isActive: false, // Inactive example to test filtering
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          colorHex == other.colorHex &&
          iconCodePoint == other.iconCodePoint &&
          productCount == other.productCount &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      colorHex.hashCode ^
      iconCodePoint.hashCode ^
      productCount.hashCode ^
      isActive.hashCode;
}
