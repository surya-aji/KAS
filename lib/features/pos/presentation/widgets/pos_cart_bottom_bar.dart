import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';

/// Sticky bottom cart summary bar for mobile smartphones (Task T2.1, T2.2 & T2.3).
///
/// Displays real-time grand total amount (reflecting item/transaction discounts and tax)
/// and highlights savings when discounts are active.
class PosCartBottomBar extends StatelessWidget {
  const PosCartBottomBar({
    super.key,
    required this.totalQuantity,
    required this.totalAmount,
    this.totalDiscounts = 0,
    required this.onViewCart,
  });

  /// Total sum of item quantities.
  final int totalQuantity;

  /// Total grand amount in Rupiah (reflects discounts and taxes).
  final int totalAmount;

  /// Total discount savings amount in Rupiah (Task T2.3).
  final int totalDiscounts;

  /// Callback when user taps "Lihat Pesanan" / Cart button.
  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasItems = totalQuantity > 0;
    final hasSavings = totalDiscounts > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 20),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cart Icon with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: hasItems
                        ? theme.colorScheme.primary.withAlpha(isDark ? 50 : 25)
                        : (isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: hasItems
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ),
                if (hasItems)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$totalQuantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),

            // Item count & Real-time Grand Total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasItems
                        ? (hasSavings
                            ? '$totalQuantity item • Hemat ${CurrencyFormatter.formatRupiah(totalDiscounts)}'
                            : '$totalQuantity item terpilih')
                        : 'Keranjang kosong',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: hasSavings
                          ? AppColors.success
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          hasSavings ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    CurrencyFormatter.formatRupiah(totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: hasItems
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Action Button
            AppButton(
              text: 'Lihat Pesanan',
              leadingIcon: Icons.receipt_long_rounded,
              variant: hasItems
                  ? AppButtonVariant.primary
                  : AppButtonVariant.secondary,
              size: AppButtonSize.medium,
              onPressed: hasItems ? onViewCart : null,
            ),
          ],
        ),
      ),
    );
  }
}
