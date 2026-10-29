import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Modal dialog for interactive cart item editing (Task T2.2).
///
/// Enables cashiers to:
/// 1. Directly input custom numeric quantities (e.g. 50 pcs).
/// 2. Use quick preset increment chips (+1, +5, +10, Maks).
/// 3. Add or modify item-specific customer notes (e.g., "Pedas sedang", "Tanpa es").
/// 4. View real-time subtotal calculations and stock limit validation.
/// 5. Delete the item directly from the cart.
class PosQuantityEditDialog extends StatefulWidget {
  const PosQuantityEditDialog({
    super.key,
    required this.cartItem,
    required this.onSave,
    required this.onDelete,
  });

  /// The active cart item being modified.
  final CartItem cartItem;

  /// Callback when changes are saved with (newQuantity, notes).
  final void Function(int newQuantity, String notes) onSave;

  /// Callback when user selects to delete the item from the cart.
  final VoidCallback onDelete;

  /// Convenient static helper to show this dialog.
  static Future<void> show(
    BuildContext context, {
    required CartItem cartItem,
    required void Function(int newQuantity, String notes) onSave,
    required VoidCallback onDelete,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PosQuantityEditDialog(
        cartItem: cartItem,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<PosQuantityEditDialog> createState() => _PosQuantityEditDialogState();
}

class _PosQuantityEditDialogState extends State<PosQuantityEditDialog> {
  late final TextEditingController _qtyController;
  late final TextEditingController _notesController;

  late int _currentQuantity;
  String? _stockValidationError;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.cartItem.quantity;
    _qtyController = TextEditingController(text: '$_currentQuantity');
    _notesController = TextEditingController(text: widget.cartItem.notes);
    _validateStock(_currentQuantity);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _validateStock(int qty) {
    final product = widget.cartItem.product;
    if (qty <= 0) {
      _stockValidationError = 'Jumlah pesanan minimal 1 ${product.unit}.';
    } else if (product.trackStock && qty > product.stock) {
      _stockValidationError =
          'Melebihi stok tersedia (Tersisa ${product.stock} ${product.unit}).';
    } else {
      _stockValidationError = null;
    }
  }

  void _updateQuantity(int newQty) {
    final product = widget.cartItem.product;
    final maxStock = product.trackStock ? product.stock : 999999;
    final clampedQty = newQty.clamp(1, maxStock);

    setState(() {
      _currentQuantity = clampedQty;
      _qtyController.text = '$_currentQuantity';
      _validateStock(_currentQuantity);
    });
  }

  void _onQtyInputChanged(String val) {
    final parsed = int.tryParse(val) ?? 0;
    setState(() {
      _currentQuantity = parsed;
      _validateStock(_currentQuantity);
    });
  }

  void _handleSave() {
    if (_currentQuantity <= 0 || _stockValidationError != null) return;
    widget.onSave(_currentQuantity, _notesController.text.trim());
    Navigator.of(context).pop();
  }

  void _handleDelete() {
    widget.onDelete();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final product = widget.cartItem.product;
    final hasStockLimit = product.trackStock;
    final isValid = _currentQuantity > 0 && _stockValidationError == null;
    final calculatedSubtotal = product.sellingPrice * _currentQuantity;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedLg,
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: AppRadius.roundedMd,
                    ),
                    child: Icon(
                      Icons.edit_note_rounded,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Atur Pesanan & Kuantitas',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Product Info & Stock Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Harga Satuan',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${CurrencyFormatter.formatRupiah(product.sellingPrice)} / ${product.unit}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(
                      label: hasStockLimit
                          ? 'Stok: ${product.stock} ${product.unit}'
                          : 'Jasa / Non-stok',
                      variant: hasStockLimit
                          ? (product.stock <= product.minStock
                              ? AppBadgeVariant.warning
                              : AppBadgeVariant.success)
                          : AppBadgeVariant.info,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Quantity Stepper & Direct Numeric Input
              Text(
                'Jumlah / Kuantitas Pesanan',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  // Decrement Button (-)
                  AppIconButton(
                    icon: Icons.remove_rounded,
                    size: 44,
                    iconSize: 22,
                    tooltip: 'Kurangi 1',
                    onPressed: _currentQuantity > 1
                        ? () => _updateQuantity(_currentQuantity - 1)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Direct Numeric Input Field
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        suffixText: product.unit,
                        suffixStyle: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.roundedMd,
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.roundedMd,
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: _onQtyInputChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Increment Button (+)
                  AppIconButton(
                    icon: Icons.add_rounded,
                    size: 44,
                    iconSize: 22,
                    tooltip: 'Tambah 1',
                    onPressed: (!hasStockLimit || _currentQuantity < product.stock)
                        ? () => _updateQuantity(_currentQuantity + 1)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // Stock Validation Warning Message
              if (_stockValidationError != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xxs,
                    bottom: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          _stockValidationError!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Quick Preset Increment Chips
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xxs,
                children: [
                  _buildPresetChip('+1', () => _updateQuantity(_currentQuantity + 1)),
                  _buildPresetChip('+5', () => _updateQuantity(_currentQuantity + 5)),
                  _buildPresetChip('+10', () => _updateQuantity(_currentQuantity + 10)),
                  _buildPresetChip('+20', () => _updateQuantity(_currentQuantity + 20)),
                  if (hasStockLimit)
                    _buildPresetChip(
                      'Maks (${product.stock})',
                      () => _updateQuantity(product.stock),
                      isHighlight: true,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Order Notes / Custom Customer Request
              AppTextField(
                controller: _notesController,
                label: 'Catatan Khusus (Opsional)',
                hint: 'Contoh: Pedas sedang, tanpa es batu...',
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                textInputAction: TextInputAction.done,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),

              // Real-time Subtotal Summary Card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(isDark ? 35 : 15),
                  borderRadius: AppRadius.roundedMd,
                  border: Border.all(
                    color: theme.colorScheme.primary.withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subtotal Baris Item',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '$_currentQuantity × ${CurrencyFormatter.formatRupiah(product.sellingPrice)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.formatRupiah(calculatedSubtotal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Actions Footer
              Row(
                children: [
                  // Delete Button
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    tooltip: 'Hapus Item dari Keranjang',
                    onPressed: _handleDelete,
                  ),
                  const Spacer(),

                  // Cancel Button
                  AppButton(
                    text: 'Batal',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Save Button
                  AppButton(
                    text: 'Simpan',
                    leadingIcon: Icons.check_rounded,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    onPressed: isValid ? _handleSave : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    VoidCallback onTap, {
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: isHighlight ? theme.colorScheme.primary : null,
      ),
      onPressed: onTap,
    );
  }
}
