import 'package:flutter/material.dart';

/// Centralized color definitions for the application.
/// Never hardcode colors in widgets — always reference these.
class AppColors {
  AppColors._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);        // Deep Blue
  static const Color primaryLight = Color(0xFF42A5F5);   // Light Blue
  static const Color primaryDark = Color(0xFF0D47A1);    // Dark Blue
  static const Color secondary = Color(0xFFFF8F00);      // Amber/Orange
  static const Color secondaryLight = Color(0xFFFFB300);
  static const Color secondaryDark = Color(0xFFE65100);
  static const Color accent = Color(0xFF00BFA5);         // Teal accent

  // ─── Semantic Colors ───────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFC62828);
  static const Color info = Color(0xFF0277BD);

  // ─── Neutral Colors ───────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ─── Light Theme Surface Colors ────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F2F8);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE8EAF0);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextHint = Color(0xFF9CA3AF);

  // ─── Dark Theme Surface Colors ─────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1123);
  static const Color darkSurface = Color(0xFF1A1D35);
  static const Color darkSurfaceVariant = Color(0xFF242849);
  static const Color darkCard = Color(0xFF1E2140);
  static const Color darkDivider = Color(0xFF2D3154);
  static const Color darkTextPrimary = Color(0xFFF1F3F9);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextHint = Color(0xFF6B7280);

  // ─── Special ───────────────────────────────────────────────────
  static const Color discount = Color(0xFFE53935);
  static const Color inStock = Color(0xFF2E7D32);
  static const Color outOfStock = Color(0xFFC62828);
  static const Color pointsGold = Color(0xFFFFB300);
  static const Color favorite = Color(0xFFE53935);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color darkShimmerBase = Color(0xFF2D3154);
  static const Color darkShimmerHighlight = Color(0xFF3D4170);
}
