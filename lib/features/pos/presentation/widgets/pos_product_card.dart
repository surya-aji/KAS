import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';

/// Touch-friendly product card designed for high-speed POS cashier operations.
class PosProductCard extends StatelessWidget {
  const PosProductCard({
    super.key,
    required this.product,
    this.categoryColor,
    this.categoryIcon,
    this.cartQuantity = 0,
    required this.onTap,
  });

  /// Catalog product domain model.
  final Product product;

  /// Optional category color for visual branding.
  final Color? categoryColor;

  /// Optional category icon.
  final IconData? categoryIcon;

  /// Quantity of this item currently present in the cart.
  final int cartQuantity;

  /// Callback when user taps the card to add it to the cart.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = categoryColor ?? theme.colorScheme.primary;
    final isOutOfStock = product.isOutOfStock;
    final isInCart = cartQuantity > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.roundedMd,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isOutOfStock ? 0.55 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(
                color: isInCart
                    ? theme.colorScheme.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isInCart ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 30 : 10),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Visual Category Avatar & Stock Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(isDark ? 50 : 25),
                              borderRadius: AppRadius.roundedSm,
                              border: Border.all(
                                color: accentColor.withAlpha(isDark ? 90 : 50),
                                width: 1.2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                categoryIcon ?? Icons.inventory_2_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: _buildStockStatusBadge(context),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Product Name
                      Text(
                        product.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),

                      // SKU or Category chip
                      if (product.sku.isNotEmpty)
                        Text(
                          product.sku,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: AppSpacing.xs),

                      // Selling Price
                      Text(
                        product.formattedSellingPrice,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Active in-cart indicator badge
                if (isInCart)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withAlpha(80),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_bag_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$cartQuantity',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockStatusBadge(BuildContext context) {
    if (!product.trackStock) {
      return const AppBadge(
        label: 'Jasa',
        variant: AppBadgeVariant.neutral,
      );
    }

    if (product.isOutOfStock) {
      return const AppBadge(
        label: 'Habis',
        variant: AppBadgeVariant.error,
        icon: Icons.close_rounded,
      );
    }

    if (product.isLowStock) {
      return AppBadge(
        label: 'Sisa ${product.stock}',
        variant: AppBadgeVariant.warning,
      );
    }

    return AppBadge(
      label: '${product.stock} ${product.unit}',
      variant: AppBadgeVariant.neutral,
    );
  }
}
