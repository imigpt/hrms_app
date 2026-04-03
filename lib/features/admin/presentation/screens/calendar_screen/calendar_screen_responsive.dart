// Responsive utility methods for calendar screen

class ResponsiveCalendar {
  /// Get horizontal padding based on screen size
  static double getHorizontalPadding(bool isMobile, bool isSmallMobile) {
    if (isSmallMobile) return 8;
    if (isMobile) return 12;
    return 16;
  }

  /// Get grid spacing based on screen size  
  static double getGridSpacing(bool isMobile, bool isSmallMobile) {
    if (isSmallMobile) return 4;
    if (isMobile) return 6;
    return 8;
  }

  /// Get calendar font size based on screen size
  static double getCalendarFontSize(bool isSmallMobile) {
    return isSmallMobile ? 11 : 12;
  }

  /// Get card padding based on screen size
  static double getCardPadding(bool isMobile, bool isSmallMobile) {
    if (isSmallMobile) return 8;
    if (isMobile) return 12;
    return 16;
  }

  /// Get FAB size based on screen size
  static double getFABSize(bool isMobile) {
    return isMobile ? 48.0 : 56.0;
  }

  /// Get dialog max width based on screen size
  static double getDialogMaxWidth(bool isMobile, double screenWidth) {
    if (isMobile) {
      return screenWidth * 0.9;
    }
    return 500;
  }
}
