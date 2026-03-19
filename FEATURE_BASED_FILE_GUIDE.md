# HRMS App - Feature-Based File Organization Guide

## 🎯 Understanding the File Structure Through Features

This guide helps you understand where every file belongs by looking at complete feature workflows.

---

## 📋 COMPLETE FEATURE EXAMPLES

### Example 1: ATTENDANCE FEATURE (Check-in/Checkout)

#### Files Involved (Old Structure)
```
lib/
├── screen/
│   ├── attendance_screen.dart          [Main attendance UI]
│   ├── attendance_history_screen.dart  [History list]
│   └── checkout_photo_screen.dart      [Photo verification]
├── models/
│   ├── attendance_checkin_model.dart   [Check-in data]
│   ├── attendance_checkout_model.dart  [Check-out data]
│   ├── attendance_history_model.dart   [History data]
│   ├── attendance_edit_request_model.dart [Edit request data]
│   ├── attendance_records_model.dart   [Records data]
│   └── attendance_summary_model.dart   [Summary data]
├── services/
│   ├── attendance_service.dart         [API calls]
│   ├── location_update_service.dart    [Location tracking]
│   ├── location_utility_service.dart   [Location helpers]
│   └── face_verification_service.dart  [Face recognition]
├── widgets/
│   ├── attendance_edit_request_dialog.dart
│   ├── attendance_edit_requests_card.dart
│   ├── attendance_statistics_section.dart
│   └── location_permission_dialog.dart
├── utils/
│   ├── location_update_mixin.dart
│   └── responsive_utils.dart
└── theme/
    └── app_theme.dart [Uses app_theme for styling]
```

**Problem**: Files scattered across 6 directories! 🔴

#### Files (New Structure - Target)
```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart [Location radius, update intervals]
│   └── utils/
│       └── location_utils.dart [Location helpers]
│
├── features/attendance/
│   ├── data/
│   │   ├── models/
│   │   │   ├── attendance_checkin_model.dart
│   │   │   ├── attendance_checkout_model.dart
│   │   │   ├── attendance_history_model.dart
│   │   │   ├── attendance_edit_request_model.dart
│   │   │   ├── attendance_records_model.dart
│   │   │   └── attendance_summary_model.dart
│   │   ├── repositories/
│   │   │   └── attendance_repository.dart [API calls wrapper]
│   │   └── services/
│   │       └── attendance_service.dart [Direct API calls]
│   │
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── attendance_screen.dart [Main UI]
│   │   │   ├── attendance_history_screen.dart [History]
│   │   │   └── checkout_photo_screen.dart [Photo]
│   │   ├── widgets/
│   │   │   ├── attendance_edit_request_dialog.dart
│   │   │   ├── attendance_edit_requests_card.dart
│   │   │   └── attendance_statistics_section.dart
│   │   └── providers/
│   │       └── attendance_provider.dart [State management]
│   │
│   └── domain/
│       ├── entities/
│       │   └── attendance_entity.dart [Core entity]
│       ├── repositories/
│       │   └── attendance_repository.dart [Interface]
│       └── usecases/
│           └── check_in_usecase.dart [Business logic]
│
├── shared/
│   ├── services/device/
│   │   ├── location_service.dart [Device location access]
│   │   ├── camera_service.dart [Camera access]
│   │   └── permission_service.dart [Permission requests]
│   │
│   ├── services/external/
│   │   ├── face_verification_service.dart [Face recognition]
│   │   └── firebase_service.dart [Firebase]
│   │
│   └── widgets/common/
│       ├── location_permission_dialog.dart
│       └── permission_request_dialog.dart
│
└── core/constants/
    └── route_constants.dart [Contains Route.attendance]
```

**Solution**: Everything attendance is in one feature folder! ✅

#### Code Flow Understanding
```
1. User taps "Check-in" button
   └─> attendance_screen.dart (PRESENTATION)

2. Screen calls check-in method
   └─> attendance_provider.dart (STATE MANAGEMENT)

3. Provider calls usecase
   └─> check_in_usecase.dart (DOMAIN)

4. Usecase calls repository
   └─> attendance_repository.dart (DATA)

5. Repository calls service
   └─> attendance_service.dart (DATA)

6. Service makes API call
   └─> Returns AttendanceCheckInModel

7. Result updates UI
   └─> State updates, screen rebuilds
```

---

### Example 2: LEAVE MANAGEMENT FEATURE

#### Files (New Structure - Target)
```
lib/features/leave/

├── data/
│   ├── models/
│   │   ├── leave_model.dart
│   │   ├── leave_balance_model.dart
│   │   ├── apply_leave_model.dart
│   │   └── leave_management_model.dart
│   ├── repositories/
│   │   └── leave_repository.dart
│   └── services/
│       └── leave_service.dart
│
├── presentation/
│   ├── screens/
│   │   ├── leave_management_screen.dart [Main screen]
│   │   └── leave_balance_screen.dart [Balance view]
│   ├── widgets/
│   │   ├── leave_application_form.dart
│   │   ├── leave_balance_card.dart
│   │   └── leave_history_list.dart
│   └── providers/
│       └── leave_provider.dart
│
└── domain/
    ├── entities/
    │   └── leave_entity.dart
    ├── repositories/
    │   └── leave_repository.dart
    └── usecases/
        ├── apply_leave_usecase.dart
        ├── fetch_leave_balance_usecase.dart
        └── cancel_leave_usecase.dart
```

---

### Example 3: CHAT FEATURE

#### Files (New Structure - Target)
```
lib/features/chat/

├── data/
│   ├── models/
│   │   ├── chat_message_model.dart
│   │   ├── chat_room_model.dart
│   │   └── chat_media_model.dart
│   ├── repositories/
│   │   └── chat_repository.dart
│   └── services/
│       └── chat_service.dart
│
├── presentation/
│   ├── screens/
│   │   ├── chat_screen.dart [Main chat]
│   │   ├── chat_list_screen.dart [List of chats]
│   │   └── chat_media_screen.dart [Media view]
│   ├── widgets/
│   │   ├── chat_message_bubble.dart
│   │   ├── chat_input_field.dart
│   │   └── chat_media_preview.dart
│   └── providers/
│       └── chat_provider.dart
│
└── domain/
    ├── entities/
    │   └── chat_entity.dart
    ├── repositories/
    │   └── chat_repository.dart
    └── usecases/
        ├── send_message_usecase.dart
        ├── fetch_messages_usecase.dart
        └── upload_media_usecase.dart
```

#### Shared Services Used
```
lib/shared/services/
├── communication/
│   ├── socket_service.dart [Real-time updates via WebSocket]
│   ├── notification_service.dart [Push notifications]
│   └── chat_socket_service.dart [Chat-specific socket]
│
└── external/
    └── firebase_service.dart [FCM for notifications]
```

---

### Example 4: ADMIN SETTINGS FEATURE

#### Files (New Structure - Target)
```
lib/features/admin/

├── data/
│   ├── models/
│   │   ├── company_settings_model.dart
│   │   ├── employee_settings_model.dart
│   │   ├── payroll_settings_model.dart
│   │   ├── email_settings_model.dart
│   │   ├── location_settings_model.dart
│   │   ├── role_permission_model.dart
│   │   ├── storage_settings_model.dart
│   │   ├── currency_model.dart
│   │   ├── translation_model.dart
│   │   ├── pdf_font_model.dart
│   │   ├── work_status_model.dart
│   │   └── hrm_settings_model.dart
│   ├── repositories/
│   │   ├── admin_repository.dart
│   │   ├── employee_repository.dart
│   │   ├── settings_repository.dart
│   │   └── reports_repository.dart
│   └── services/
│       ├── admin_service.dart
│       ├── employee_service.dart
│       ├── settings_service.dart
│       ├── reports_service.dart
│       └── admin_clients_service.dart
│
├── presentation/
│   ├── screens/
│   │   ├── admin_dashboard_screen.dart [Main dashboard]
│   │   │
│   │   ├── employee_management/
│   │   │   ├── employee_list_screen.dart
│   │   │   ├── employee_details_screen.dart
│   │   │   ├── employee_add_screen.dart
│   │   │   └── employee_import_screen.dart
│   │   │
│   │   ├── company_settings/
│   │   │   ├── company_settings_screen.dart
│   │   │   ├── location_settings_screen.dart
│   │   │   └── currency_settings_screen.dart
│   │   │
│   │   ├── hrm_settings/
│   │   │   ├── payroll_settings_screen.dart
│   │   │   ├── email_settings_screen.dart
│   │   │   ├── hrm_settings_screen.dart
│   │   │   ├── employee_id_settings_screen.dart
│   │   │   ├── storage_settings_screen.dart
│   │   │   ├── roles_permissions_screen.dart
│   │   │   ├── translations_screen.dart
│   │   │   ├── pdf_fonts_screen.dart
│   │   │   ├── work_status_screen.dart
│   │   │   └── user_credentials_screen.dart
│   │   │
│   │   └── reports/
│   │       ├── attendance_reports_screen.dart
│   │       ├── leave_reports_screen.dart
│   │       ├── payroll_reports_screen.dart
│   │       ├── expense_reports_screen.dart
│   │       └── task_reports_screen.dart
│   │
│   ├── widgets/
│   │   ├── admin_stat_card.dart
│   │   ├── settings_section.dart
│   │   ├── settings_toggle.dart
│   │   ├── employee_table.dart
│   │   ├── report_chart.dart
│   │   └── [Feature-specific widgets]
│   │
│   └── providers/
│       ├── admin_provider.dart
│       ├── employee_provider.dart
│       ├── settings_provider.dart
│       └── reports_provider.dart
│
└── domain/
    ├── entities/
    │   ├── admin_entity.dart
    │   ├── employee_entity.dart
    │   ├── settings_entity.dart
    │   └── report_entity.dart
    ├── repositories/
    │   └── [Repository interfaces]
    └── usecases/
        ├── fetch_employees_usecase.dart
        ├── update_settings_usecase.dart
        ├── generate_reports_usecase.dart
        └── [More usecases]
```

---

## 📊 DECISION TREE: WHERE DOES CODE GO?

```
START: I'm adding/modifying code
│
├─ Is it a SCREEN/PAGE?
│  └─ YES → lib/features/[feature]/presentation/screens/
│
├─ Is it a data MODEL (API response)?
│  └─ YES → lib/features/[feature]/data/models/
│
├─ Is it an API SERVICE CALL?
│  └─ YES → lib/features/[feature]/data/services/
│
├─ Is it a WIDGET (small UI component)?
│  ├─ Is it feature-specific?
│  │  └─ YES → lib/features/[feature]/presentation/widgets/
│  └─ Is it reusable across features?
│     └─ YES → lib/shared/widgets/{common|cards|forms}/
│
├─ Is it STATE MANAGEMENT (Provider/Bloc)?
│  └─ YES → lib/features/[feature]/presentation/providers/
│
├─ Is it BUSINESS LOGIC (UseCase)?
│  └─ YES → lib/features/[feature]/domain/usecases/
│
├─ Is it a SHARED SERVICE?
│  ├─ Location, Camera, Permission?
│  │  └─ lib/shared/services/device/
│  ├─ Notifications, Chat, WebSocket?
│  │  └─ lib/shared/services/communication/
│  ├─ API Client, Storage, Cache?
│  │  └─ lib/shared/services/core/
│  ├─ Firebase, Analytics, Crash?
│  │  └─ lib/shared/services/external/
│
├─ Is it a CONFIGURATION/CONSTANT?
│  ├─ API endpoints?
│  │  └─ lib/core/config/api_config.dart
│  ├─ App settings?
│  │  └─ lib/core/config/app_config.dart
│  ├─ Routes?
│  │  └─ lib/core/constants/route_constants.dart
│  ├─ General constants?
│  │  └─ lib/core/constants/app_constants.dart
│  ├─ Assets (images, icons)?
│  │  └─ lib/core/constants/asset_constants.dart
│
├─ Is it a UTILITY FUNCTION?
│  ├─ Data validation?
│  │  └─ lib/core/utils/validators.dart
│  ├─ Date formatting?
│  │  └─ lib/core/utils/date_utils.dart
│  ├─ File operations?
│  │  └─ lib/core/utils/file_utils.dart
│
├─ Is it ERROR HANDLING?
│  └─ lib/core/errors/exceptions.dart
│
├─ Is it ROUTING/NAVIGATION?
│  └─ lib/routing/
│
└─ Is it a DEVELOPMENT TEST SCREEN?
   └─ lib/test_screens/
```

---

## 🔗 DEPENDENCY FLOW (How Files Talk to Each Other)

### Standard Feature Dependency Flow
```
Screen (UI)
  ↓ (triggers action)
Provider (State Management)
  ↓ (calls)
UseCase (Business Logic - Domain)
  ↓ (calls)
Repository (Data Access - Data)
  ↓ (calls)
Service (API Calls - Data)
  ↓ (returns)
Model (Data Structure - Data)
  ↓ (converts to)
Entity (Business Entity - Domain)
  ↓ (returns to)
Provider (updates state)
  ↓ (rebuilds)
Screen (shows updated UI)
```

### Example: Check-in Attendance
```
attendance_screen.dart
  │ "User taps Check-in button"
  ↓
attendance_provider.dart
  │ "Provider handles action"
  ↓
check_in_usecase.dart
  │ "UseCase validates and processes"
  ↓
attendance_repository.dart
  │ "Repository manages data"
  ↓
attendance_service.dart
  │ "Service calls API: POST /api/attendance/checkin"
  ↓
attendance_checkin_model.dart
  │ "API returns response data"
  ↓
check_in_entity.dart
  │ "Converts to business entity"
  ↓
attendance_provider.dart
  │ "Updates state with result"
  ↓
attendance_screen.dart
  │ "Screen rebuilds and shows success"
  ↓
"User sees confirmation"
```

### Cross-Feature Dependencies (Shared Services)
```
attendance_screen.dart
  │ "Needs to get device location"
  ↓
shared/services/device/location_service.dart
  │ "Gets GPS coordinates"
  ↓
Returns location data
```

---

## 🎯 QUICK LOOKUP TABLE

| Need | Old Path | New Path |
|------|----------|----------|
| **Add Leave Screen** | `screen/` | `features/leave/presentation/screens/` |
| **Add Leave Model** | `models/` | `features/leave/data/models/` |
| **Add Leave Service** | `services/` | `features/leave/data/services/` |
| **Add Shared Widget** | `widgets/` | `shared/widgets/` |
| **Add Route** | Update manually | `core/constants/route_constants.dart` |
| **Add Constant** | `config/app_config.dart` | `core/constants/app_constants.dart` |
| **Add API Endpoint** | `config/api_config.dart` | `core/config/api_config.dart` |
| **Add Validator** | `utils/` | `core/utils/validators.dart` |
| **Add Location Service** | `services/location_*.dart` | `shared/services/device/location_service.dart` |
| **Add Toast/Dialog** | `widgets/` | `shared/widgets/common/` |

---

## 📈 FILE MIGRATION CHECKLIST

When migrating a feature, follow this order:

```
1. [ ] Create feature directory structure
   └── lib/features/[feature]/

2. [ ] Move data files
   ├── [ ] Models → data/models/
   ├── [ ] Services → data/services/
   └── [ ] Repositories → data/repositories/

3. [ ] Move presentation files
   ├── [ ] Screens → presentation/screens/
   ├── [ ] Widgets → presentation/widgets/
   └── [ ] Providers → presentation/providers/

4. [ ] Create domain files (if needed)
   ├── [ ] Entities → domain/entities/
   ├── [ ] Repository interfaces → domain/repositories/
   └── [ ] UseCases → domain/usecases/

5. [ ] Update all imports
   ├── [ ] Fix internal imports
   ├── [ ] Fix external imports in other features
   └── [ ] Update main.dart if needed

6. [ ] Update routing
   ├── [ ] Add routes to route_constants.dart
   └── [ ] Update navigation calls

7. [ ] Test feature
   ├── [ ] Compile without errors
   ├── [ ] Test all screens
   └── [ ] Test all API calls

8. [ ] Document changes
   └── [ ] Update team documentation
```

---

## 🎓 Examples by Developer Level

### Beginner Challenge
"Add a new field to the AttendanceCheckinModel"

**Solution Path:**
1. Find: `lib/features/attendance/data/models/attendance_checkin_model.dart`
2. Edit: Add new field and toJson/fromJson methods
3. Update: Related service calls that use this model
4. Test: Ensure serialization works
5. Done! ✅

### Intermediate Challenge
"Add a new screen to show attendance statistics"

**Solution Path:**
1. Create: `lib/features/attendance/presentation/screens/attendance_statistics_screen.dart`
2. Create: `lib/features/attendance/presentation/widgets/statistics_chart.dart`
3. Add: Provider method in `attendance_provider.dart`
4. Add: UseCase `fetch_statistics_usecase.dart`
5. Add: Service method in `attendance_service.dart`
6. Add: Model for statistics data
7. Add: Route in `route_constants.dart`
8. Test: Complete flow from screen to API
9. Done! ✅

### Advanced Challenge
"Implement offline mode for attendance"

**Solution Path:**
1. Update: Models to support caching
2. Update: Repository to add offline logic
3. Create: Cache manager in `shared/services/core/cache_service.dart`
4. Update: Services to check cache first
5. Create: Sync usecase for background sync
6. Update: Provider to handle offline state
7. Create: Connection listener in `shared/services/device/connectivity_service.dart`
8. Create: Widgets for offline indicators
9. Test: Offline flow with mock API
10. Done! ✅

---

## 🚀 Next Steps

1. **Read Structure Documents**:
   - `CURRENT_FILE_STRUCTURE_ANALYSIS.md`
   - `FILE_STRUCTURE_VISUAL_GUIDE.md`

2. **Explore Actual Files**:
   - Navigate to `lib/features/attendance/` - see actual structure
   - Check `lib/core/constants/` - see constant definitions
   - Review `lib/core/config/` - see configuration

3. **Understand a Feature**:
   - Pick one feature (e.g., attendance)
   - Trace files from screen to database
   - Understand the complete flow

4. **Plan First Migration**:
   - Choose simplest feature to migrate
   - Follow the migration checklist
   - Test thoroughly

---

**Guide Version**: 1.0
**Created**: March 17, 2026
**Purpose**: Understanding file organization and structure
**Status**: Complete (No code changes made)