import 'package:flutter/material.dart';

/// Responsive utility class for consistent responsive design across the app
class ResponsiveUtils {
  final BuildContext context;
  late final MediaQueryData _mediaQuery;
  late final double screenWidth;
  late final double screenHeight;
  late final Orientation orientation;
  late final double devicePixelRatio;

  ResponsiveUtils(this.context) {
    _mediaQuery = MediaQuery.of(context);
    screenWidth = _mediaQuery.size.width;
    screenHeight = _mediaQuery.size.height;
    orientation = _mediaQuery.orientation;
    devicePixelRatio = _mediaQuery.devicePixelRatio;
  }

  // Device type checks
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900 && screenWidth < 1200;
  bool get isLargeDesktop => screenWidth >= 1200;
  bool get isDesktopDevice => screenWidth > 800;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  // Responsive dimensions
  double get sidebarWidth => isLargeDesktop ? 280.0 : 250.0;

  double get horizontalPadding => isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

  double get verticalPadding => isMobile ? 16.0 : (isTablet ? 20.0 : 24.0);

  double get spacing => isMobile ? 16.0 : 20.0;

  double get smallSpacing => isMobile ? 8.0 : 12.0;

  double get largeSpacing => isMobile ? 24.0 : 32.0;

  // Font sizes
  double get titleFontSize => isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);

  double get headingFontSize => isMobile ? 18.0 : (isTablet ? 20.0 : 22.0);

  double get bodyFontSize => isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);

  double get captionFontSize => isMobile ? 12.0 : 13.0;

  // Icon sizes
  double get iconSize => isMobile ? 24.0 : 28.0;

  double get smallIconSize => isMobile ? 18.0 : 20.0;

  double get largeIconSize => isMobile ? 32.0 : 40.0;

  // Grid configuration
  int get gridCrossAxisCount => isMobile ? 2 : (isTablet ? 3 : 4);

  double get gridChildAspectRatio => isMobile ? 1.3 : (isTablet ? 1.4 : 1.6);

  double get gridSpacing => isMobile ? 12.0 : 15.0;

  // Button dimensions
  double get buttonHeight => isMobile ? 48.0 : 54.0;

  double get buttonMinWidth => isMobile ? 100.0 : 120.0;

  // Card dimensions
  double get cardBorderRadius => 12.0;

  double get cardElevation => 2.0;

  // Dialog dimensions
  double get dialogMaxWidth =>
      isMobile ? screenWidth * 0.9 : (isTablet ? 500.0 : 600.0);

  // Avatar sizes
  double get avatarRadius => isMobile ? 20.0 : 24.0;

  double get largeAvatarRadius => isMobile ? 40.0 : 50.0;

  // AppBar height
  double get appBarHeight => isMobile ? 56.0 : 64.0;

  // Bottom sheet dimensions
  double get bottomSheetMaxHeight => screenHeight * 0.9;

  // Get responsive value based on screen size
  T responsive<T>({required T mobile, T? tablet, T? desktop, T? largeDesktop}) {
    if (isLargeDesktop && largeDesktop != null) return largeDesktop;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }

  // Get scaled font size based on screen width
  double scaledFontSize(double baseSize) {
    final scaleFactor =
        screenWidth / 375; // 375 is base mobile width (iPhone SE)
    return baseSize * scaleFactor.clamp(0.8, 1.5);
  }

  // Get scaled size based on screen width
  double scaledSize(double baseSize) {
    final scaleFactor = screenWidth / 375;
    return baseSize * scaleFactor.clamp(0.8, 2.0);
  }

  // Safe area insets
  EdgeInsets get safeAreaPadding => _mediaQuery.padding;

  double get safeAreaTop => _mediaQuery.padding.top;

  double get safeAreaBottom => _mediaQuery.padding.bottom;

  // Get number of columns for responsive grids
  int getGridColumns({
    int mobile = 2,
    int? tablet,
    int? desktop,
    int? largeDesktop,
  }) {
    return responsive<int>(
      mobile: mobile,
      tablet: tablet ?? 3,
      desktop: desktop ?? 4,
      largeDesktop: largeDesktop ?? 5,
    );
  }

  // Get responsive padding
  EdgeInsets responsivePadding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    final scale = isMobile ? 1.0 : (isTablet ? 1.25 : 1.5);

    return EdgeInsets.only(
      left: (left ?? horizontal ?? all ?? 0) * scale,
      right: (right ?? horizontal ?? all ?? 0) * scale,
      top: (top ?? vertical ?? all ?? 0) * scale,
      bottom: (bottom ?? vertical ?? all ?? 0) * scale,
    );
  }

  // Check if screen is small (height-wise)
  bool get isShortScreen => screenHeight < 600;

  // Check if keyboard is visible
  bool get isKeyboardVisible => _mediaQuery.viewInsets.bottom > 0;
}

/// Extension on BuildContext for easy access to ResponsiveUtils
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => mediaQuery.size;

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  Orientation get orientation => mediaQuery.orientation;

  bool get isMobile => screenWidth < 600;

  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  bool get isDesktop => screenWidth >= 900;
}
