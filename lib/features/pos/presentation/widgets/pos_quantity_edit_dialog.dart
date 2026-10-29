import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/domain/models/discount_type.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_currency_field.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Callback signature when item editing is saved.
typedef OnQuantityEditSave = void Function(
  int newQuantity,
  String notes, [
  DiscountType? discountType,
  double? discountValue,
]);

/// Modal dialog for interactive cart item editing (Task T2.2 & T2.3).
///
/// Enables cashiers to:
/// 1. Directly input custom numeric quantities (e.g. 50 pcs).
/// 2. Use quick preset increment chips (+1, +5, +10, Maks).
/// 3. Add or modify item-specific customer notes (e.g. "Pedas sedang", "Tanpa es").
/// 4. Configure item-level discount (% or fixed nominal Rp) with preset chips.
/// 5. View real-time gross subtotal, item discount, and net subtotal calculations.
/// 6. Delete the item directly from the cart.
class PosQuantityEditDialog extends StatefulWidget {
  const PosQuantityEditDialog({
    super.key,
    required this.cartItem,
    required this.onSave,
    required this.onDelete,
  });

  /// The active cart item being modified.
  final CartItem cartItem;

  /// Callback when changes are saved with (newQuantity, notes, [discountType, discountValue]).
  final OnQuantityEditSave onSave;

  /// Callback when user selects to delete the item from the cart.
  final VoidCallback onDelete;

  /// Convenient static helper to show this dialog.
  static Future<void> show(
    BuildContext context, {
    required CartItem cartItem,
    required OnQuantityEditSave onSave,
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
  late final TextEditingController _discountPercentController;

  late int _currentQuantity;
  late DiscountType _discountType;
  late double _discountValue;
  String? _stockValidationError;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.cartItem.quantity;
    _discountType = widget.cartItem.discountType;
    _discountValue = widget.cartItem.discountValue;

    _qtyController = TextEditingController(text: '$_currentQuantity');
    _notesController = TextEditingController(text: widget.cartItem.notes);

    final initialDiscountText = _discountType.isPercentage && _discountValue > 0
        ? (_discountValue % 1 == 0
            ? _discountValue.toInt().toString()
            : _discountValue.toString())
        : '';
    _discountPercentController =
        TextEditingController(text: initialDiscountText);

    _validateStock(_currentQuantity);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    _discountPercentController.dispose();
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

  void _applyQuickDiscountPercent(double percent) {
    setState(() {
      _discountType = DiscountType.percentage;
      _discountValue = percent;
      _discountPercentController.text = percent > 0
          ? (percent % 1 == 0 ? percent.toInt().toString() : percent.toString())
          : '';
    });
  }

  void _handleSave() {
    if (_currentQuantity <= 0 || _stockValidationError != null) return;
    widget.onSave(
      _currentQuantity,
      _notesController.text.trim(),
      _discountType,
      _discountValue,
    );
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

    // Real-time item calculation breakdown
    final grossSubtotal = product.sellingPrice * _currentQuantity;
    int calculatedDiscountAmount = 0;
    if (_discountValue > 0 && grossSubtotal > 0) {
      if (_discountType.isPercentage) {
        final clamped = _discountValue.clamp(0.0, 100.0);
        calculatedDiscountAmount = ((grossSubtotal * clamped) / 100.0).round();
      } else {
        calculatedDiscountAmount =
            _discountValue.round().clamp(0, grossSubtotal);
      }
    }
    final netSubtotal = (grossSubtotal - calculatedDiscountAmount).clamp(0, grossSubtotal);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.roundedLg,
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
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
            ),
            const Divider(height: 1),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Product Info & Stock Banner
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceVariant
                            : AppColors.lightSurfaceVariant,
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
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
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 1: Quantity Stepper & Direct Numeric Input
                    Text(
                      'Jumlah / Kuantitas Pesanan',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
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
                              suffixStyle:
                                  theme.textTheme.labelMedium?.copyWith(
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
                        AppIconButton(
                          icon: Icons.add_rounded,
                          size: 44,
                          iconSize: 22,
                          tooltip: 'Tambah 1',
                          onPressed:
                              (!hasStockLimit || _currentQuantity < product.stock)
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
                        _buildPresetChip('+1',
                            () => _updateQuantity(_currentQuantity + 1)),
                        _buildPresetChip('+5',
                            () => _updateQuantity(_currentQuantity + 5)),
                        _buildPresetChip('+10',
                            () => _updateQuantity(_currentQuantity + 10)),
                        _buildPresetChip('+20',
                            () => _updateQuantity(_currentQuantity + 20)),
                        if (hasStockLimit)
                          _buildPresetChip(
                            'Maks (${product.stock})',
                            () => _updateQuantity(product.stock),
                            isHighlight: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 2: Diskon Item (Task T2.3)
                    Row(
                      children: [
                        Text(
                          'Diskon Item',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (_discountValue > 0)
                          AppBadge(
                            label: _discountType.isPercentage
                                ? '${_discountValue.toStringAsFixed(_discountValue % 1 == 0 ? 0 : 1)}%'
                                : CurrencyFormatter.formatRupiah(
                                    _discountValue.toInt()),
                            variant: AppBadgeVariant.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<DiscountType>(
                      segments: const [
                        ButtonSegment(
                          value: DiscountType.percentage,
                          label: Text('Persen (%)'),
                        ),
                        ButtonSegment(
                          value: DiscountType.fixed,
                          label: Text('Nominal (Rp)'),
                        ),
                      ],
                      selected: {_discountType},
                      onSelectionChanged: (selected) {
                        setState(() {
                          _discountType = selected.first;
                          _discountValue = 0.0;
                          _discountPercentController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_discountType.isPercentage) ...[
                      AppTextField(
                        controller: _discountPercentController,
                        label: 'Persentase Diskon Item',
                        hint: '0',
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _discountValue = parsed.clamp(0.0, 100.0);
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          _buildPresetChip('0%', () => _applyQuickDiscountPercent(0)),
                          _buildPresetChip('5%', () => _applyQuickDiscountPercent(5)),
                          _buildPresetChip('10%', () => _applyQuickDiscountPercent(10)),
                          _buildPresetChip('15%', () => _applyQuickDiscountPercent(15)),
                          _buildPresetChip('20%', () => _applyQuickDiscountPercent(20)),
                          _buildPresetChip('50%', () => _applyQuickDiscountPercent(50)),
                        ],
                      ),
                    ] else ...[
                      AppCurrencyField(
                        key: ValueKey('item_discount_nominal_$_discountValue'),
                        initialAmount: _discountValue.toInt(),
                        label: 'Potongan Diskon Item (Rp)',
                        hint: '0',
                        onAmountChanged: (amount) {
                          setState(() {
                            _discountValue = amount.toDouble();
                          });
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 3: Order Notes
                    AppTextField(
                      controller: _notesController,
                      label: 'Catatan Khusus (Opsional)',
                      hint: 'Contoh: Pedas sedang, tanpa es batu...',
                      prefixIcon:
                          const Icon(Icons.note_alt_outlined, size: 20),
                      textInputAction: TextInputAction.done,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 4: Real-time Line Calculation Summary
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withAlpha(isDark ? 35 : 15),
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(60),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Subtotal Kotor ($_currentQuantity × ${CurrencyFormatter.formatRupiah(product.sellingPrice)}):',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                CurrencyFormatter.formatRupiah(grossSubtotal),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (calculatedDiscountAmount > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Diskon Item:',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '-${CurrencyFormatter.formatRupiah(calculatedDiscountAmount)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Divider(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Subtotal Akhir Baris:',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                CurrencyFormatter.formatRupiah(netSubtotal),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    tooltip: 'Hapus Item dari Keranjang',
                    onPressed: _handleDelete,
                  ),
                  const Spacer(),
                  AppButton(
                    text: 'Batal',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'Simpan',
                    leadingIcon: Icons.check_rounded,
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.medium,
                    onPressed: isValid ? _handleSave : null,
                  ),
                ],
              ),
            ),
          ],
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
