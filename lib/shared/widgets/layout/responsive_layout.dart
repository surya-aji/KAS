import 'package:flutter/material.dart';

/// Breakpoint constants for responsive layouts.
class AppBreakpoints {
  AppBreakpoints._();

  /// Maximum width for mobile layout (e.g. smartphones).
  static const double mobile = 600.0;

  /// Maximum width for tablet layout.
  static const double tablet = 900.0;
}

/// Helper widget that renders different layouts for mobile vs tablet screens.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
  });

  final Widget mobile;
  final Widget? tablet;

  /// Helper to determine if the current context is running on a tablet-sized screen.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.mobile;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppBreakpoints.mobile && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
