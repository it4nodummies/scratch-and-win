import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// A widget that provides different layouts based on screen size.
/// 
/// This widget helps implement responsive design by allowing different
/// widgets to be displayed based on the screen width.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Returns true if the screen width is less than the tablet breakpoint
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppConstants.tabletBreakpoint;

  /// Returns true if the screen width is between tablet and desktop breakpoints
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint &&
      MediaQuery.of(context).size.width < AppConstants.desktopBreakpoint;

  /// Returns true if the screen width is greater than or equal to the desktop breakpoint
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Desktop layout
    if (width >= AppConstants.desktopBreakpoint && desktop != null) {
      return desktop!;
    }
    
    // Tablet layout
    if (width >= AppConstants.tabletBreakpoint && tablet != null) {
      return tablet!;
    }
    
    // Mobile layout (default)
    return mobile;
  }
}

/// Extension on BuildContext to easily access screen dimensions and responsive helpers
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  bool get isMobile => ResponsiveLayout.isMobile(this);
  bool get isTablet => ResponsiveLayout.isTablet(this);
  bool get isDesktop => ResponsiveLayout.isDesktop(this);
  
  /// Returns a value based on the screen size
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
  
  /// Returns a padding value based on the screen size
  EdgeInsets get responsivePadding => responsive<EdgeInsets>(
    mobile: const EdgeInsets.all(16.0),
    tablet: const EdgeInsets.all(24.0),
    desktop: const EdgeInsets.all(32.0),
  );
  
  /// Returns a font size based on the screen size
  double responsiveFontSize(double size) => responsive<double>(
    mobile: size,
    tablet: size * 1.2,
    desktop: size * 1.4,
  );
}