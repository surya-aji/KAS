import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/domain/models/discount_type.dart';
import 'package:kas_usaha/features/pos/domain/services/transaction_calculator.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_currency_field.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Modal dialog for configuring transaction-level discount and tax (PPN) in real-time (Task T2.3).
///
/// Features:
/// 1. Transaction discount (% or fixed nominal Rp) with quick preset chips.
/// 2. Pajak (PPN) toggle and customizable percentage rate (default 11%).
/// 3. Live simulated financial calculation breakdown before applying.
class PosDiscountTaxDialog extends StatefulWidget {
  const PosDiscountTaxDialog({
    super.key,
    required this.cartItems,
    required this.initialDiscountType,
    required this.initialDiscountValue,
    required this.initialIsTaxApplied,
    required this.initialTaxRate,
    required this.onApply,
  });

  /// The active cart items to compute real-time simulation.
  final List<CartItem> cartItems;

  /// Current active discount type.
  final DiscountType initialDiscountType;

  /// Current active discount value.
  final double initialDiscountValue;

  /// Current tax applied state.
  final bool initialIsTaxApplied;

  /// Current tax percentage rate.
  final double initialTaxRate;

  /// Callback when user applies the discount and tax configurations.
  final void Function({
    required DiscountType discountType,
    required double discountValue,
    required bool isTaxApplied,
    required double taxRate,
  }) onApply;

  /// Convenient static helper to show the dialog.
  static Future<void> show(
    BuildContext context, {
    required List<CartItem> cartItems,
    required DiscountType initialDiscountType,
    required double initialDiscountValue,
    required bool initialIsTaxApplied,
    required double initialTaxRate,
    required void Function({
      required DiscountType discountType,
      required double discountValue,
      required bool isTaxApplied,
      required double taxRate,
    }) onApply,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => PosDiscountTaxDialog(
        cartItems: cartItems,
        initialDiscountType: initialDiscountType,
        initialDiscountValue: initialDiscountValue,
        initialIsTaxApplied: initialIsTaxApplied,
        initialTaxRate: initialTaxRate,
        onApply: onApply,
      ),
    );
  }

  @override
  State<PosDiscountTaxDialog> createState() => _PosDiscountTaxDialogState();
}

class _PosDiscountTaxDialogState extends State<PosDiscountTaxDialog> {
  late DiscountType _discountType;
  late double _discountValue;
  late bool _isTaxApplied;
  late double _taxRate;

  late final TextEditingController _percentController;
  late final TextEditingController _taxRateController;

  @override
  void initState() {
    super.initState();
    _discountType = widget.initialDiscountType;
    _discountValue = widget.initialDiscountValue;
    _isTaxApplied = widget.initialIsTaxApplied;
    _taxRate = widget.initialTaxRate;

    final initialPercentText = _discountType.isPercentage && _discountValue > 0
        ? (_discountValue % 1 == 0
            ? _discountValue.toInt().toString()
            : _discountValue.toString())
        : '';
    _percentController = TextEditingController(text: initialPercentText);

    final initialTaxText = _taxRate % 1 == 0
        ? _taxRate.toInt().toString()
        : _taxRate.toString();
    _taxRateController = TextEditingController(text: initialTaxText);
  }

  @override
  void dispose() {
    _percentController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  void _onDiscountTypeChanged(DiscountType type) {
    setState(() {
      _discountType = type;
      _discountValue = 0.0;
      _percentController.clear();
    });
  }

  void _applyQuickPercentage(double percent) {
    setState(() {
      _discountType = DiscountType.percentage;
      _discountValue = percent;
      _percentController.text =
          percent > 0 ? (percent % 1 == 0 ? percent.toInt().toString() : percent.toString()) : '';
    });
  }

  void _applyQuickNominal(int amount) {
    setState(() {
      _discountType = DiscountType.fixed;
      _discountValue = amount.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate real-time simulated financial result
    final liveCalc = TransactionCalculator.calculate(
      cartItems: widget.cartItems,
      transactionDiscountType: _discountType,
      transactionDiscountValue: _discountValue,
      isTaxEnabled: _isTaxApplied,
      taxRate: _taxRate,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedLg),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Title & Close Button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: AppRadius.roundedSm,
                    ),
                    child: Icon(
                      Icons.percent_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Atur Diskon & Pajak Transaksi',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION 1: DISKON TRANSAKSI
                    Row(
                      children: [
                        Text(
                          'Diskon Transaksi / Nota',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (_discountValue > 0)
                          AppBadge(
                            label: _discountType.isPercentage
                                ? '${_discountValue.toStringAsFixed(_discountValue % 1 == 0 ? 0 : 1)}%'
                                : CurrencyFormatter.formatRupiah(_discountValue.toInt()),
                            variant: AppBadgeVariant.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Discount Type Selector (Percentage vs Nominal)
                    SegmentedButton<DiscountType>(
                      segments: const [
                        ButtonSegment(
                          value: DiscountType.percentage,
                          label: Text('Persentase (%)'),
                          icon: Icon(Icons.pie_chart_outline_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: DiscountType.fixed,
                          label: Text('Nominal (Rp)'),
                          icon: Icon(Icons.money_rounded, size: 16),
                        ),
                      ],
                      selected: {_discountType},
                      onSelectionChanged: (selected) {
                        _onDiscountTypeChanged(selected.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Value Input Field
                    if (_discountType.isPercentage) ...[
                      AppTextField(
                        controller: _percentController,
                        label: 'Persentase Diskon',
                        hint: '0',
                        suffixIcon: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        onChanged: (val) {
                          final parsed = double.tryParse(val) ?? 0.0;
                          setState(() {
                            _discountValue = parsed.clamp(0.0, 100.0);
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Quick Percentage Chips
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          _buildQuickChip(
                            label: 'Tanpa Diskon',
                            isSelected: _discountValue == 0,
                            onTap: () => _applyQuickPercentage(0),
                          ),
                          _buildQuickChip(
                            label: '5%',
                            isSelected: _discountValue == 5,
                            onTap: () => _applyQuickPercentage(5),
                          ),
                          _buildQuickChip(
                            label: '10%',
                            isSelected: _discountValue == 10,
                            onTap: () => _applyQuickPercentage(10),
                          ),
                          _buildQuickChip(
                            label: '15%',
                            isSelected: _discountValue == 15,
                            onTap: () => _applyQuickPercentage(15),
                          ),
                          _buildQuickChip(
                            label: '20%',
                            isSelected: _discountValue == 20,
                            onTap: () => _applyQuickPercentage(20),
                          ),
                          _buildQuickChip(
                            label: '50%',
                            isSelected: _discountValue == 50,
                            onTap: () => _applyQuickPercentage(50),
                          ),
                        ],
                      ),
                    ] else ...[
                      AppCurrencyField(
                        key: ValueKey('discount_nominal_$_discountValue'),
                        initialAmount: _discountValue.toInt(),
                        label: 'Nominal Potongan Diskon (Rp)',
                        hint: '0',
                        onAmountChanged: (amount) {
                          setState(() {
                            _discountValue = amount.toDouble();
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Quick Nominal Chips
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: [
                          _buildQuickChip(
                            label: 'Rp0',
                            isSelected: _discountValue == 0,
                            onTap: () => _applyQuickNominal(0),
                          ),
                          _buildQuickChip(
                            label: 'Rp5.000',
                            isSelected: _discountValue == 5000,
                            onTap: () => _applyQuickNominal(5000),
                          ),
                          _buildQuickChip(
                            label: 'Rp10.000',
                            isSelected: _discountValue == 10000,
                            onTap: () => _applyQuickNominal(10000),
                          ),
                          _buildQuickChip(
                            label: 'Rp20.000',
                            isSelected: _discountValue == 20000,
                            onTap: () => _applyQuickNominal(20000),
                          ),
                          _buildQuickChip(
                            label: 'Rp50.000',
                            isSelected: _discountValue == 50000,
                            onTap: () => _applyQuickNominal(50000),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // SECTION 2: PAJAK TRANSAKSI (PPN)
                    Material(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      borderRadius: AppRadius.roundedMd,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.roundedMd,
                          border: Border.all(
                            color: _isTaxApplied
                                ? theme.colorScheme.primary.withAlpha(120)
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                'Kenakan Pajak (PPN)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                _isTaxApplied
                                    ? 'Pajak aktif pada transaksi ini'
                                  : 'Transaksi bebas pajak',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: _isTaxApplied,
                            onChanged: (val) {
                              setState(() {
                                _isTaxApplied = val;
                              });
                            },
                          ),
                          if (_isTaxApplied) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _taxRateController,
                                    label: 'Tarif Pajak',
                                    hint: '11',
                                    suffixIcon: const Padding(
                                      padding: EdgeInsets.all(AppSpacing.sm),
                                      child: Text('%', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    onChanged: (val) {
                                      final parsed = double.tryParse(val) ?? 0.0;
                                      setState(() {
                                        _taxRate = parsed.clamp(0.0, 100.0);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                _buildQuickChip(
                                  label: '10%',
                                  isSelected: _taxRate == 10,
                                  onTap: () {
                                    setState(() {
                                      _taxRate = 10.0;
                                      _taxRateController.text = '10';
                                    });
                                  },
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                _buildQuickChip(
                                  label: '11%',
                                  isSelected: _taxRate == 11,
                                  onTap: () {
                                    setState(() {
                                      _taxRate = 11.0;
                                      _taxRateController.text = '11';
                                    });
                                  },
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                _buildQuickChip(
                                  label: '12%',
                                  isSelected: _taxRate == 12,
                                  onTap: () {
                                    setState(() {
                                      _taxRate = 12.0;
                                      _taxRateController.text = '12';
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                    // SECTION 3: LIVE FINANCIAL SIMULATION BREAKDOWN
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withAlpha(12),
                        borderRadius: AppRadius.roundedMd,
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(50),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calculate_outlined,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Simulasi Kalkulasi Real-time',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildSummaryRow(
                            'Subtotal Produk (${liveCalc.totalQuantity} item):',
                            liveCalc.formattedGrossSubtotal,
                            theme,
                          ),
                          if (liveCalc.hasItemDiscounts)
                            _buildSummaryRow(
                              'Total Diskon Item:',
                              '-${liveCalc.formattedItemDiscounts}',
                              theme,
                              textColor: AppColors.error,
                            ),
                          if (liveCalc.hasTransactionDiscount)
                            _buildSummaryRow(
                              liveCalc.transactionDiscountLabel,
                              '-${liveCalc.formattedTransactionDiscountAmount}',
                              theme,
                              textColor: AppColors.error,
                            ),
                          if (_isTaxApplied) ...[
                            _buildSummaryRow(
                              'Dasar Pengenaan Pajak (DPP):',
                              liveCalc.formattedTaxableAmount,
                              theme,
                              isSecondary: true,
                            ),
                            _buildSummaryRow(
                              liveCalc.taxLabel,
                              '+${liveCalc.formattedTaxAmount}',
                              theme,
                              textColor: theme.colorScheme.primary,
                            ),
                          ],
                          const Divider(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Akhir:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                liveCalc.formattedGrandTotal,
                                style: theme.textTheme.titleLarge?.copyWith(
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

            // Dialog Actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    text: 'Batal',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'Terapkan (${liveCalc.formattedGrandTotal})',
                    variant: AppButtonVariant.primary,
                    leadingIcon: Icons.check_circle_outline_rounded,
                    onPressed: () {
                      widget.onApply(
                        discountType: _discountType,
                        discountValue: _discountValue,
                        isTaxApplied: _isTaxApplied,
                        taxRate: _taxRate,
                      );
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      backgroundColor: isSelected
          ? theme.colorScheme.primary.withAlpha(25)
          : null,
      side: isSelected
          ? BorderSide(color: theme.colorScheme.primary, width: 1.2)
          : null,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? textColor,
    bool isSecondary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
