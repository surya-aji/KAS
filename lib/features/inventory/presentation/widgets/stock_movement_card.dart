import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/app/theme/app_typography.dart';
import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';

/// Reusable card component rendering an individual inventory stock change record.
class StockMovementCard extends StatelessWidget {
  const StockMovementCard({
    super.key,
    required this.movement,
    this.onTap,
  });

  final StockMovement movement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Accent color based on positive (in) vs negative (out) movement
    final Color qtyColor = movement.type.isPositive
        ? (isDark ? const Color(0xFF86EFAC) : AppColors.success)
        : (isDark ? const Color(0xFFFCA5A5) : AppColors.error);

    final Color avatarBgColor = movement.type.isPositive
        ? (isDark ? AppColors.successDark.withAlpha(50) : AppColors.successLight)
        : (isDark ? AppColors.errorDark.withAlpha(50) : AppColors.errorLight);

    final Color avatarIconColor = movement.type.isPositive
        ? (isDark ? const Color(0xFF86EFAC) : AppColors.successDark)
        : (isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Product Name, Badges, and Signed Quantity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: avatarBgColor,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: avatarIconColor.withAlpha(isDark ? 90 : 60),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    movement.type.icon,
                    color: avatarIconColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Product Info & Movement Type Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppBadge(
                          label: movement.type.displayName,
                          variant: movement.type.badgeVariant,
                          icon: movement.type.icon,
                        ),
                        if (movement.productSku.isNotEmpty)
                          AppBadge(
                            label: movement.productSku,
                            variant: AppBadgeVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity Changed (+20 porsi / -5 cup)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    movement.formattedQuantity,
                    style: AppTypography.tabularFigures(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: qtyColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movement.type.isPositive ? 'Masuk' : 'Keluar',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: qtyColor.withAlpha(200),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Stock Transition Info & Reference Pill
          Row(
            children: [
              // Stock Transition Indicator
              Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Stok: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                movement.formattedStockTransition,
                style: AppTypography.tabularFigures(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),

              // Reference Number Tag
              if (movement.referenceNumber.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    borderRadius: AppRadius.roundedSm,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag_rounded,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        movement.referenceNumber,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Audit / Explanation Notes
          if (movement.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant.withAlpha(80)
                    : AppColors.lightSurfaceVariant.withAlpha(120),
                borderRadius: AppRadius.roundedSm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.notes_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      movement.notes,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),

          // Timestamp Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
              ),
              const SizedBox(width: 4),
              Text(
                movement.formattedDate,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
