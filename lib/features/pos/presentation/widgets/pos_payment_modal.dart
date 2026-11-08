import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/pos/domain/models/payment_method.dart';
import 'package:kas_usaha/features/pos/domain/models/pos_calculation.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_icon_button.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_currency_field.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Interactive Payment Method modal and view (Task T2.4).
///
/// Supports:
/// 1. Three primary payment methods:
///    - **Tunai** (Cash): Real-time change calculation, quick cash suggestions, and shortage detection.
///    - **Transfer** (Bank Transfer): Bank account selection, copy account button, and reference number.
///    - **QRIS**: High-contrast offline QRIS simulation, merchant info, and transaction verification.
/// 2. Responsive presentation:
///    - Modal Bottom Sheet for smartphones.
///    - Centered Dialog for tablets and wide screens.
/// 3. Clear audit tracking via [PaymentResult].
class PosPaymentModal extends StatefulWidget {
  const PosPaymentModal({
    super.key,
    required this.totalAmount,
    this.totalQuantity = 0,
    this.businessName = 'Kas Usaha POS',
    this.calculation,
    this.initialMethod = PaymentMethodType.cash,
    this.onPaymentConfirmed,
  });

  /// Total bill amount payable in integer Rupiah.
  final int totalAmount;

  /// Total quantity of items in the current transaction.
  final int totalQuantity;

  /// Business name to display on QRIS and transfer instructions.
  final String businessName;

  /// Optional calculation breakdown for item/transaction discounts and tax.
  final PosCalculation? calculation;

  /// Initial selected payment method.
  final PaymentMethodType initialMethod;

  /// Callback when payment is verified and confirmed.
  final ValueChanged<PaymentResult>? onPaymentConfirmed;

  /// Convenient static helper to show the payment modal responsively.
  static Future<PaymentResult?> show(
    BuildContext context, {
    required int totalAmount,
    int totalQuantity = 0,
    String businessName = 'Kas Usaha POS',
    PosCalculation? calculation,
    PaymentMethodType initialMethod = PaymentMethodType.cash,
    ValueChanged<PaymentResult>? onPaymentConfirmed,
  }) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isTablet) {
      return showDialog<PaymentResult>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: ClipRRect(
              borderRadius: AppRadius.roundedLg,
              child: Material(
                color: Theme.of(ctx).scaffoldBackgroundColor,
                child: PosPaymentModal(
                  totalAmount: totalAmount,
                  totalQuantity: totalQuantity,
                  businessName: businessName,
                  calculation: calculation,
                  initialMethod: initialMethod,
                  onPaymentConfirmed: onPaymentConfirmed,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<PaymentResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.90,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: PosPaymentModal(
              totalAmount: totalAmount,
              totalQuantity: totalQuantity,
              businessName: businessName,
              calculation: calculation,
              initialMethod: initialMethod,
              onPaymentConfirmed: onPaymentConfirmed,
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PosPaymentModal> createState() => _PosPaymentModalState();
}

class _PosPaymentModalState extends State<PosPaymentModal> {
  late PaymentMethodType _selectedMethod;

  // Cash State
  late int _cashReceivedAmount;
  late List<int> _quickCashOptions;
  final TextEditingController _cashNoteController = TextEditingController();

  // Bank Transfer State
  String _selectedBank = 'BCA';
  final TextEditingController _transferRefController = TextEditingController();
  bool _isTransferVerified = true;

  // QRIS State
  final TextEditingController _qrisRrnController = TextEditingController();
  bool _isQrisVerified = true;

  // Bank account mapping
  final Map<String, Map<String, String>> _bankAccounts = {
    'BCA': {
      'number': '8830-1284-9021',
      'name': 'Kas Usaha Operasional',
    },
    'Mandiri': {
      'number': '137-00-1928-3829',
      'name': 'Kas Usaha Operasional',
    },
    'BRI': {
      'number': '0206-01-029384-501',
      'name': 'Kas Usaha Operasional',
    },
    'BNI': {
      'number': '089-238-1928',
      'name': 'Kas Usaha Operasional',
    },
  };

  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.initialMethod;
    // By default, set cash received to exact amount
    _cashReceivedAmount = widget.totalAmount;
    _quickCashOptions = QuickCashHelper.generateSuggestions(widget.totalAmount);
  }

  @override
  void dispose() {
    _cashNoteController.dispose();
    _transferRefController.dispose();
    _qrisRrnController.dispose();
    super.dispose();
  }

  bool get _isPaymentValid {
    switch (_selectedMethod) {
      case PaymentMethodType.cash:
        return _cashReceivedAmount >= widget.totalAmount;
      case PaymentMethodType.transfer:
        return _isTransferVerified;
      case PaymentMethodType.qris:
        return _isQrisVerified;
    }
  }

  void _confirmPayment() {
    if (!_isPaymentValid) return;

    final PaymentResult result;
    switch (_selectedMethod) {
      case PaymentMethodType.cash:
        result = PaymentResult(
          method: PaymentMethodType.cash,
          totalPayable: widget.totalAmount,
          amountPaid: _cashReceivedAmount,
          changeAmount: _cashReceivedAmount > widget.totalAmount
              ? _cashReceivedAmount - widget.totalAmount
              : 0,
          note: _cashNoteController.text.trim().isNotEmpty
              ? _cashNoteController.text.trim()
              : null,
        );
        break;

      case PaymentMethodType.transfer:
        result = PaymentResult(
          method: PaymentMethodType.transfer,
          totalPayable: widget.totalAmount,
          amountPaid: widget.totalAmount,
          changeAmount: 0,
          bankName: _selectedBank,
          referenceNumber: _transferRefController.text.trim().isNotEmpty
              ? _transferRefController.text.trim()
              : null,
          note: 'Transfer via $_selectedBank',
        );
        break;

      case PaymentMethodType.qris:
        result = PaymentResult(
          method: PaymentMethodType.qris,
          totalPayable: widget.totalAmount,
          amountPaid: widget.totalAmount,
          changeAmount: 0,
          referenceNumber: _qrisRrnController.text.trim().isNotEmpty
              ? _qrisRrnController.text.trim()
              : null,
          note: 'QRIS Digital Payment',
        );
        break;
    }

    widget.onPaymentConfirmed?.call(result);
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modal Drag Handle / Header
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Column(
            children: [
              // Subtle Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.payments_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'Metode Pembayaran',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Tutup',
                    size: 32,
                    iconSize: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Scrollable Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Total Tagihan Banner Card
                _buildTotalAmountBanner(theme, isDark),

                const SizedBox(height: AppSpacing.md),

                // Payment Method Selector Tabs (Tunai, Transfer, QRIS)
                Text(
                  'Pilih Metode Pembayaran',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildMethodSelectorTabs(theme, isDark),

                const SizedBox(height: AppSpacing.lg),

                // Method-Specific View
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildSelectedMethodView(theme, isDark),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1),

        // Sticky Footer Action Buttons
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Batal',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.large,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: AppButton(
                  text: _getConfirmButtonText(),
                  leadingIcon: Icons.check_circle_rounded,
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.large,
                  onPressed: _isPaymentValid ? _confirmPayment : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getConfirmButtonText() {
    switch (_selectedMethod) {
      case PaymentMethodType.cash:
        if (_cashReceivedAmount < widget.totalAmount) {
          final shortage = widget.totalAmount - _cashReceivedAmount;
          return 'Kurang ${CurrencyFormatter.formatRupiah(shortage)}';
        }
        return 'Konfirmasi Tunai';
      case PaymentMethodType.transfer:
        return 'Konfirmasi Transfer';
      case PaymentMethodType.qris:
        return 'Konfirmasi QRIS';
    }
  }

  /// Banner displaying the grand total and optional financial breakdown chips.
  Widget _buildTotalAmountBanner(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withAlpha(isDark ? 30 : 15),
        borderRadius: AppRadius.roundedMd,
        border: Border.all(
          color: theme.colorScheme.primary.withAlpha(isDark ? 80 : 40),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL TAGIHAN',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (widget.totalQuantity > 0)
                      Text(
                        '${widget.totalQuantity} item dalam pesanan',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.formatRupiah(widget.totalAmount),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Savings & Tax Badges if available
          if (widget.calculation != null &&
              (widget.calculation!.hasAnyDiscount ||
                  widget.calculation!.isTaxEnabled)) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (widget.calculation!.hasAnyDiscount)
                  AppBadge(
                    label:
                        'Hemat ${widget.calculation!.formattedTotalDiscounts}',
                    variant: AppBadgeVariant.success,
                  ),
                if (widget.calculation!.isTaxEnabled)
                  AppBadge(
                    label:
                        'Termasuk PPN ${widget.calculation!.taxRate.toStringAsFixed(widget.calculation!.taxRate % 1 == 0 ? 0 : 1)}% (${widget.calculation!.formattedTaxAmount})',
                    variant: AppBadgeVariant.info,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 3 Selectable payment method tabs (Tunai, Transfer, QRIS).
  Widget _buildMethodSelectorTabs(ThemeData theme, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: PaymentMethodType.values.map((method) {
            final isSelected = _selectedMethod == method;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMethod = method;
                    });
                  },
                  borderRadius: AppRadius.roundedMd,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withAlpha(isDark ? 45 : 20)
                          : (isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant),
                      borderRadius: AppRadius.roundedMd,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          method.icon,
                          size: 24,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          method.name,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Builds the view according to the active payment method.
  Widget _buildSelectedMethodView(ThemeData theme, bool isDark) {
    switch (_selectedMethod) {
      case PaymentMethodType.cash:
        return _buildCashView(theme, isDark);
      case PaymentMethodType.transfer:
        return _buildTransferView(theme, isDark);
      case PaymentMethodType.qris:
        return _buildQrisView(theme, isDark);
    }
  }

  // ==========================================
  // 1. CASH PAYMENT VIEW
  // ==========================================
  Widget _buildCashView(ThemeData theme, bool isDark) {
    final change = _cashReceivedAmount > widget.totalAmount
        ? _cashReceivedAmount - widget.totalAmount
        : 0;
    final isExact = _cashReceivedAmount == widget.totalAmount;
    final isShortage = _cashReceivedAmount < widget.totalAmount;
    final shortage = isShortage ? widget.totalAmount - _cashReceivedAmount : 0;

    return Column(
      key: const ValueKey('cash_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Cash Chips
        Text(
          'Pilihan Uang Cepat',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: _quickCashOptions.map((amount) {
            final isCurrent = _cashReceivedAmount == amount;
            final isExactOption = amount == widget.totalAmount;
            return ChoiceChip(
              label: Text(
                isExactOption
                    ? 'Uang Pas (${CurrencyFormatter.formatRupiah(amount)})'
                    : CurrencyFormatter.formatRupiah(amount),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
              selected: isCurrent,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: BorderSide(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _cashReceivedAmount = amount;
                  });
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.md),

        // Custom Cash Received Input Field
        AppCurrencyField(
          label: 'Nominal Uang Diterima',
          initialAmount: _cashReceivedAmount,
          hint: 'Masukkan uang tunai...',
          onAmountChanged: (val) {
            setState(() {
              _cashReceivedAmount = val;
            });
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Real-time Kembalian / Status Box
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isShortage
                ? AppColors.error.withAlpha(isDark ? 35 : 15)
                : (isExact
                    ? theme.colorScheme.primary.withAlpha(isDark ? 35 : 15)
                    : AppColors.success.withAlpha(isDark ? 35 : 15)),
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isShortage
                  ? AppColors.error.withAlpha(120)
                  : (isExact
                      ? theme.colorScheme.primary.withAlpha(120)
                      : AppColors.success.withAlpha(120)),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isShortage
                    ? Icons.warning_amber_rounded
                    : (isExact
                        ? Icons.check_circle_outline_rounded
                        : Icons.savings_rounded),
                color: isShortage
                    ? AppColors.error
                    : (isExact
                        ? theme.colorScheme.primary
                        : AppColors.success),
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isShortage
                          ? 'Pembayaran Kurang'
                          : (isExact ? 'Uang Pas' : 'Kembalian Tunai'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isShortage
                            ? AppColors.error
                            : (isExact
                                ? theme.colorScheme.primary
                                : AppColors.success),
                      ),
                    ),
                    Text(
                      isShortage
                          ? CurrencyFormatter.formatRupiah(shortage)
                          : (isExact
                              ? 'Tidak ada kembalian'
                              : CurrencyFormatter.formatRupiah(change)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isShortage
                            ? AppColors.error
                            : (isExact
                                ? theme.colorScheme.primary
                                : AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Optional Cash Note
        AppTextField(
          controller: _cashNoteController,
          label: 'Catatan Tunai (Opsional)',
          hint: 'Contoh: Uang pecahan 100rb / titip pelanggan',
          prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
        ),
      ],
    );
  }

  // ==========================================
  // 2. BANK TRANSFER VIEW
  // ==========================================
  Widget _buildTransferView(ThemeData theme, bool isDark) {
    final activeAccount = _bankAccounts[_selectedBank] ??
        {
          'number': '8830-1284-9021',
          'name': widget.businessName,
        };

    return Column(
      key: const ValueKey('transfer_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bank Selection Chips
        Text(
          'Pilih Bank Tujuan Transfer',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: _bankAccounts.keys.map((bank) {
            final isCurrent = _selectedBank == bank;
            return ChoiceChip(
              label: Text(
                bank,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              selected: isCurrent,
              selectedColor: theme.colorScheme.primary,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                side: BorderSide(
                  color: isCurrent
                      ? theme.colorScheme.primary
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedBank = bank;
                  });
                }
              },
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.md),

        // Bank Details Card with Copy Account Number
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurfaceVariant,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.account_balance_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'Rekening Bank $_selectedBank',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: activeAccount['number']!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Nomor rekening ${activeAccount['number']} berhasil disalin',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                activeAccount['number']!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'a.n. ${activeAccount['name']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Nominal yang harus ditransfer:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    CurrencyFormatter.formatRupiah(widget.totalAmount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Transfer Reference Number / Sender Name
        AppTextField(
          controller: _transferRefController,
          label: 'Nomor Referensi / Nama Pengirim (Opsional)',
          hint: 'Contoh: TRF-902381 / Budi Santoso',
          prefixIcon: const Icon(Icons.receipt_rounded, size: 20),
        ),

        const SizedBox(height: AppSpacing.md),

        // Transfer Verification Confirmation
        InkWell(
          onTap: () {
            setState(() {
              _isTransferVerified = !_isTransferVerified;
            });
          },
          borderRadius: AppRadius.roundedMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _isTransferVerified
                  ? AppColors.success.withAlpha(isDark ? 30 : 15)
                  : theme.colorScheme.surface,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(
                color: _isTransferVerified
                    ? AppColors.success.withAlpha(120)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isTransferVerified,
                  activeColor: AppColors.success,
                  onChanged: (val) {
                    setState(() {
                      _isTransferVerified = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dana Transfer Telah Masuk',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isTransferVerified
                              ? AppColors.success
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Sudah mengecek mutasi masuk sebesar ${CurrencyFormatter.formatRupiah(widget.totalAmount)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. QRIS DIGITAL PAYMENT VIEW
  // ==========================================
  Widget _buildQrisView(ThemeData theme, bool isDark) {
    return Column(
      key: const ValueKey('qris_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // QRIS Card Container
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurfaceVariant
                : AppColors.lightSurfaceVariant,
            borderRadius: AppRadius.roundedMd,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              // QRIS Brand Header Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F), // Indonesian QRIS red
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'QRIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            'Standar Pembayaran Nasional',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'NMID: ID1020030040',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Merchant Info
              Text(
                widget.businessName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'Tagihan: ${CurrencyFormatter.formatRupiah(widget.totalAmount)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Realistic Offline Simulated QR Display
              _buildSimulatedQrCode(theme, isDark),

              const SizedBox(height: AppSpacing.md),

              // Scan Instructions
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.smartphone_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Scan via GoPay, OVO, Dana, ShopeePay, BCA, Mandiri, dll',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // QRIS Reference / RRN Number Input
        AppTextField(
          controller: _qrisRrnController,
          label: 'Kode Referensi / RRN QRIS (Opsional)',
          hint: 'Contoh: RRN-892182910',
          prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20),
        ),

        const SizedBox(height: AppSpacing.md),

        // QRIS Verification Toggle
        InkWell(
          onTap: () {
            setState(() {
              _isQrisVerified = !_isQrisVerified;
            });
          },
          borderRadius: AppRadius.roundedMd,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _isQrisVerified
                  ? AppColors.success.withAlpha(isDark ? 30 : 15)
                  : theme.colorScheme.surface,
              borderRadius: AppRadius.roundedMd,
              border: Border.all(
                color: _isQrisVerified
                    ? AppColors.success.withAlpha(120)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _isQrisVerified,
                  activeColor: AppColors.success,
                  onChanged: (val) {
                    setState(() {
                      _isQrisVerified = val ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pembayaran QRIS Berhasil',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isQrisVerified
                              ? AppColors.success
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Pelanggan telah scan & saldo berhasil terkonfirmasi',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// High-contrast offline simulated QR code visual representation.
  Widget _buildSimulatedQrCode(ThemeData theme, bool isDark) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated matrix grid
          CustomPaint(
            size: const Size(150, 150),
            painter: _QrPatternPainter(),
          ),
          // Center QRIS Logo
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD32F2F), width: 1.5),
            ),
            child: const Text(
              'QRIS',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline painter to draw an authentic-looking QR code pattern with 3 finder patterns.
class _QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Draw the 3 standard QR corner finder patterns
    void drawFinderPattern(Offset offset, double finderSize) {
      // Outer square
      canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, finderSize, finderSize),
        paint,
      );
      // Inner clear space
      final innerClearPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final step = finderSize / 7;
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + step,
          offset.dy + step,
          finderSize - 2 * step,
          finderSize - 2 * step,
        ),
        innerClearPaint,
      );
      // Center solid square
      canvas.drawRect(
        Rect.fromLTWH(
          offset.dx + 2 * step,
          offset.dy + 2 * step,
          finderSize - 4 * step,
          finderSize - 4 * step,
        ),
        paint,
      );
    }

    const finderSize = 35.0;
    // Top-Left finder
    drawFinderPattern(Offset.zero, finderSize);
    // Top-Right finder
    drawFinderPattern(Offset(size.width - finderSize, 0), finderSize);
    // Bottom-Left finder
    drawFinderPattern(Offset(0, size.height - finderSize), finderSize);

    // Timing patterns & simulated data dots
    const moduleCount = 21;
    final moduleSize = size.width / moduleCount;

    for (int r = 0; r < moduleCount; r++) {
      for (int c = 0; c < moduleCount; c++) {
        // Skip finder areas
        final inTopLeft = r < 7 && c < 7;
        final inTopRight = r < 7 && c >= moduleCount - 7;
        final inBottomLeft = r >= moduleCount - 7 && c < 7;
        final inCenter = (r >= 8 && r <= 12) && (c >= 8 && c <= 12);

        if (inTopLeft || inTopRight || inBottomLeft || inCenter) continue;

        // Deterministic pseudo-random pattern based on coordinates
        final isFilled = ((r * 7 + c * 13 + (r * c)) % 3) == 0;
        if (isFilled) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * moduleSize + 0.5,
              r * moduleSize + 0.5,
              moduleSize - 1,
              moduleSize - 1,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
