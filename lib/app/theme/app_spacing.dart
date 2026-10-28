import 'package:flutter/material.dart';

/// Spacing and layout metrics based on a consistent 4-point / 8-point grid.
class AppSpacing {
  AppSpacing._();

  /// 2.0 dp
  static const double xxs = 2.0;

  /// 4.0 dp
  static const double xs = 4.0;

  /// 8.0 dp
  static const double sm = 8.0;

  /// 12.0 dp
  static const double md = 12.0;

  /// 16.0 dp - Standard screen edge padding
  static const double lg = 16.0;

  /// 20.0 dp
  static const double xl = 20.0;

  /// 24.0 dp
  static const double xxl = 24.0;

  /// 32.0 dp
  static const double xxxl = 32.0;

  /// 48.0 dp - Minimum accessible tap target height
  static const double minTouchTarget = 48.0;
}

/// Border radius tokens for cards, buttons, inputs, dialogs, and chips.
class AppRadius {
  AppRadius._();

  /// 4.0 dp
  static const double xs = 4.0;

  /// 8.0 dp
  static const double sm = 8.0;

  /// 12.0 dp - Standard input, card & button radius
  static const double md = 12.0;

  /// 16.0 dp - Modal bottom sheet & dialog radius
  static const double lg = 16.0;

  /// 24.0 dp
  static const double xl = 24.0;

  /// Fully rounded / Pill
  static const double full = 999.0;

  // BorderRadius helpers
  static final BorderRadius roundedXs = BorderRadius.circular(xs);
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedFull = BorderRadius.circular(full);
}
