import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:hrms_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:hrms_app/features/auth/presentation/screens/auth_check_screen.dart';
import 'package:hrms_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:hrms_app/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:hrms_app/features/leave/presentation/screens/leave_management_screen.dart';
import 'package:hrms_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:hrms_app/features/payroll/presentation/screens/payroll_screen.dart';
import 'package:hrms_app/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:hrms_app/features/profile/presentation/providers/profile_notifier.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';
import 'package:hrms_app/features/leave/presentation/providers/leave_notifier.dart';
import 'package:hrms_app/features/admin/presentation/providers/calendar_notifier.dart';
import 'package:hrms_app/features/admin/presentation/providers/company_notifier.dart';
import 'package:hrms_app/features/notifications/presentation/providers/notifications_notifier.dart';
import 'package:hrms_app/features/notifications/data/services/api_notification_service.dart';
import 'package:hrms_app/features/dashboard/presentation/providers/dashboard_notifier.dart';
import 'package:hrms_app/features/expenses/presentation/providers/expenses_notifier.dart';
import 'package:hrms_app/features/expenses/data/services/expense_service.dart';
import 'package:hrms_app/features/payroll/presentation/providers/payroll_notifier.dart';
import 'package:hrms_app/features/payroll/data/services/payroll_service.dart';
import 'package:hrms_app/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:hrms_app/features/attendance/data/services/attendance_service.dart';
import 'package:hrms_app/features/tasks/presentation/providers/tasks_notifier.dart';
import 'package:hrms_app/features/tasks/data/services/task_service.dart';
import 'package:hrms_app/features/announcements/presentation/providers/announcements_notifier.dart';
import 'package:hrms_app/features/announcements/data/services/announcement_service.dart';
import 'package:hrms_app/features/settings/presentation/providers/settings_notifier.dart';
import 'package:hrms_app/features/chat/presentation/providers/chat_notifier.dart';
import 'package:hrms_app/features/chat/data/services/chat_media_service.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'firebase_options.dart';
import 'package:hrms_app/shared/theme/app_theme.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('✅ Firebase initialized successfully');

  // 3. Register FCM background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  debugPrint('✅ Background handler registered');

  // 4. Initialize Cameras
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error initializing camera: $e');
  }

  // 5. Initialize Notification Service
  try {
    await NotificationService().initialize();
    final permissionGranted = await NotificationService()
        .requestNotificationPermissions();
    debugPrint('Notification permission granted: $permissionGranted');
    // Set up FCM foreground handlers
    await NotificationService().setupFcmHandlers();
    debugPrint('✅ FCM handlers configured');

    // Retrieve and log FCM token
    await _retrieveFCMToken();
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // 5. Initialize ChatMediaService (sets up local cache directory)
  try {
    await ChatMediaService().init();
    debugPrint('ChatMediaService initialized');
  } catch (e) {
    debugPrint('Error initializing ChatMediaService: $e');
  }

  // 6. Set System UI Overlay (Optional: makes status bar transparent)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 7. Run App with cameras
  runApp(HrmsApp(cameras: cameras));
}

/// Retrieve and log the FCM token for diagnostic purposes.
/// NOTE: Permission is NOT requested here — that is done inside
/// NotificationService.registerFcmToken() after login, so we avoid
/// a duplicate permission dialog and a race that clears the token.
Future<void> _retrieveFCMToken() async {
  try {
    // Get FCM token (Firebase.initializeApp must have completed already)
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null && token.isNotEmpty) {
      debugPrint('🔥 FCM token retrieved at startup: $token');
      debugPrint('💡 Token will be saved to backend after user login via registerFcmToken()');
    } else {
      debugPrint('⚠️ FCM token is null at startup — will retry after login via registerFcmToken()');
    }
  } catch (e) {
    debugPrint('❌ Error retrieving FCM token at startup: $e');
  }
}

class HrmsApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const HrmsApp({super.key, required this.cameras});

  @override
  State<HrmsApp> createState() => _HrmsAppState();
}

class _HrmsAppState extends State<HrmsApp> {
  @override
  void initState() {
    super.initState();
    debugPrint('🚀 HrmsApp initialized');

    // Register notification tap handler for background/terminated FCM taps
    // Supports notifications from both HRMS system and external apps
    NotificationService.onNotificationTap =
        (String type, String referenceId) async {
          final nav = NotificationService.navigatorKey.currentState;
          if (nav == null) {
            debugPrint('⚠️ Navigator not available for notification tap');
            return;
          }

          debugPrint(
            '📲 Handling notification tap: type=$type, ref=$referenceId',
          );

          final storage = TokenStorageService();
          final token = await storage.getToken();
          final role = await storage.getUserRole() ?? 'employee';

          // Handle notifications from HRMS system and external apps
          switch (type) {
            case 'chat':
              debugPrint('→ Navigating to Chat');
              nav.push(MaterialPageRoute(builder: (_) => const ChatScreen()));
              break;
            case 'announcement':
              debugPrint('→ Navigating to Announcements');
              nav.push(
                MaterialPageRoute(
                  builder: (_) =>
                      AnnouncementsScreen(token: token, role: role),
                ),
              );
              break;
            case 'task':
            case 'task_assigned':
            case 'task_updated':
            case 'task_completed':
            case 'task_comment':
              debugPrint('→ Navigating to Tasks');
              nav.push(
                MaterialPageRoute(
                  builder: (_) => TasksScreen(token: token, role: role),
                ),
              );
              break;
            case 'leave':
            case 'leave_request':
            case 'leave_approved':
            case 'leave_rejected':
              debugPrint('→ Navigating to Leave Management');
              nav.push(
                MaterialPageRoute(
                  builder: (_) => const LeaveManagementScreen(),
                ),
              );
              break;
            case 'expense':
            case 'expense_approved':
            case 'expense_rejected':
              debugPrint('→ Navigating to Expenses');
              nav.push(
                MaterialPageRoute(
                  builder: (_) => ExpensesScreen(role: role),
                ),
              );
              break;
            case 'payroll':
            case 'payroll_generated':
              debugPrint('→ Navigating to Payroll');
              nav.push(
                MaterialPageRoute(builder: (_) => PayrollScreen(role: role)),
              );
              break;
            case 'attendance':
            case 'attendance_checkin':
            case 'attendance_checkout':
            case 'attendance_correction':
              debugPrint('→ Navigating to Attendance');
              nav.push(
                MaterialPageRoute(
                  builder: (_) => const AttendanceScreen(),
                ),
              );
              break;
            case 'approval':
            case 'approval_required':
            default:
              // Default navigation for unknown types from external apps
              debugPrint('→ Navigating to Notifications (default for: $type)');
              nav.push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              break;
          }
        };

    // Consume any pending terminated-state notification that the retry loop
    // could not deliver yet (navigator was not ready during app start).
    final pendingType = NotificationService.pendingNotificationType;
    final pendingRef  = NotificationService.pendingNotificationReferenceId;
    if (pendingType != null) {
      debugPrint('📲 Consuming pending terminated-state notification: type=$pendingType');
      NotificationService.pendingNotificationType        = null;
      NotificationService.pendingNotificationReferenceId = null;
      // Small delay so the navigator has finished building the initial route.
      Future.delayed(const Duration(milliseconds: 300), () {
        NotificationService.onNotificationTap?.call(pendingType, pendingRef ?? '');
      });
    }
  }

  @override
  void dispose() {
    // Clear the callback to avoid stale references
    NotificationService.onNotificationTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>(
          create: (_) => AuthNotifier(
            AuthService(),
            TokenStorageService(),
          ),
        ),
        ChangeNotifierProvider<ProfileNotifier>(
          create: (_) => ProfileNotifier(ProfileService()),
        ),
        ChangeNotifierProvider<LeaveNotifier>(
          create: (_) => LeaveNotifier(),
        ),
        ChangeNotifierProvider<CalendarNotifier>(
          create: (_) => CalendarNotifier(),
        ),
        ChangeNotifierProvider<CompanyNotifier>(
          create: (_) => CompanyNotifier(),
        ),
        ChangeNotifierProvider<NotificationsNotifier>(
          create: (_) => NotificationsNotifier(ApiNotificationService()),
        ),
        ChangeNotifierProvider<DashboardNotifier>(
          create: (_) => DashboardNotifier(
            attendanceService: AttendanceService(),
            announcementService: AnnouncementService(),
          ),
        ),
        ChangeNotifierProvider<ExpensesNotifier>(
          create: (_) => ExpensesNotifier(expenseService: ExpenseService()),
        ),
        ChangeNotifierProvider<PayrollNotifier>(
          create: (_) => PayrollNotifier(payrollService: PayrollService()),
        ),
        ChangeNotifierProvider<AttendanceNotifier>(
          create: (_) => AttendanceNotifier(
            attendanceService: AttendanceService(),
          ),
        ),
        ChangeNotifierProvider<TasksNotifier>(
          create: (_) => TasksNotifier(taskService: TaskService()),
        ),
        ChangeNotifierProvider<AnnouncementsNotifier>(
          create: (_) => AnnouncementsNotifier(
            announcementService: AnnouncementService(),
          ),
        ),
        ChangeNotifierProvider<SettingsNotifier>(
          create: (_) => SettingsNotifier(),
        ),
        ChangeNotifierProvider<ChatNotifier>(
          create: (_) => ChatNotifier(),
        ),
      ],
      child: Builder(
        builder: (context) {
          // Initialize auth state on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthNotifier>().restoreAuthFromStorage();
          });

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Aselea HRMS',
            theme: AppTheme.darkTheme,
            // Wire global navigatorKey so FCM taps can navigate from outside the widget tree
            navigatorKey: NotificationService.navigatorKey,
            // AuthCheckScreen determines whether to show login or dashboard
            home: const AuthCheckScreen(),
          );
        },
      ),
    );
  }
}
