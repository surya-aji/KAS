import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/presentation/providers/pos_provider.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';
import 'package:kas_usaha/shared/widgets/dialogs/app_confirm_dialog.dart';

/// Interactive Bottom Sheet modal displaying active cart items on mobile devices (Task T2.2 & T2.3).
///
/// Features:
/// - Real-time Riverpod state reactivity with full calculation breakdown (Task T2.3).
/// - Direct item-level discount display and editing.
/// - Transaction-level discount & tax adjustment trigger.
/// - Direct quantity change via tapping quantity badge or edit icon.
/// - Increment (+) and Decrement (-) with stock limits.
/// - Delete individual items with button or swipe-to-dismiss.
/// - Clear entire cart with confirmation dialog.
class PosCartModalSheet extends ConsumerWidget {
  const PosCartModalSheet({
    super.key,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDelete,
    required this.onEdit,
    required this.onClear,
    this.onConfigureDiscountAndTax,
    this.onCheckout,
  });

  /// Callback when (+) is tapped.
  final ValueChanged<CartItem> onIncrement;

  /// Callback when (-) is tapped.
  final ValueChanged<CartItem> onDecrement;

  /// Callback when delete is tapped.
  final ValueChanged<CartItem> onDelete;

  /// Callback to edit quantity or notes directly.
  final ValueChanged<CartItem> onEdit;

  /// Callback to clear entire cart.
  final VoidCallback onClear;

  /// Callback to open discount and tax configuration modal.
  final VoidCallback? onConfigureDiscountAndTax;

  /// Callback to proceed to checkout / payment.
  final VoidCallback? onCheckout;

  /// Static helper method to display the mobile cart sheet.
  static Future<void> show(
    BuildContext context, {
    required ValueChanged<CartItem> onIncrement,
    required ValueChanged<CartItem> onDecrement,
    required ValueChanged<CartItem> onDelete,
    required ValueChanged<CartItem> onEdit,
    required VoidCallback onClear,
    VoidCallback? onConfigureDiscountAndTax,
    VoidCallback? onCheckout,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PosCartModalSheet(
        onIncrement: onIncrement,
        onDecrement: onDecrement,
        onDelete: onDelete,
        onEdit: onEdit,
        onClear: onClear,
        onConfigureDiscountAndTax: onConfigureDiscountAndTax,
        onCheckout: onCheckout,
      ),
    );
  }

  Future<void> _confirmClearCart(
    BuildContext context,
    int totalQuantity,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Kosongkan Keranjang?',
      message:
          'Apakah Anda yakin ingin menghapus semua $totalQuantity item dari keranjang pesanan ini?',
      confirmText: 'Kosongkan',
      cancelText: 'Batal',
      isDanger: true,
      icon: Icons.delete_sweep_rounded,
    );

    if (confirmed == true && context.mounted) {
      onClear();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posState = ref.watch(posProvider);
    final calc = posState.calculation;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withAlpha(70),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Rincian Pesanan',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppBadge(
                        label: '${posState.totalQuantity} item',
                        variant: posState.hasItems
                            ? AppBadgeVariant.success
                            : AppBadgeVariant.neutral,
                      ),
                    ],
                  ),
                ),
                if (posState.cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    tooltip: 'Kosongkan Keranjang',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        _confirmClearCart(context, posState.totalQuantity),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart Items List or Empty State
          Flexible(
            child: posState.cartItems.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant
                                .withAlpha(120),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Keranjang Kosong',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'Belum ada produk yang dimasukkan ke keranjang.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    shrinkWrap: true,
                    itemCount: posState.cartItems.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = posState.cartItems[index];
                      return _buildMobileCartItemTile(theme, isDark, item);
                    },
                  ),
          ),

          const Divider(height: 1),

          // Real-time Calculation Breakdown & Checkout Button (Task T2.3)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Quick Discount & Tax Adjustment Row
                  if (posState.hasItems && onConfigureDiscountAndTax != null) ...[
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onConfigureDiscountAndTax!();
                      },
                      borderRadius: AppRadius.roundedSm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(15),
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(
                            color: theme.colorScheme.primary.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                'Atur Diskon & Pajak',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            if (calc.hasTransactionDiscount) ...[
                              AppBadge(
                                label: calc.transactionDiscountType.isPercentage
                                    ? '-${calc.transactionDiscountValue.toStringAsFixed(calc.transactionDiscountValue % 1 == 0 ? 0 : 1)}%'
                                    : '-${CurrencyFormatter.formatRupiah(calc.transactionDiscountAmount)}',
                                variant: AppBadgeVariant.success,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                            ],
                            if (calc.isTaxEnabled) ...[
                              AppBadge(
                                label: 'PPN ${calc.taxRate.toStringAsFixed(calc.taxRate % 1 == 0 ? 0 : 1)}%',
                                variant: AppBadgeVariant.info,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                            ],
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],

                  // Subtotal
                  _buildSummaryLine(
                    'Subtotal (${calc.totalQuantity} item):',
                    calc.formattedGrossSubtotal,
                    theme,
                  ),

                  // Item Discounts
                  if (calc.hasItemDiscounts)
                    _buildSummaryLine(
                      'Diskon Item:',
                      '-${calc.formattedItemDiscounts}',
                      theme,
                      color: AppColors.error,
                    ),

                  // Transaction Discount
                  if (calc.hasTransactionDiscount)
                    _buildSummaryLine(
                      '${calc.transactionDiscountLabel}:',
                      '-${calc.formattedTransactionDiscountAmount}',
                      theme,
                      color: AppColors.error,
                    ),

                  // Tax (PPN)
                  if (calc.isTaxEnabled) ...[
                    _buildSummaryLine(
                      'Dasar Pengenaan Pajak (DPP):',
                      calc.formattedTaxableAmount,
                      theme,
                      isDimmed: true,
                    ),
                    _buildSummaryLine(
                      '${calc.taxLabel}:',
                      '+${calc.formattedTaxAmount}',
                      theme,
                      color: theme.colorScheme.primary,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xxs),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.xs),

                  // Grand Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (calc.hasAnyDiscount)
                            Text(
                              'Hemat ${calc.formattedTotalDiscounts}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        calc.formattedGrandTotal,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Tutup Keranjang',
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.large,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      if (onCheckout != null && posState.hasItems) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: 'Bayar Sekarang',
                            leadingIcon: Icons.payment_rounded,
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.large,
                            onPressed: () {
                              Navigator.of(context).pop();
                              onCheckout!();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
    bool isDimmed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: (isDimmed
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: (isDimmed
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: isDimmed ? FontWeight.w500 : FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartItemTile(
    ThemeData theme,
    bool isDark,
    CartItem item,
  ) {
    final product = item.product;
    final isMaxStockReached =
        product.trackStock && item.quantity >= product.stock;

    return Dismissible(
      key: ValueKey('dismiss_cart_${item.product.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: AppRadius.roundedMd,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hapus',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(item),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
          borderRadius: AppRadius.roundedMd,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            // Details & clickable area to edit
            Expanded(
              child: InkWell(
                onTap: () => onEdit(item),
                borderRadius: AppRadius.roundedSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      // Price & Quantity
                      Text(
                        '${CurrencyFormatter.formatRupiah(product.sellingPrice)} × ${item.quantity}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 1),
                      // Line Subtotal & Discount Badge (Task T2.3)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: 2,
                        children: [
                          Text(
                            item.formattedSubtotal,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.hasDiscount) ...[
                            Text(
                              item.formattedGrossSubtotal,
                              style: theme.textTheme.labelSmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AppBadge(
                              label: item.discountDescription,
                              variant: AppBadgeVariant.success,
                            ),
                          ],
                        ],
                      ),
                      if (item.hasNotes) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                item.notes,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Stepper controls
            AppIconButton(
              icon: Icons.remove_rounded,
              size: 28,
              iconSize: 16,
              tooltip: 'Kurangi Kuantitas',
              onPressed: () => onDecrement(item),
            ),

            // Quantity Tap-to-Edit Badge
            Tooltip(
              message: 'Sentuh untuk ubah jumlah',
              child: InkWell(
                onTap: () => onEdit(item),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(80),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),

            AppIconButton(
              icon: Icons.add_rounded,
              size: 28,
              iconSize: 16,
              tooltip: isMaxStockReached
                  ? 'Stok maksimal tercapai'
                  : 'Tambah Kuantitas',
              onPressed: isMaxStockReached ? null : () => onIncrement(item),
            ),
            const SizedBox(width: AppSpacing.xxs),

            AppIconButton(
              icon: Icons.edit_note_rounded,
              size: 28,
              iconSize: 17,
              tooltip: 'Ubah Jumlah & Catatan',
              onPressed: () => onEdit(item),
            ),
            const SizedBox(width: AppSpacing.xxs),

            AppIconButton(
              icon: Icons.delete_outline_rounded,
              size: 28,
              iconSize: 16,
              color: AppColors.error,
              tooltip: 'Hapus Item',
              onPressed: () => onDelete(item),
            ),
          ],
        ),
      ),
    );
  }
}
