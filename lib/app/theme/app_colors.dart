import 'package:flutter/material.dart';

/// Centralized color tokens for the Kas Usaha application.
///
/// Designed with high contrast, accessibility, and visual clarity
/// suited for retail, grocery, cafe, and service POS workflows.
class AppColors {
  AppColors._();

  // ── Primary Brand Palette (Emerald Commerce) ────────────────────
  /// Main brand color representing commerce, cash flow, and financial health.
  static const Color primary50 = Color(0xFFE8F7EE);
  static const Color primary100 = Color(0xFFC7ECDA);
  static const Color primary200 = Color(0xFF91D8B7);
  static const Color primary300 = Color(0xFF53C090);
  static const Color primary400 = Color(0xFF28A76F);
  static const Color primary500 = Color(0xFF137547); // Core primary
  static const Color primary600 = Color(0xFF0F5E39);
  static const Color primary700 = Color(0xFF0E4C2F);
  static const Color primary800 = Color(0xFF0D3D27);
  static const Color primary900 = Color(0xFF0B3322);

  // ── Secondary / Slate Accent ───────────────────────────────────
  static const Color secondary50 = Color(0xFFF0F7FA);
  static const Color secondary100 = Color(0xFFDCEEF4);
  static const Color secondary500 = Color(0xFF1E5E7A);
  static const Color secondary600 = Color(0xFF174A61);

  // ── Semantic Colors ────────────────────────────────────────────
  /// Success: Completed transactions, cash in, sufficient stock.
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF15803D);

  /// Warning: Low stock alerts, draft sessions, pending payments.
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);

  /// Error / Danger: Voided transactions, cash out, delete actions.
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFB91C1C);

  /// Info: Bluetooth printer status, general guides, logs.
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);

  // ── Neutrals / Surfaces (Light Mode) ───────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // ── Neutrals / Surfaces (Dark Mode) ────────────────────────────
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);
}
