# Responsive Design Implementation Guide

## Overview
The HRMS app now uses **MediaQuery** and a custom **ResponsiveUtils** class to create a fully responsive UI that adapts seamlessly across different screen sizes and devices.

## Architecture

### 1. ResponsiveUtils Class
Location: `lib/utils/responsive_utils.dart`

A comprehensive utility class that provides:
- **Screen dimension detection** via MediaQuery
- **Breakpoint-based device type checks**
- **Adaptive sizing and spacing**
- **Responsive font sizes**
- **Context extensions** for easy access

#### Device Breakpoints
```dart
- Mobile: screenWidth < 600px
- Tablet: 600px ≤ screenWidth < 900px
- Desktop: 900px ≤ screenWidth < 1200px
- Large Desktop: screenWidth ≥ 1200px
```

### 2. Key Features

#### Responsive Dimensions
- **Sidebar width**: 250px (desktop), 280px (large desktop)
- **Horizontal padding**: 16px (mobile), 20px (tablet), 24px (desktop)
- **Vertical spacing**: 16px (mobile), 20px (desktop)
- **Icon sizes**: 24px (mobile), 28px (desktop)
- **Button height**: 48px (mobile), 54px (desktop)

#### Font Scaling
- **Title**: 20px (mobile) → 22px (tablet) → 24px (desktop)
- **Heading**: 18px (mobile) → 20px (tablet) → 22px (desktop)
- **Body**: 14px (mobile) → 15px (tablet) → 16px (desktop)
- **Caption**: 12px (mobile) → 13px (desktop)

#### Grid Configuration
- **Cross axis count**: 2 (mobile), 3 (tablet), 4 (desktop)
- **Child aspect ratio**: 1.3 (mobile), 1.4 (tablet), 1.6 (desktop)
- **Grid spacing**: 12px (mobile), 15px (desktop)

## Usage Examples

### Basic Usage in Screens

```dart
import 'package:hrms_app/utils/responsive_utils.dart';

@override
Widget build(BuildContext context) {
  final responsive = ResponsiveUtils(context);
  
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'My Screen',
        style: TextStyle(fontSize: responsive.titleFontSize),
      ),
    ),
    body: Padding(
      padding: EdgeInsets.all(responsive.horizontalPadding),
      child: Column(
        children: [
          // Adaptive spacing
          SizedBox(height: responsive.spacing),
          
          // Responsive grid
          GridView.count(
            crossAxisCount: responsive.gridCrossAxisCount,
            childAspectRatio: responsive.gridChildAspectRatio,
            children: [...],
          ),
        ],
      ),
    ),
  );
}
```

### Using Context Extension

```dart
@override
Widget build(BuildContext context) {
  // Quick access via extension
  if (context.isMobile) {
    return MobileLayout();
  } else if (context.isTablet) {
    return TabletLayout();
  } else {
    return DesktopLayout();
  }
}
```

### Custom Responsive Values

```dart
final responsive = ResponsiveUtils(context);

// Get different values for each screen size
final columns = responsive.responsive<int>(
  mobile: 1,
  tablet: 2,
  desktop: 3,
  largeDesktop: 4,
);

// Scale font size dynamically
final scaledFont = responsive.scaledFontSize(16.0);

// Scale any dimension
final scaledPadding = responsive.scaledSize(20.0);
```

### Responsive Padding Helper

```dart
final responsive = ResponsiveUtils(context);

Container(
  padding: responsive.responsivePadding(
    horizontal: 16,
    vertical: 8,
  ),
  // Automatically scales: mobile × 1.0, tablet × 1.25, desktop × 1.5
);
```

## Implemented Screens

### ✅ Dashboard Screen
- **File**: `lib/screen/dashboard_screen.dart`
- **Features**:
  - MediaQuery-based breakpoints (mobile/tablet/desktop/large desktop)
  - Responsive sidebar width
  - Adaptive padding and spacing
  - Dynamic grid layout (2/3/4 columns)
  - Responsive font sizes for title, icons
  - Conditional layout (sidebar on desktop, drawer on mobile)

### ✅ Apply Leave Screen  
- **File**: `lib/screen/apply_leave_screen.dart`
- **Features**:
  - Responsive leave balance cards
  - Grid layout on desktop, horizontal scroll on mobile
  - Adaptive button sizing
  - Responsive dropdown and form elements
  - Dynamic font sizes

### ✅ Profile Screen (Enhanced AppBar)
- **File**: `lib/screen/profile_screen.dart`
- **Features**:
  - Responsive AppBar with adaptive icon sizes
  - Dynamic font sizing for title and buttons
  - Adaptive padding
  - Desktop/mobile layout switching

## Best Practices

### 1. Always Use ResponsiveUtils
```dart
// ✅ Good
final responsive = ResponsiveUtils(context);
SizedBox(height: responsive.spacing);

// ❌ Avoid
SizedBox(height: 16); // Fixed value
```

### 2. Leverage Device Type Checks
```dart
// ✅ Good
if (responsive.isDesktopDevice) {
  return SidebarLayout();
} else {
  return DrawerLayout();
}

// ❌ Avoid
if (MediaQuery.of(context).size.width > 800) { ... }
```

### 3. Use Responsive Values Method
```dart
// ✅ Good
final padding = responsive.responsive<double>(
  mobile: 16.0,
  tablet: 20.0,
  desktop: 24.0,
);

// ❌ Avoid
final padding = screenWidth < 600 ? 16.0 : screenWidth < 900 ? 20.0 : 24.0;
```

### 4. Combine LayoutBuilder When Needed
```dart
// For constraint-based layouts
LayoutBuilder(
  builder: (context, constraints) {
    final responsive = ResponsiveUtils(context);
    
    return Container(
      width: constraints.maxWidth * 0.5,
      padding: EdgeInsets.all(responsive.spacing),
    );
  },
)
```

### 5. Use MediaQuery for Special Cases
```dart
final responsive = ResponsiveUtils(context);

// Check orientation
if (responsive.isPortrait) {
  // Portrait-specific layout
}

// Safe area handling
Padding(
  padding: EdgeInsets.only(top: responsive.safeAreaTop),
);

// Keyboard visibility
if (responsive.isKeyboardVisible) {
  // Adjust UI when keyboard is shown
}
```

## Migration Guide

To make an existing screen responsive:

1. **Import ResponsiveUtils**:
   ```dart
   import 'package:hrms_app/utils/responsive_utils.dart';
   ```

2. **Initialize in build method**:
   ```dart
   final responsive = ResponsiveUtils(context);
   ```

3. **Replace fixed dimensions**:
   - Replace `16.0` → `responsive.spacing`
   - Replace `24.0` → `responsive.iconSize`
   - Replace `fontSize: 18` → `fontSize: responsive.headingFontSize`

4. **Add breakpoint logic**:
   ```dart
   if (responsive.isDesktopDevice) {
     // Desktop layout
   } else {
     // Mobile layout
   }
   ```

5. **Update grids**:
   ```dart
   GridView.count(
     crossAxisCount: responsive.gridCrossAxisCount,
     childAspectRatio: responsive.gridChildAspectRatio,
     crossAxisSpacing: responsive.gridSpacing,
     mainAxisSpacing: responsive.gridSpacing,
   )
   ```

## Testing Responsive Layouts

### Flutter DevTools
1. Run app: `flutter run`
2. Open DevTools resize window
3. Test breakpoints: 375px (mobile), 768px (tablet), 1024px (desktop), 1440px (large desktop)

### Common Test Sizes
- **iPhone SE**: 375 × 667 (mobile)
- **iPad**: 768 × 1024 (tablet)
- **iPad Pro**: 1024 × 1366 (large tablet)
- **Desktop Small**: 1280 × 800
- **Desktop Large**: 1920 × 1080

## Performance Considerations

1. **MediaQuery is efficient** - It only rebuilds when screen metrics change
2. **ResponsiveUtils caches values** - Calculations happen once per build
3. **Use const widgets** when possible with fixed responsive values
4. **Avoid excessive nesting** of ResponsiveUtils instantiation

## Future Enhancements

- [ ] Add orientation-specific layouts
- [ ] Implement text scaling based on accessibility settings
- [ ] Add support for foldable devices
- [ ] Create responsive image loading (different resolutions)
- [ ] Add landscape-specific layouts for tablets

## Troubleshooting

### UI doesn't adapt on resize
- Ensure you're not using fixed values
- Check that ResponsiveUtils is initialized in build()
- Verify MediaQuery is accessible in context

### Incorrect breakpoints
- Check screen width calculation
- Ensure proper device emulation in testing
- Verify breakpoint constants in ResponsiveUtils

### Layout overflow
- Use `SafeArea` for notch/status bar
- Add `SingleChildScrollView` for overflow content
- Use `Expanded` or `Flexible` widgets appropriately

## Resources

- [Flutter Responsive Design](https://flutter.dev/docs/development/ui/layout/adaptive-responsive)
- [MediaQuery Documentation](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)
- [LayoutBuilder Documentation](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html)

---

**Last Updated**: January 2025  
**Maintained By**: HRMS Development Team
