import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';

/// Specialized input field for entering amounts in Indonesian Rupiah (Rp).
///
/// Ensures inputs are treated as integer rupiah values (no floating-point)
/// as required by the business rules and implementation plan.
class AppCurrencyField extends StatefulWidget {
  const AppCurrencyField({
    super.key,
    this.initialAmount,
    this.label = 'Nominal',
    this.hint = '0',
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onAmountChanged,
    this.validator,
  });

  final int? initialAmount;
  final String? label;
  final String hint;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final ValueChanged<int>? onAmountChanged;
  final FormFieldValidator<String>? validator;

  @override
  State<AppCurrencyField> createState() => _AppCurrencyFieldState();
}

class _AppCurrencyFieldState extends State<AppCurrencyField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialText = widget.initialAmount != null && widget.initialAmount! > 0
        ? CurrencyFormatter.formatNumber(widget.initialAmount!)
        : '';
    _controller = TextEditingController(text: initialText);
  }

  @override
  void didUpdateWidget(covariant AppCurrencyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialAmount != oldWidget.initialAmount) {
      final currentParsed = _parseAmount(_controller.text);
      if (currentParsed != widget.initialAmount) {
        final newText = widget.initialAmount != null && widget.initialAmount! > 0
            ? CurrencyFormatter.formatNumber(widget.initialAmount!)
            : '';
        _controller.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _parseAmount(String text) {
    final rawDigits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return rawDigits.isEmpty ? 0 : int.tryParse(rawDigits) ?? 0;
  }

  void _onChanged(String value) {
    final amount = _parseAmount(value);
    final formatted = amount > 0 ? CurrencyFormatter.formatNumber(amount) : '';

    if (formatted != value) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    widget.onAmountChanged?.call(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: _controller,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: _onChanged,
          validator: widget.validator,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(120),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                'Rp',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
          ),
        ),
      ],
    );
  }
}
