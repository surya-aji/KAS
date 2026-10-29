import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';

/// Reusable card component for displaying an individual product item in catalog.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.categoryColor,
    this.categoryIcon,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.onViewStockHistory,
  });

  final Product product;
  final Color? categoryColor;
  final IconData? categoryIcon;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleActive;
  final VoidCallback? onViewStockHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = categoryColor ?? theme.colorScheme.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap ?? onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Visual Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(isDark ? 50 : 30),
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: accentColor.withAlpha(isDark ? 90 : 60),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    categoryIcon ?? Icons.inventory_2_rounded,
                    color: accentColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Title, Category & SKU
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: product.isActive
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (!product.isActive)
                          const AppBadge(
                            label: 'Nonaktif',
                            variant: AppBadgeVariant.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (product.categoryName.isNotEmpty)
                          AppBadge(
                            label: product.categoryName,
                            variant: AppBadgeVariant.info,
                          ),
                        if (product.sku.isNotEmpty)
                          AppBadge(
                            label: product.sku,
                            variant: AppBadgeVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Menu
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Pilihan Produk',
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'history':
                      onViewStockHistory?.call();
                      break;
                    case 'toggle':
                      onToggleActive?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: AppSpacing.sm),
                        Text('Edit Produk'),
                      ],
                    ),
                  ),
                  if (onViewStockHistory != null && product.trackStock)
                    const PopupMenuItem<String>(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: AppSpacing.sm),
                          Text('Riwayat Stok'),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          product.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          product.isActive ? 'Nonaktifkan' : 'Aktifkan',
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Hapus Produk',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Price & Stock Information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Selling Price & Profit Info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.formattedSellingPrice,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (product.costPrice > 0)
                    Text(
                      'Modal: ${product.formattedCostPrice} (Margin ${product.profitMarginPercentage.toStringAsFixed(0)}%)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),

              // Stock Status Badge
              _buildStockBadge(),
            ],
          ),

          // Description snippet if available
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppSpacing.xs),

          // Bottom Quick Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit Produk',
                size: 34.0,
                iconSize: 18.0,
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.xs),
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Hapus Produk',
                color: AppColors.error,
                size: 34.0,
                iconSize: 18.0,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockBadge() {
    if (!product.trackStock) {
      return const AppBadge(
        label: 'Tanpa Stok',
        variant: AppBadgeVariant.neutral,
        icon: Icons.all_inclusive_rounded,
      );
    }

    if (product.isOutOfStock) {
      return const AppBadge(
        label: 'Stok Habis (0)',
        variant: AppBadgeVariant.error,
        icon: Icons.warning_rounded,
      );
    }

    if (product.isLowStock) {
      return AppBadge(
        label: 'Sisa ${product.stock} ${product.unit}',
        variant: AppBadgeVariant.warning,
        icon: Icons.error_outline_rounded,
      );
    }

    return AppBadge(
      label: 'Stok: ${product.stock} ${product.unit}',
      variant: AppBadgeVariant.success,
      icon: Icons.check_circle_outline_rounded,
    );
  }
}
