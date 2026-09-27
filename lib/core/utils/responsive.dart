import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Responsive utilities for adaptive layouts.
class Responsive {
  Responsive._();

  /// Whether the screen is mobile-sized
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppSpacing.mobileBreakpoint;

  /// Whether the screen is tablet-sized
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppSpacing.mobileBreakpoint &&
        width < AppSpacing.desktopBreakpoint;
  }

  /// Whether the screen is desktop-sized
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppSpacing.desktopBreakpoint;

  /// Get the number of grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppSpacing.desktopBreakpoint) {
      return AppSpacing.desktopGridColumns;
    } else if (width >= AppSpacing.tabletBreakpoint) {
      return AppSpacing.tabletGridColumns;
    } else {
      return AppSpacing.mobileGridColumns;
    }
  }

  /// Get adaptive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return AppSpacing.huge;
    if (isTablet(context)) return AppSpacing.xxl;
    return AppSpacing.lg;
  }

  /// Get the appropriate child aspect ratio for product grids
  static double getProductAspectRatio(BuildContext context) {
    if (isDesktop(context)) return 0.65;
    if (isTablet(context)) return 0.7;
    return 0.72;
  }

  /// Returns a value based on current screen size
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// A responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (Responsive.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}
