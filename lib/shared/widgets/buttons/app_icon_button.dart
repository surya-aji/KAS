import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';

/// Reusable icon button component with tooltip, badge, and variant options.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.badgeCount,
    this.color,
    this.backgroundColor,
    this.size = 40.0,
    this.iconSize = 22.0,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final int? badgeCount;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = color ?? theme.colorScheme.onSurface;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: AppRadius.roundedSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.roundedSm,
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: onPressed != null ? foregroundColor : theme.disabledColor,
            ),
          ),
        ),
      ),
    );

    if (badgeCount != null && badgeCount! > 0) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: AppRadius.roundedFull,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                badgeCount! > 99 ? '99+' : badgeCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
