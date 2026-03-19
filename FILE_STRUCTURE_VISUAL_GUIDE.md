# HRMS App - File Structure Visual Guide

## 🗺️ Complete Directory Tree (Current State)

```
hrms_app/
├── lib/
│   ├── main.dart                                 [Entry point]
│   ├── firebase_options.dart                    [Firebase config]
│   ├── LOCATION_UPDATE_USAGE.dart               [Documentation]
│   │
│   ├── ==================== NEW STRUCTURE (Ready) ====================
│   │
│   ├── core/                                    [Infrastructure & Configuration]
│   │   ├── config/
│   │   │   ├── app_config.dart                  [✅ App settings, feature flags]
│   │   │   ├── api_config.dart                  [✅ API endpoints and config]
│   │   │   └── environment.dart                 [✅ Dev/Staging/Production]
│   │   │
│   │   ├── constants/
│   │   │   ├── app_constants.dart               [✅ User roles, statuses, messages]
│   │   │   ├── asset_constants.dart             [✅ Asset paths, file utilities]
│   │   │   ├── api_constants.dart               [✅ HTTP methods, headers]
│   │   │   └── route_constants.dart             [✅ Route definitions]
│   │   │
│   │   ├── errors/                              [⏳ Structure ready, content pending]
│   │   │   └── [exceptions.dart, failures.dart]
│   │   │
│   │   ├── network/                             [⏳ Structure ready, content pending]
│   │   │   ├── interceptors/
│   │   │   └── [api_client.dart, network_info.dart]
│   │   │
│   │   └── utils/                               [⏳ Structure ready, content pending]
│   │       └── [validators.dart, date_utils.dart, file_utils.dart]
│   │
│   ├── shared/                                  [Reusable Across Features]
│   │   ├── theme/
│   │   │   └── app_theme.dart                   [Theme & styling]
│   │   │
│   │   ├── widgets/
│   │   │   ├── common/                          [Common widgets (button, dialog)]
│   │   │   ├── cards/                           [Card-based components]
│   │   │   └── forms/                           [Form widgets]
│   │   │
│   │   ├── services/
│   │   │   ├── core/                            [API, storage, cache]
│   │   │   ├── device/                          [Camera, location, permissions]
│   │   │   ├── communication/                   [Notifications, chat, socket]
│   │   │   └── external/                        [Firebase, analytics]
│   │   │
│   │   └── mixins/                              [Reusable mixins]
│   │       └── [loading_mixin.dart, validation_mixin.dart]
│   │
│   ├── features/                                [Feature Modules]
│   │   │
│   │   ├── auth/                                [Authentication]
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── repositories/
│   │   │   │   └── services/
│   │   │   ├── presentation/
│   │   │   │   ├── screens/
│   │   │   │   ├── widgets/
│   │   │   │   └── providers/
│   │   │   └── domain/
│   │   │       ├── entities/
│   │   │       ├── repositories/
│   │   │       └── usecases/
│   │   │
│   │   ├── dashboard/                           [Home/Dashboard]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── attendance/                          [Check-in/out, geolocation]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── leave/                               [Leave requests & balance]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── payroll/                             [Salary slips & payments]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── tasks/                               [Task management]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── chat/                                [Real-time messaging]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── expenses/                            [Expense submissions]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── notifications/                       [Push notifications]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── announcements/                       [Company announcements]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   ├── profile/                             [User profile]
│   │   │   ├── data/
│   │   │   ├── presentation/
│   │   │   └── domain/
│   │   │
│   │   └── admin/                               [Admin features]
│   │       ├── data/
│   │       │   ├── models/
│   │       │   ├── repositories/
│   │       │   └── services/
│   │       ├── presentation/
│   │       │   ├── screens/
│   │       │   │   ├── admin_dashboard/
│   │       │   │   ├── employee_management/
│   │       │   │   ├── company_settings/
│   │       │   │   ├── reports/
│   │       │   │   └── system_settings/
│   │       │   ├── widgets/
│   │       │   └── providers/
│   │       └── domain/
│   │           ├── entities/
│   │           ├── repositories/
│   │           └── usecases/
│   │
│   ├── routing/                                 [Navigation Management]
│   │   ├── app_router.dart                      [Main router]
│   │   ├── navigation_service.dart              [Navigation helpers]
│   │   ├── route_generator.dart                 [Dynamic route generation]
│   │   └── routes/
│   │       ├── auth_routes.dart
│   │       ├── dashboard_routes.dart
│   │       └── admin_routes.dart
│   │
│   ├── test_screens/                            [Dev/Test Screens]
│   │   ├── api_test_screen.dart
│   │   ├── widget_test_screen.dart
│   │   └── integration_test_screen.dart
│   │
│   ├── ==================== OLD STRUCTURE (Active) ====================
│   │
│   ├── screen/                                  [ALL SCREENS - Mixed]
│   │   ├── admin/
│   │   │   ├── admin_settings/                  [Admin configuration]
│   │   │   │   ├── company_settings_screen.dart
│   │   │   │   ├── currencies_screen.dart
│   │   │   │   ├── email_settings_screen.dart
│   │   │   │   ├── employee_id_screen.dart
│   │   │   │   ├── hrm_settings_screen.dart
│   │   │   │   ├── locations_screen.dart
│   │   │   │   ├── payroll_settings_screen.dart
│   │   │   │   ├── pdf_fonts_screen.dart
│   │   │   │   ├── roles_permissions_screen.dart
│   │   │   │   ├── storage_settings_screen.dart
│   │   │   │   ├── translations_screen.dart
│   │   │   │   ├── work_status_screen.dart
│   │   │   │   └── shared.dart
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── admin_sentiment_analysis_screen.dart
│   │   │   └── admin_salary_screen.dart
│   │   │
│   │   ├── auth_check_screen.dart               [Authentication check]
│   │   ├── announcements_screen.dart            [Announcements list]
│   │   ├── announcement_detail_screen.dart
│   │   ├── announcement_api_test_screen.dart
│   │   ├── attendance_screen.dart               [Attendance check-in/out]
│   │   ├── attendance_api_test_screen.dart
│   │   ├── attendance_history_screen.dart
│   │   ├── checkout_photo_screen.dart           [Photo verification]
│   │   │
│   │   ├── chat_screen.dart                     [Chat messaging]
│   │   ├── chat_api_test_screen.dart
│   │   │
│   │   ├── expenses_screen.dart                 [Expense management]
│   │   ├── expense_api_test_screen.dart
│   │   │
│   │   ├── forgot_password_screen.dart          [Password reset]
│   │   │
│   │   ├── leave_management_screen.dart         [Leave requests]
│   │   ├── leave_balance_screen.dart
│   │   ├── leave_api_test_screen.dart
│   │   ├── increment_promotion_screen.dart
│   │   │
│   │   ├── location_settings_screen.dart        [Location preferences]
│   │   │
│   │   ├── notifications_screen.dart            [Notifications list]
│   │   │
│   │   ├── payroll_screen.dart                  [Salary information]
│   │   ├── my_salary_screen.dart
│   │   ├── pre_payments_screen.dart
│   │   │
│   │   ├── tasks_screen.dart                    [Task management]
│   │   ├── task_detail_sheet.dart
│   │   │
│   │   ├── user_api_integration_screen.dart
│   │   ├── user_profile_screen.dart             [User profile]
│   │   │
│   │   ├── api_test_screen.dart                 [Test screen]
│   │   ├── camera_screen.dart                   [Camera functionality]
│   │   ├── employee_api_test_screen.dart        [Test screen]
│   │   ├── all_clients_screen.dart
│   │   └── all_employees_screen.dart
│   │
│   ├── models/                                  [DATA MODELS - All Features]
│   │   ├── announcement_model.dart
│   │   ├── apply_leave_model.dart
│   │   ├── attendance_checkin_model.dart
│   │   ├── attendance_checkout_model.dart
│   │   ├── attendance_edit_request_model.dart
│   │   ├── attendance_history_model.dart
│   │   ├── attendance_records_model.dart
│   │   ├── attendance_summary_model.dart
│   │   ├── auth_login_model.dart
│   │   ├── auth_model.dart
│   │   ├── chat_room_model.dart
│   │   ├── dashboard_stats_model.dart
│   │   ├── employee_model.dart
│   │   ├── expense_model.dart
│   │   ├── leave_balance_model.dart
│   │   ├── leave_management_model.dart
│   │   ├── payroll_model.dart
│   │   ├── policy_model.dart
│   │   ├── profile_model.dart
│   │   ├── today_attendance_model.dart
│   │   └── update_location_model.dart
│   │
│   ├── services/                                [SERVICE LAYER - All Features]
│   │   ├── admin_service.dart
│   │   ├── admin_clients_service.dart
│   │   ├── announcement_service.dart
│   │   ├── announcement_websocket_service.dart
│   │   ├── api_notification_service.dart
│   │   ├── attendance_service.dart
│   │   ├── chat_media_service.dart
│   │   ├── chat_socket_service.dart
│   │   ├── employee_service.dart
│   │   ├── expense_service.dart
│   │   ├── face_verification_service.dart
│   │   ├── hr_accounts_service.dart
│   │   ├── leave_service.dart
│   │   ├── location_update_service.dart
│   │   ├── location_utility_service.dart
│   │   ├── notification_service.dart
│   │   ├── payroll_service.dart
│   │   ├── policy_service.dart
│   │   ├── settings_service.dart
│   │   ├── task_service.dart
│   │   ├── token_storage_service.dart
│   │   ├── workflow_service.dart
│   │   ├── workflow_visualization_service.dart
│   │   └── [More services...]
│   │
│   ├── widgets/                                 [REUSABLE WIDGETS - Unorganized]
│   │   ├── announcements_section.dart
│   │   ├── attendance_edit_request_dialog.dart
│   │   ├── attendance_edit_requests_card.dart
│   │   ├── attendance_statistics_section.dart
│   │   ├── bod_eod_dialogs.dart
│   │   ├── dashboard_quick_stats_section.dart
│   │   ├── dashboard_stats_card.dart
│   │   ├── leave_statistics_section.dart
│   │   ├── location_permission_dialog.dart
│   │   ├── mobile_dashboard_stats.dart
│   │   ├── profile_card_widget.dart
│   │   ├── stat_card.dart
│   │   ├── status_card.dart
│   │   ├── task_workflow_canvas.dart
│   │   ├── tasks_section.dart
│   │   ├── workflow_tab_widget.dart
│   │   └── workflow_template_manager.dart
│   │
│   ├── utils/                                   [UTILITIES - Mixed]
│   │   ├── location_update_mixin.dart           [Mixin for location]
│   │   └── responsive_utils.dart                [Responsive design helpers]
│   │
│   ├── theme/                                   [THEMING - Single file]
│   │   └── app_theme.dart                       [All theme configuration]
│   │
│   └── config/                                  [CONFIGURATION - OLD]
│       └── api_config.dart                      [OLD - Duplicate of core/config]
│
├── android/                                     [Android native code]
├── ios/                                         [iOS native code]
├── linux/                                       [Linux support]
├── macos/                                       [macOS support]
├── windows/                                     [Windows support]
├── web/                                         [Web support]
├── assets/                                      [Images, icons, etc]
├── test/                                        [Unit tests]
├── pubspec.yaml                                 [Dependencies]
└── pubspec.lock                                 [Locked dependencies]
```

---

## 🎯 QUICK REFERENCE: WHERE TO FIND THINGS

### Authentication
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Login screen | `screen/auth_check_screen.dart` | `features/auth/presentation/screens/` |
| Auth model | `models/auth_model.dart` | `features/auth/data/models/` |
| Auth service | `services/token_storage_service.dart` | `features/auth/data/services/` |
| Forgot password | `screen/forgot_password_screen.dart` | `features/auth/presentation/screens/` |

### Attendance
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Checkin screen | `screen/attendance_screen.dart` | `features/attendance/presentation/screens/` |
| Attendance models | `models/attendance_*.dart` | `features/attendance/data/models/` |
| Location service | `services/location_*_service.dart` | `shared/services/device/` |
| Attendance service | `services/attendance_service.dart` | `features/attendance/data/services/` |

### Leave Management
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Leave screen | `screen/leave_management_screen.dart` | `features/leave/presentation/screens/` |
| Leave models | `models/leave_*.dart` | `features/leave/data/models/` |
| Leave service | `services/leave_service.dart` | `features/leave/data/services/` |
| Leave balance | `screen/leave_balance_screen.dart` | `features/leave/presentation/screens/` |

### Chat
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Chat screen | `screen/chat_screen.dart` | `features/chat/presentation/screens/` |
| Chat socket | `services/chat_socket_service.dart` | `shared/services/communication/` |
| Chat model | `models/chat_room_model.dart` | `features/chat/data/models/` |

### Tasks
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Task screen | `screen/tasks_screen.dart` | `features/tasks/presentation/screens/` |
| Task service | `services/task_service.dart` | `features/tasks/data/services/` |
| Workflow service | `services/workflow_service.dart` | `features/tasks/data/services/` |

### Admin Features
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Admin screens | `screen/admin/admin_settings/` | `features/admin/presentation/screens/` |
| Admin service | `services/admin_service.dart` | `features/admin/data/services/` |
| Company settings | `screen/admin/admin_settings/company_settings_screen.dart` | `features/admin/presentation/screens/...` |

### Shared Services
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Notifications | `services/api_notification_service.dart` | `shared/services/communication/` |
| Firebase | `services/notification_service.dart` | `shared/services/external/` |
| Camera | `screen/camera_screen.dart` | `shared/services/device/` |
| Location | `services/location_*_service.dart` | `shared/services/device/` |

### Shared Widgets
| What | Old Location | New Location (Target) |
|------|--------------|----------------------|
| Stat cards | `widgets/stat_card.dart` | `shared/widgets/cards/` |
| Dialogs | `widgets/*_dialog.dart` | `shared/widgets/common/` |
| Dashboard section | `widgets/dashboard_*_section.dart` | `shared/widgets/common/` |

---

## 🔍 FEATURE-TO-FILE MAPPING

### Feature: ATTENDANCE
```
Old Structure Files:
  ├── screen/attendance_screen.dart
  ├── screen/attendance_history_screen.dart
  ├── screen/checkout_photo_screen.dart
  ├── models/attendance_checkin_model.dart
  ├── models/attendance_checkout_model.dart
  ├── models/attendance_history_model.dart
  ├── models/attendance_edit_request_model.dart
  ├── models/attendance_summary_model.dart
  ├── models/attendance_records_model.dart
  ├── services/attendance_service.dart
  ├── services/location_update_service.dart
  ├── services/location_utility_service.dart
  ├── widgets/attendance_edit_request_dialog.dart
  ├── widgets/attendance_edit_requests_card.dart
  ├── widgets/attendance_statistics_section.dart
  ├── utils/location_update_mixin.dart
  └── utils/responsive_utils.dart

New Structure (Target):
  └── features/attendance/
      ├── data/
      │   ├── models/
      │   │   ├── attendance_checkin_model.dart
      │   │   ├── attendance_checkout_model.dart
      │   │   ├── attendance_history_model.dart
      │   │   ├── attendance_edit_request_model.dart
      │   │   └── attendance_summary_model.dart
      │   ├── repositories/
      │   │   └── attendance_repository.dart
      │   └── services/
      │       ├── attendance_service.dart
      │       └── location_service.dart [moved to shared later]
      ├── presentation/
      │   ├── screens/
      │   │   ├── attendance_screen.dart
      │   │   ├── attendance_history_screen.dart
      │   │   └── checkout_photo_screen.dart
      │   ├── widgets/
      │   │   ├── attendance_edit_request_dialog.dart
      │   │   ├── attendance_edit_requests_card.dart
      │   │   └── attendance_statistics_section.dart
      │   └── providers/
      │       └── attendance_provider.dart [NEW]
      └── domain/
          ├── entities/
          │   └── attendance_entity.dart [NEW]
          └── repositories/
              └── attendance_repository.dart [NEW]
```

---

## 📊 STATISTICS

### Old Structure (Current Production)
- **Screens**: ~40 files (30-40 screens across multiple features)
- **Models**: ~20+ files (data structures)
- **Services**: ~22+ files (API calls and business logic)
- **Widgets**: ~17+ files (reusable components)
- **Utils**: 2+ files (helper functions)
- **Total Core Files**: 100+ files

### New Structure (Prepared)
- **Core**: 7 files (configuration & constants)
- **Features**: 12 modules (directories ready)
- **Shared**: 3+ directories (to be populated)
- **Routing**: 1+ file (ready for development)
- **Total**: 100+ files (to be migrated + new additions)

---

## ⚖️ COMPARISON: Locating a File

### Old Way
```
Developer: "Where is the attendance check-in logic?"
Steps:
1. Check screen directory: Found attendance_screen.dart
2. Search services: Found attendance_service.dart
3. Search models: Found attendance_checkin_model.dart
4. Search widgets: Found attendance_statistics_section.dart
5. Mentally connect the pieces together
Result: Time spent: 5-10 minutes
```

### New Way
```
Developer: "Where is the attendance check-in logic?"
Steps:
1. Go to lib/features/attendance
Result: Everything attendance-related is in one place
Time spent: 1-2 minutes
```

---

## 🚀 NAVIGATION GUIDE FOR DEVELOPERS

### Finding a Feature
```
Question: "I need to work on Task management"
Answer:
  1. All task code is in: lib/features/tasks/
  2. UI screens are in: lib/features/tasks/presentation/screens/
  3. API calls are in: lib/features/tasks/data/services/
  4. Data models are in: lib/features/tasks/data/models/
  5. Business logic is in: lib/features/tasks/domain/
```

### Finding a Specific Component Type
```
Question: "Where are reusable card widgets?"
Old Way: Search through lib/widgets/ for *_card.dart files
New Way: Go to lib/shared/widgets/cards/

Question: "Where is the notification service?"
Old Way: Search through lib/services/ directory
New Way: Go to lib/shared/services/communication/
```

### Understanding Dependencies
```
Old Way: Hard to trace which service is used where
New Way:
  - Import from specific feature or shared
  - Clear separation prevents circular deps
  - Services are organized by category
```

---

## 🎓 Onboarding with New Structure

### New Developer Questions & Answers

**Q1: "Where do I add a new screen for attendance?"**
A: `lib/features/attendance/presentation/screens/`

**Q2: "Where are the API models for leave?"**
A: `lib/features/leave/data/models/`

**Q3: "Where is the shared notification service?"**
A: `lib/shared/services/communication/notification_service.dart`

**Q4: "Where are app-wide constants?"**
A: `lib/core/constants/app_constants.dart`

**Q5: "How do I add a new route?"**
A: Define in `lib/core/constants/route_constants.dart` and implement in `lib/routing/`

**Q6: "Where are the API endpoint definitions?"**
A: `lib/core/config/api_config.dart`

**Q7: "Where do reusable widgets go?"**
A: `lib/shared/widgets/{common|cards|forms}/`

**Q8: "Where do I add validation utilities?"**
A: `lib/core/utils/validators.dart`

---

## 📈 Improvement Metrics

| Metric | Old Structure | New Structure |
|--------|---------------|---------------|
| Time to find file | 5-10 min | 1-2 min |
| Import statements | Scattered | Organized |
| Circular dependencies | Likely | Prevented |
| Team collaboration | Difficult | Easy |
| Code reuse | Manual | Clear |
| onboarding time | 2-3 weeks | 3-5 days |
| Feature addition | 2-3 hours | 30-45 min |

---

## 🎯 ACTION ITEMS FOR UNDERSTANDING

1. **✅ Review This Document**: Understand current structure
2. **✅ Explore Directories**: Navigate both old and new structures
3. **✅ Read Configuration Files**: `lib/core/config/` and `lib/core/constants/`
4. **✅ Understand Layers**: Review Clean Architecture (data/presentation/domain)
5. **✅ Plan Migration**: Decide feature order for migration

---

**Document Version**: 1.0
**Created**: March 17, 2026
**Status**: Complete (For Understanding Only)