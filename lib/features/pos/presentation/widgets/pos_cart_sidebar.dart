import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/domain/models/pos_calculation.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';

/// Dedicated interactive order summary sidebar panel for Tablet landscape layouts (Task T2.1, T2.2 & T2.3).
///
/// Supports:
/// - Real-time breakdown of subtotal, item discounts, transaction discounts, and tax (Task T2.3).
/// - Increment (+) and Decrement (-) items with stock limit checking.
/// - Delete individual items or clear entire cart.
/// - Direct quantity change & notes editing via interactive quantity badge / edit button.
/// - One-tap access to configure transaction-level discount and tax settings.
class PosCartSidebar extends StatelessWidget {
  const PosCartSidebar({
    super.key,
    required this.cartItems,
    required this.totalQuantity,
    required this.totalAmount,
    this.calculation,
    required this.onIncrementItem,
    required this.onDecrementItem,
    required this.onDeleteItem,
    required this.onClearCart,
    this.onEditItem,
    this.onConfigureDiscountAndTax,
    this.onCheckout,
  });

  /// Current items in cart.
  final List<CartItem> cartItems;

  /// Total sum of item quantities.
  final int totalQuantity;

  /// Total amount in Rupiah.
  final int totalAmount;

  /// Comprehensive real-time financial calculation of the cart (Task T2.3).
  final PosCalculation? calculation;

  /// Callback when (+) is pressed on an item.
  final ValueChanged<CartItem> onIncrementItem;

  /// Callback when (-) is pressed on an item.
  final ValueChanged<CartItem> onDecrementItem;

  /// Callback when delete is pressed on an item.
  final ValueChanged<CartItem> onDeleteItem;

  /// Callback when user wants to edit quantity or notes directly.
  final ValueChanged<CartItem>? onEditItem;

  /// Callback to clear entire cart.
  final VoidCallback onClearCart;

  /// Callback to open the transaction discount and tax configuration modal.
  final VoidCallback? onConfigureDiscountAndTax;

  /// Callback to proceed to checkout / payment.
  final VoidCallback? onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use provided calculation or fallback to simple calculation
    final calc = calculation ??
        PosCalculation(
          totalQuantity: totalQuantity,
          grossSubtotal: totalAmount,
          grandTotal: totalAmount,
        );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Pesanan Aktif',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppBadge(
                        label: '$totalQuantity item',
                        variant: totalQuantity > 0
                            ? AppBadgeVariant.success
                            : AppBadgeVariant.neutral,
                      ),
                    ],
                  ),
                ),
                if (cartItems.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      size: 20,
                      color: AppColors.error,
                    ),
                    tooltip: 'Kosongkan Keranjang',
                    visualDensity: VisualDensity.compact,
                    onPressed: onClearCart,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Items List or Empty State
          Expanded(
            child: cartItems.isEmpty
                ? _buildEmptyCart(theme, isDark)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItemTile(theme, isDark, item);
                    },
                  ),
          ),

          const Divider(height: 1),

          // Real-time Calculation Summary & Checkout Footer (Task T2.3)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Discount & Tax Adjustment Button
                if (cartItems.isNotEmpty && onConfigureDiscountAndTax != null) ...[
                  InkWell(
                    onTap: onConfigureDiscountAndTax,
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
                              'Diskon & Pajak',
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

                // Gross Subtotal
                _buildBreakdownRow(
                  label: 'Subtotal ($totalQuantity item):',
                  value: calc.formattedGrossSubtotal,
                  theme: theme,
                ),

                // Item Discounts
                if (calc.hasItemDiscounts)
                  _buildBreakdownRow(
                    label: 'Diskon Item:',
                    value: '-${calc.formattedItemDiscounts}',
                    theme: theme,
                    textColor: AppColors.error,
                  ),

                // Transaction Discount
                if (calc.hasTransactionDiscount)
                  _buildBreakdownRow(
                    label: '${calc.transactionDiscountLabel}:',
                    value: '-${calc.formattedTransactionDiscountAmount}',
                    theme: theme,
                    textColor: AppColors.error,
                  ),

                // Taxable Base (DPP)
                if (calc.isTaxEnabled) ...[
                  _buildBreakdownRow(
                    label: 'Dasar Pengenaan Pajak (DPP):',
                    value: calc.formattedTaxableAmount,
                    theme: theme,
                    isSecondary: true,
                  ),
                  _buildBreakdownRow(
                    label: '${calc.taxLabel}:',
                    value: '+${calc.formattedTaxAmount}',
                    theme: theme,
                    textColor: theme.colorScheme.primary,
                  ),
                ],

                const SizedBox(height: AppSpacing.xs),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                    ),
                    const SizedBox(width: AppSpacing.xs),
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

                // Checkout Button
                AppButton(
                  text: totalQuantity > 0
                      ? 'Lanjut Pembayaran (${calc.formattedGrandTotal})'
                      : 'Keranjang Kosong',
                  leadingIcon: Icons.payment_rounded,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: totalQuantity > 0 ? onCheckout : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String value,
    required ThemeData theme,
    Color? textColor,
    bool isSecondary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: (isSecondary
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
            style: (isSecondary
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              fontWeight: isSecondary ? FontWeight.w500 : FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keranjang Kosong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Sentuh produk pada katalog kasir di samping untuk menambahkan ke pesanan.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemTile(
    ThemeData theme,
    bool isDark,
    CartItem item,
  ) {
    final product = item.product;
    final isMaxStockReached =
        product.trackStock && item.quantity >= product.stock;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurface,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Product details & customer notes
          Expanded(
            child: InkWell(
              onTap: onEditItem != null ? () => onEditItem!(item) : null,
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
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${CurrencyFormatter.formatRupiah(product.sellingPrice)} / ${product.unit}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.hasNotes) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.notes,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxs),
                    // Item Subtotal & Discount Badge (Task T2.3)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: 2,
                      children: [
                        Text(
                          item.formattedSubtotal,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
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
                  ],
                ),
              ),
            ),
          ),

          // Stepper & Direct Quantity Editing Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decrement (-)
              AppIconButton(
                icon: Icons.remove_rounded,
                size: 28,
                iconSize: 16,
                tooltip: 'Kurangi Kuantitas',
                onPressed: () => onDecrementItem(item),
              ),

              // Interactive Quantity Badge (Tap to edit directly)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Tooltip(
                  message: 'Sentuh untuk ubah jumlah langsung',
                  child: InkWell(
                    onTap: onEditItem != null ? () => onEditItem!(item) : null,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 32),
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
              ),

              // Increment (+)
              AppIconButton(
                icon: Icons.add_rounded,
                size: 28,
                iconSize: 16,
                tooltip: isMaxStockReached
                    ? 'Stok maksimal tercapai'
                    : 'Tambah Kuantitas',
                onPressed:
                    isMaxStockReached ? null : () => onIncrementItem(item),
              ),
              const SizedBox(width: AppSpacing.xxs),

              // Edit Notes & Details
              if (onEditItem != null)
                AppIconButton(
                  icon: Icons.edit_note_rounded,
                  size: 28,
                  iconSize: 17,
                  tooltip: 'Ubah Jumlah & Catatan',
                  onPressed: () => onEditItem!(item),
                ),
              const SizedBox(width: AppSpacing.xxs),

              // Delete button
              AppIconButton(
                icon: Icons.delete_outline_rounded,
                size: 28,
                iconSize: 16,
                color: AppColors.error,
                tooltip: 'Hapus Item',
                onPressed: () => onDeleteItem(item),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
