import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_text_styles.dart';

/// Centralized theme provider.
/// Use [AppTheme.light] and [AppTheme.dark] throughout the app.
class AppTheme {
  AppTheme._();

  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
}
