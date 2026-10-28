import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';

/// Reusable confirmation dialog for POS operations (void, delete, close shift, etc.).
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    this.isDanger = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDanger;
  final IconData? icon;

  /// Helper to show this dialog directly.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Konfirmasi',
    String cancelText = 'Batal',
    bool isDanger = false,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDanger: isDanger,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isDanger ? AppColors.error : theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        AppButton(
          text: cancelText,
          variant: AppButtonVariant.outlined,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          text: confirmText,
          variant: isDanger ? AppButtonVariant.danger : AppButtonVariant.primary,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
