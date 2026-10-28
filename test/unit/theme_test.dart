import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/app/theme/app_typography.dart';

void main() {
  group('AppTheme', () {
    test('light theme provides expected primary colors and brightness', () {
      final theme = AppTheme.light;
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.primary, AppColors.primary500);
      expect(theme.colorScheme.error, AppColors.error);
      expect(theme.useMaterial3, isTrue);
    });

    test('dark theme provides expected primary colors and brightness', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primary400);
      expect(theme.colorScheme.error, AppColors.error);
      expect(theme.useMaterial3, isTrue);
    });

    test('typography tabular figures helper sets monospace family and font feature', () {
      final style = AppTypography.tabularFigures(fontSize: 16);
      expect(style.fontFamily, 'monospace');
      expect(style.fontSize, 16);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('spacing and radius constants adhere to expected design scale', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.minTouchTarget, 48.0);

      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
    });
  });
}
