# Data-Reload-Only Pattern Guide

## Overview
Reloads data without rebuilding the entire widget tree. This improves performance and prevents unnecessary widget reconstructions.

## Pattern Structure

### 1. **Separate Data State from Widget State**
```dart
// Data variables
List<ChatRoom> _allRooms = [];
List<ChatRoom> _filtered = [];
bool _isLoading = true;

// Widget will NOT be rebuilt unless explicitly needed
```

### 2. **Use `didChangeWindowMetrics` or `didUpdateWidget` for Lifecycle**
```dart
@override
void didUpdateWidget(ChatScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  // Only reload data if needed, don't rebuild
  _reloadDataOnly();
}
```

### 3. **Separate Data Loading Methods**
```dart
// RELOAD DATA ONLY - no setState on main build
Future<void> _reloadDataOnly() async {
  // Fetch fresh data
  // Only call setState for data-specific updates
}

// INITIAL LOAD - called once
Future<void> _loadInitial() async {
  setState(() { _isLoading = true; });
  // Load data
}
```

### 4. **Implement In initState and onResume**
```dart
@override
void initState() {
  super.initState();
  _loadInitial();  // Initial load with widget build
  _initSocket();
}

// When user returns to screen (from navigation)
@override
void didChangeWindowMetrics(...) {
  _reloadDataOnly();  // Reload without full rebuild
}
```

## Key Principles

1. **initState**: Full initialization + data load
2. **_reloadDataOnly**: Updates data without setState on build
3. **Socket Listeners**: Auto-update data as it arrives
4. **Minimal setState**: Only when data changes, not on every interaction

## Benefits

✅ Reduced widget rebuilds  
✅ Better performance  
✅ Cleaner state management  
✅ Real-time updates via sockets  

## Implementation Checklist

- [ ] Separate `_loadInitial()` from `_reloadDataOnly()`
- [ ] Move socket listeners to `_initSocket()`
- [ ] Use `didChangeWindowMetrics` for screen resume
- [ ] Only call `setState()` for data changes
- [ ] Test data updates without widget flicker
