import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';

/// Semantic variants for [AppBadge].
enum AppBadgeVariant {
  success,
  warning,
  error,
  info,
  neutral,
}

/// Compact badge or status chip for transaction statuses, stock levels, and tags.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (variant) {
      case AppBadgeVariant.success:
        bg = isDark ? AppColors.successDark.withAlpha(80) : AppColors.successLight;
        fg = isDark ? const Color(0xFF86EFAC) : AppColors.successDark;
        break;
      case AppBadgeVariant.warning:
        bg = isDark ? AppColors.warningDark.withAlpha(80) : AppColors.warningLight;
        fg = isDark ? const Color(0xFFFCD34D) : AppColors.warningDark;
        break;
      case AppBadgeVariant.error:
        bg = isDark ? AppColors.errorDark.withAlpha(80) : AppColors.errorLight;
        fg = isDark ? const Color(0xFFFCA5A5) : AppColors.errorDark;
        break;
      case AppBadgeVariant.info:
        bg = isDark ? AppColors.infoDark.withAlpha(80) : AppColors.infoLight;
        fg = isDark ? const Color(0xFF93C5FD) : AppColors.infoDark;
        break;
      case AppBadgeVariant.neutral:
        bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
        fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
