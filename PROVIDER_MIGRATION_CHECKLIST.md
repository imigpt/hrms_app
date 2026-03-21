# Provider Migration Quick Reference Guide

**Purpose:** Fast lookup for migrating modules to Provider pattern  
**Generated:** March 21, 2026

---

## 🎯 Quick Status Overview

```
✅ USING PROVIDER (2/14 modules)
  └─ Auth
  └─ Dashboard

❌ NEEDS MIGRATION (12/14 modules)
  ├─ Admin
  ├─ Announcements
  ├─ Attendance
  ├─ Chat
  ├─ Expenses
  ├─ Leave
  ├─ Notifications
  ├─ Payroll
  ├─ Policies
  ├─ Profile
  ├─ Settings
  └─ Tasks
```

---

## 📋 Module-by-Module Checklist

### ✅ AUTH MODULE
**Status:** COMPLETE  
**Pattern:** ChangeNotifier + Consumer

**Screens:**
- ✅ LoginScreen - Using Consumer<AuthNotifier>
- ✅ AuthCheckScreen - Using Consumer<AuthNotifier>
- ⏳ ForgotPasswordScreen - Still StatefulWidget (PENDING)

**Files to Reference:**
- `lib/features/auth/presentation/providers/auth_notifier.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`

---

### ✅ DASHBOARD MODULE
**Status:** INTEGRATED  
**Pattern:** Consumer (reads global auth state)

**Screens:**
- ✅ DashboardScreen - Using Consumer<AuthNotifier>

**Files to Reference:**
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

---

### ❌ ADMIN MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget + TickerProviderStateMixin

**Files to Migrate:**
```
lib/features/admin/presentation/screens/
├── admin_attendance_screen.dart
├── edit_requests_screen.dart
├── clients/
├── company_settings/
├── employee_management/
└── hrm_settings/
```

**State Variables to Extract:**
- Multiple admin data management states
- Request editing states
- Navigation states

**Migration Steps:**
1. [ ] Create `admin_notifier.dart`
2. [ ] Create `AdminNotifier extends ChangeNotifier`
3. [ ] Create `admin_providers.dart` file
4. [ ] Convert screens to ConsumerStatefulWidget (keep TickerProvider)
5. [ ] Update main.dart to add AdminNotifier to MultiProvider
6. [ ] Test all admin screens
7. [ ] Update imports in all screens

**Created Notifier Template:**
```dart
// lib/features/admin/presentation/providers/admin_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

class AdminState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> items;
  
  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
  });
  
  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? items,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      items: items ?? this.items,
    );
  }
  
  @override
  List<Object?> get props => [isLoading, errorMessage, items];
}

class AdminNotifier extends ChangeNotifier {
  AdminState _state = const AdminState();
  AdminState get state => _state;
  
  void _setState(AdminState newState) {
    _state = newState;
    notifyListeners();
  }
}
```

---

### ❌ ANNOUNCEMENTS MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget

**Files to Migrate:**
```
lib/features/announcements/presentation/screens/
├── announcements_screen.dart
└── announcement_detail_screen.dart
```

**State Variables to Extract:**
- `_allAnnouncements`
- `_isLoading`
- `_error`
- `_selectedFilter`
- `_currentUserId`
- `_authToken`

**Migration Steps:**
1. [ ] Create `announcement_notifier.dart`
2. [ ] Create `AnnouncementNotifier extends ChangeNotifier`
3. [ ] Create `announcement_providers.dart`
4. [ ] Convert AnnouncementsScreen to ConsumerWidget
5. [ ] Convert AnnouncementDetailScreen to ConsumerWidget
6. [ ] Add provider to main.dart MultiProvider
7. [ ] Test filtering, loading, error states

**Created Notifier Template:**
```dart
// lib/features/announcements/presentation/providers/announcement_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:hrms_app/features/announcements/data/models/announcement_model.dart';
import 'package:hrms_app/features/announcements/data/services/announcement_service.dart';

class AnnouncementState extends Equatable {
  final List<Announcement> announcements;
  final bool isLoading;
  final String? errorMessage;
  final String selectedFilter;
  
  const AnnouncementState({
    this.announcements = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter = 'All',
  });
  
  AnnouncementState copyWith({
    List<Announcement>? announcements,
    bool? isLoading,
    String? errorMessage,
    String? selectedFilter,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
  
  @override
  List<Object?> get props => [announcements, isLoading, errorMessage, selectedFilter];
}

class AnnouncementNotifier extends ChangeNotifier {
  final AnnouncementService _service;
  
  AnnouncementState _state = const AnnouncementState();
  AnnouncementState get state => _state;
  
  AnnouncementNotifier(this._service);
  
  void _setState(AnnouncementState newState) {
    _state = newState;
    notifyListeners();
  }
  
  Future<void> loadAnnouncements() async {
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final announcements = await _service.getAnnouncements();
      _setState(_state.copyWith(
        announcements: announcements,
        isLoading: false,
      ));
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
  
  void setFilter(String filter) {
    _setState(_state.copyWith(selectedFilter: filter));
  }
}
```

---

### ❌ ATTENDANCE MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget + TickerProviderStateMixin

**Files to Migrate:**
```
lib/features/attendance/presentation/screens/
├── attendance_screen.dart
├── attendance_history_screen.dart
├── admin_attendance_screen.dart
├── camera_screen.dart
└── checkout_photo_screen.dart
```

**State Variables to Extract:**
- Attendance records list
- Check-in/check-out state
- Camera state
- Loading states
- Filter/date selection

**Migration Steps:**
1. [ ] Create `attendance_notifier.dart`
2. [ ] Create `AttendanceNotifier extends ChangeNotifier`
3. [ ] Create separate notifier for camera if needed
4. [ ] Convert all screens to ConsumerStatefulWidget (keep TickerProvider)
5. [ ] Add to main.dart MultiProvider
6. [ ] Test attendance flow with camera
7. [ ] Test attendance history
8. [ ] Test admin attendance view

---

### ❌ CHAT MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget + TickerProviderStateMixin

**Files to Migrate:**
```
lib/features/chat/presentation/screens/
└── chat_screen.dart
```

**State Variables to Extract:**
- Messages list
- Current chat user/conversation
- Loading states
- Message input state
- Typing indicators

**Migration Steps:**
1. [ ] Create `chat_notifier.dart`
2. [ ] Create `ChatNotifier extends ChangeNotifier`
3. [ ] Keep local TextEditingController for message input
4. [ ] Convert ChatScreen to ConsumerStatefulWidget (keep TickerProvider for animations)
5. [ ] Add to main.dart MultiProvider
6. [ ] Test real-time messaging
7. [ ] Test message history

**Key Consideration:** Keep local state for message input controller, extract conversation/message management to Provider

---

### ❌ EXPENSES MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget

**Files to Migrate:**
```
lib/features/expenses/presentation/screens/
└── expenses_screen.dart
```

**State Variables to Extract:**
- Expenses list
- Filters
- Sorting
- Loading state
- Error state

**Migration Steps:**
1. [ ] Create `expense_notifier.dart`
2. [ ] Create `ExpenseNotifier extends ChangeNotifier`
3. [ ] Convert ExpensesScreen to ConsumerWidget
4. [ ] Add to main.dart MultiProvider
5. [ ] Test expense loading
6. [ ] Test filtering and sorting

---

### ❌ LEAVE MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget + TickerProviderStateMixin

**Files to Migrate:**
```
lib/features/leave/presentation/screens/
├── leave_management_screen.dart
├── leave_balance_screen.dart
└── apply_leave_screen.dart
```

**State Variables to Extract:**
- Leave applications list
- Leave balance
- Leave type selection
- Date range selection
- Status filters

**Migration Steps:**
1. [ ] Create `leave_notifier.dart`
2. [ ] Create `LeaveNotifier extends ChangeNotifier`
3. [ ] Create separate balance notifier if needed
4. [ ] Convert screens to ConsumerStatefulWidget (keep TickerProvider)
5. [ ] Add to main.dart MultiProvider
6. [ ] Test leave application flow
7. [ ] Test leave balance calculation

**Complexity:** HIGH - Multi-step workflow

---

### ❌ NOTIFICATIONS MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget

**Files to Migrate:**
```
lib/features/notifications/presentation/screens/
└── notifications_screen.dart
```

**State Variables to Extract:**
- Notifications list (from multiple services)
- Filters by type
- Read/unread state
- Loading and error states

**Migration Steps:**
1. [ ] Create `notification_notifier.dart`
2. [ ] Create `NotificationNotifier extends ChangeNotifier`
3. [ ] Consolidate notifications from multiple services
4. [ ] Convert NotificationsScreen to ConsumerWidget
5. [ ] Add to main.dart MultiProvider
6. [ ] Test notification filtering
7. [ ] Test mark as read/unread

**Complexity:** MEDIUM - Aggregates from multiple services

---

### ❌ PAYROLL MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget + TickerProviderStateMixin

**Files to Migrate:**
```
lib/features/payroll/presentation/screens/
├── payroll_screen.dart
├── admin_salary_screen.dart
├── my_salary_screen.dart
└── pre_payments_screen.dart
```

**State Variables to Extract:**
- Salary data
- Month selection
- Filter selections
- Loading states
- Error handling

**Migration Steps:**
1. [ ] Create `payroll_notifier.dart`
2. [ ] Create `PayrollNotifier extends ChangeNotifier`
3. [ ] Convert all screens to ConsumerWidget/ConsumerStatefulWidget
4. [ ] Add to main.dart MultiProvider
5. [ ] Test salary data loading
6. [ ] Test month filtering
7. [ ] Test pre-payment features

**Complexity:** HIGH - Sensitive financial data

---

### ❌ POLICIES MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget

**Files to Migrate:**
```
lib/features/policies/presentation/screens/
└── policies_screen.dart
```

**State Variables to Extract:**
- Policies list
- Search query
- Filter selections
- Loading state

**Migration Steps:**
1. [ ] Create `policy_notifier.dart`
2. [ ] Create `PolicyNotifier extends ChangeNotifier`
3. [ ] Convert PoliciesScreen to ConsumerWidget
4. [ ] Add to main.dart MultiProvider
5. [ ] Test policy loading
6. [ ] Test search/filter functionality

---

### ❌ PROFILE MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget

**Files to Migrate:**
```
lib/features/profile/presentation/screens/
└── profile_screen.dart
```

**State Variables to Extract:**
- User profile data
- Edit mode toggle
- Saving state
- Form field states

**Migration Steps:**
1. [ ] Create `profile_notifier.dart`
2. [ ] Create `ProfileNotifier extends ChangeNotifier`
3. [ ] Convert ProfileScreen to ConsumerWidget
4. [ ] Keep TextEditingControllers as local state (form fields)
5. [ ] Add to main.dart MultiProvider
6. [ ] Test profile loading
7. [ ] Test profile editing and saving

**Keep as Local State:** TextEditingControllers, form field values

---

### ❌ SETTINGS MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget

**Files to Migrate:**
```
lib/features/settings/presentation/screens/
├── settings_screen.dart
└── location_settings_screen.dart
```

**State Variables to Extract:**
- Settings/preferences
- Location settings
- Loading states

**Migration Steps:**
1. [ ] Create `settings_notifier.dart`
2. [ ] Create `SettingsNotifier extends ChangeNotifier`
3. [ ] Convert screens to ConsumerWidget
4. [ ] Add to main.dart MultiProvider
5. [ ] Test settings changes
6. [ ] Test location settings

**Note:** Some local UI state (toggles, etc.) can remain local

---

### ❌ TASKS MODULE
**Status:** NOT MIGRATED  
**Current Pattern:** StatefulWidget + SingleTickerProviderStateMixin

**Files to Migrate:**
```
lib/features/tasks/presentation/screens/
├── tasks_screen.dart
└── task_detail_sheet.dart
```

**State Variables to Extract:**
- Tasks list
- Task filters
- Task details
- Status updates

**Migration Steps:**
1. [ ] Create `task_notifier.dart`
2. [ ] Create `TaskNotifier extends ChangeNotifier`
3. [ ] Convert TasksScreen to ConsumerWidget
4. [ ] Convert TaskDetailSheet to ConsumerWidget (keep TickerProvider if needed)
5. [ ] Add to main.dart MultiProvider
6. [ ] Test task loading
7. [ ] Test task status updates

---

## 🔄 Migration Workflow

### Step-by-Step for Each Module:

#### 1. Create Notifier File
```dart
// lib/features/[module]/presentation/providers/[module]_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

class [Module]State extends Equatable {
  // Copy state variables here
  @override
  List<Object?> get props => [];
}

class [Module]Notifier extends ChangeNotifier {
  [Module]State _state = const [Module]State();
  [Module]State get state => _state;
  
  void _setState([Module]State newState) {
    _state = newState;
    notifyListeners();
  }
}
```

#### 2. Create Providers File (Optional but recommended)
```dart
// lib/features/[module]/presentation/providers/[module]_providers.dart
import 'package:provider/provider.dart';
import '[module]_notifier.dart';

final [module]NotifierProvider = ChangeNotifierProvider<[Module]Notifier>(
  (ref) => [Module]Notifier(),
);
```

#### 3. Update Screens
```dart
// Before: StatefulWidget
class MyScreen extends StatefulWidget { ... }

// After: ConsumerWidget
import 'package:provider/provider.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch([module]NotifierProvider);
    final notifier = ref.read([module]NotifierProvider);
    // Use state and notifier
  }
}

// Or for animation-heavy screens
class MyScreen extends ConsumerStatefulWidget { ... }
class _MyScreenState extends ConsumerState<MyScreen> 
    with TickerProviderStateMixin { ... }
```

#### 4. Update main.dart
```dart
// Add to MultiProvider list
ChangeNotifierProvider<[Module]Notifier>(
  create: (_) => [Module]Notifier(),
),
```

#### 5. Test Thoroughly
- [ ] Load data
- [ ] Handle errors
- [ ] Check UI updates
- [ ] Verify state persistence
- [ ] Test navigation

---

## 🎨 State Structure Template

For any module notifier, follow this structure:

```dart
class [Module]State extends Equatable {
  final List<dynamic> items;           // Main data
  final bool isLoading;                // Loading indicator
  final String? errorMessage;          // Error state
  final bool isInitialized;            // First load flag
  final String? selectedFilter;        // Filter state
  final String sortBy;                 // Sort preference
  final int pageNumber;                // Pagination (if needed)
  
  const [Module]State({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
    this.selectedFilter,
    this.sortBy = 'default',
    this.pageNumber = 1,
  });
  
  [Module]State copyWith({
    List<dynamic>? items,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    String? selectedFilter,
    String? sortBy,
    int? pageNumber,
  }) {
    return [Module]State(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isInitialized: isInitialized ?? this.isInitialized,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      sortBy: sortBy ?? this.sortBy,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }
  
  @override
  List<Object?> get props => [
    items,
    isLoading,
    errorMessage,
    isInitialized,
    selectedFilter,
    sortBy,
    pageNumber,
  ];
}

class [Module]Notifier extends ChangeNotifier {
  final [Module]Service _service;
  
  [Module]State _state = const [Module]State();
  [Module]State get state => _state;
  
  [Module]Notifier(this._service);
  
  void _setState([Module]State newState) {
    _state = newState;
    notifyListeners();
  }
  
  Future<void> loadItems() async {
    if (_state.isInitialized) return;
    _setState(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _service.getItems();
      _setState(_state.copyWith(
        items: items,
        isLoading: false,
        isInitialized: true,
      ));
    } catch (e) {
      _setState(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
```

---

## ✨ Tips & Best Practices

✅ **DO:**
- Keep form fields as local state (TextEditingController)
- Use copyWith for immutable state updates
- Make Notifier methods async-aware
- Clear errors after user interaction
- Initialize data on first screen load
- Test Provider integration after migration

❌ **DON'T:**
- Don't put TextEditingController in Provider state
- Don't mutate state directly (use copyWith)
- Don't create new Notifier instances unnecessarily
- Don't forget to dispose resources
- Don't mix Provider with GetX or other state managers
- Don't put animations in Provider state

---

## 📚 Reference Links

- **Provider Package:** https://pub.dev/packages/provider
- **Auth Implementation:** `lib/features/auth/presentation/providers/auth_notifier.dart`
- **Main Setup:** `lib/main.dart` - MultiProvider wrapper
- **Equatable:** `https://pub.dev/packages/equatable`

---

**Last Updated:** March 21, 2026  
**Version:** 1.0
