# MediaQuery Responsive Design - Quick Reference

## Quick Start

```dart
import 'package:hrms_app/utils/responsive_utils.dart';

@override
Widget build(BuildContext context) {
  final responsive = ResponsiveUtils(context);
  
  return Scaffold(
    appBar: AppBar(
      title: Text('Title', style: TextStyle(fontSize: responsive.titleFontSize)),
    ),
    body: Padding(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: YourContent(),
    ),
  );
}
```

## Common Properties

### Device Type Checks
```dart
responsive.isMobile           // < 600px
responsive.isTablet           // 600px - 900px  
responsive.isDesktop          // 900px - 1200px
responsive.isLargeDesktop     // >= 1200px
responsive.isDesktopDevice    // > 800px
responsive.isPortrait         // Portrait orientation
responsive.isLandscape        // Landscape orientation
```

### Dimensions
```dart
responsive.screenWidth        // Current screen width
responsive.screenHeight       // Current screen height
responsive.sidebarWidth       // 250px or 280px
responsive.spacing            // 16px or 20px
responsive.smallSpacing       // 8px or 12px
responsive.largeSpacing       // 24px or 32px
```

### Padding
```dart
responsive.horizontalPadding  // 16/20/24px
responsive.verticalPadding    // 16/20/24px
responsive.safeAreaTop        // Top safe area
responsive.safeAreaBottom     // Bottom safe area
```

### Font Sizes
```dart
responsive.titleFontSize      // 20/22/24px
responsive.headingFontSize    // 18/20/22px
responsive.bodyFontSize       // 14/15/16px
responsive.captionFontSize    // 12/13px
```

### Icon Sizes
```dart
responsive.iconSize           // 24/28px
responsive.smallIconSize      // 18/20px
responsive.largeIconSize      // 32/40px
```

### Grid
```dart
responsive.gridCrossAxisCount   // 2/3/4
responsive.gridChildAspectRatio // 1.3/1.4/1.6
responsive.gridSpacing          // 12/15px
```

### Buttons & Cards
```dart
responsive.buttonHeight       // 48/54px
responsive.buttonMinWidth     // 100/120px
responsive.cardBorderRadius   // 12px
responsive.cardElevation      // 2px
```

## Helper Methods

### Responsive Values
```dart
final value = responsive.responsive<T>(
  mobile: mobileValue,
  tablet: tabletValue,      // optional
  desktop: desktopValue,    // optional
  largeDesktop: ldValue,    // optional
);
```

### Scaled Sizes
```dart
responsive.scaledFontSize(16.0)  // Auto-scaled based on screen
responsive.scaledSize(20.0)       // Auto-scaled dimension
```

### Grid Columns
```dart
responsive.getGridColumns(
  mobile: 2,
  tablet: 3,
  desktop: 4,
  largeDesktop: 5,
)
```

### Responsive Padding
```dart
responsive.responsivePadding(
  all: 16.0,              // All sides
  horizontal: 20.0,       // Left + right
  vertical: 10.0,         // Top + bottom 
  left: 8.0,              // Individual sides
  right: 8.0,
  top: 4.0,
  bottom: 4.0,
)
// Auto-scales: mobile ×1.0, tablet ×1.25, desktop ×1.5
```

## Context Extensions

```dart
context.isMobile              // Same as responsive.isMobile
context.isTablet              // Same as responsive.isTablet
context.isDesktop             // Same as responsive.isDesktop
context.screenWidth           // Quick screen width
context.screenHeight          // Quick screen height
context.orientation           // Portrait or landscape
```

## Common Patterns

### Conditional Layout
```dart
responsive.isDesktopDevice
  ? DesktopLayout()
  : MobileLayout()
```

### Responsive Padding
```dart
Padding(
  padding: EdgeInsets.all(responsive.horizontalPadding),
  child: ...
)
```

### Responsive Text
```dart
Text(
  'Hello',
  style: TextStyle(fontSize: responsive.headingFontSize),
)
```

### Responsive Grid
```dart
GridView.count(
  crossAxisCount: responsive.gridCrossAxisCount,
  childAspectRatio: responsive.gridChildAspectRatio,
  crossAxisSpacing: responsive.gridSpacing,
  mainAxisSpacing: responsive.gridSpacing,
  children: [...],
)
```

### Responsive Sizing
```dart
Container(
  width: responsive.scaledSize(200),
  height: responsive.scaledSize(100),
  padding: EdgeInsets.all(responsive.spacing),
)
```

### Safe Area
```dart
Padding(
  padding: EdgeInsets.only(
    top: responsive.safeAreaTop,
    bottom: responsive.safeAreaBottom,
  ),
  child: ...
)
```

### Keyboard Check
```dart
if (responsive.isKeyboardVisible) {
  // Adjust UI for keyboard
}
```

## Breakpoint Reference

| Breakpoint | Width Range | Device Examples |
|------------|-------------|-----------------|
| Mobile | < 600px | iPhone, small Android |
| Tablet | 600px - 900px | iPad, Android tablets |
| Desktop | 900px - 1200px | Small laptops |
| Large Desktop | ≥ 1200px | Desktop monitors |

## Testing Sizes

```dart
// Common test dimensions
- Mobile:  375 × 667  (iPhone SE)
- Mobile:  414 × 896  (iPhone 11)
- Tablet:  768 × 1024 (iPad)
- Desktop: 1280 × 800 (Laptop)
- Desktop: 1920 × 1080 (Full HD)
```

## Migration Checklist

- [ ] Import `responsive_utils.dart`
- [ ] Initialize `ResponsiveUtils(context)`
- [ ] Replace `16` → `responsive.spacing`
- [ ] Replace `fontSize: 18` → `fontSize: responsive.headingFontSize`
- [ ] Replace `size: 24` → `size: responsive.iconSize`
- [ ] Add breakpoint logic for layouts
- [ ] Update grids to use responsive values
- [ ] Test on multiple screen sizes

## Performance Tips

✅ **Good:**
```dart
final responsive = ResponsiveUtils(context);
// Use responsive multiple times
```

❌ **Avoid:**
```dart
// Creating multiple instances
ResponsiveUtils(context).spacing
ResponsiveUtils(context).iconSize
```

---

**Quick Tip**: Use `context.responsive` for one-time access, or store `ResponsiveUtils(context)` in a variable for multiple uses.
