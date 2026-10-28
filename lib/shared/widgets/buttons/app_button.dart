import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';

/// Style variants for [AppButton].
enum AppButtonVariant {
  primary,
  secondary,
  outlined,
  text,
  danger,
}

/// Sizing options for [AppButton].
enum AppButtonSize {
  small(height: 36.0, iconSize: 18.0, horizontalPadding: AppSpacing.md),
  medium(height: 48.0, iconSize: 20.0, horizontalPadding: AppSpacing.lg),
  large(height: 56.0, iconSize: 24.0, horizontalPadding: AppSpacing.xl);

  const AppButtonSize({
    required this.height,
    required this.iconSize,
    required this.horizontalPadding,
  });

  final double height;
  final double iconSize;
  final double horizontalPadding;
}

/// Unified button component adhering to the Kas Usaha design system.
///
/// Supports loading states, custom icons, full-width stretches,
/// and various semantic variants (primary, secondary, danger, etc.).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    BorderSide? borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        backgroundColor = theme.colorScheme.primary;
        foregroundColor = theme.colorScheme.onPrimary;
        break;
      case AppButtonVariant.secondary:
        backgroundColor = theme.colorScheme.secondaryContainer;
        foregroundColor = theme.colorScheme.onSecondaryContainer;
        break;
      case AppButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.primary;
        borderSide = BorderSide(color: theme.colorScheme.outline);
        break;
      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = theme.colorScheme.primary;
        break;
      case AppButtonVariant.danger:
        backgroundColor = AppColors.error;
        foregroundColor = Colors.white;
        break;
    }

    if (!isEnabled) {
      if (variant == AppButtonVariant.outlined || variant == AppButtonVariant.text) {
        backgroundColor = Colors.transparent;
        foregroundColor = theme.disabledColor;
        if (variant == AppButtonVariant.outlined) {
          borderSide = BorderSide(color: theme.disabledColor.withAlpha(50));
        }
      } else {
        backgroundColor = theme.disabledColor.withAlpha(30);
        foregroundColor = theme.disabledColor;
      }
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: size.iconSize,
        height: size.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: size.iconSize, color: foregroundColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Icon(trailingIcon, size: size.iconSize, color: foregroundColor),
          ],
        ],
      );
    }

    return SizedBox(
      height: size.height,
      width: isFullWidth ? double.infinity : null,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.roundedMd,
          side: borderSide ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
