import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/screen/announcements_screen.dart';
import 'package:hrms_app/screen/auth_check_screen.dart';
import 'package:hrms_app/screen/chat_screen.dart';
import 'package:hrms_app/screen/expenses_screen.dart';
import 'package:hrms_app/screen/leave_management_screen.dart';
import 'package:hrms_app/screen/notifications_screen.dart';
import 'package:hrms_app/screen/payroll_screen.dart';
import 'package:hrms_app/screen/tasks_screen.dart';
import 'package:hrms_app/services/chat_media_service.dart';
import 'package:hrms_app/services/notification_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

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

Future<void> _retrieveFCMToken() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permission (Android 13+ and iOS)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('⚠️ Notification permission provisional');
    } else {
      debugPrint('❌ Notification permission denied');
    }

    // Get FCM token
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint('🔥 FCM TOKEN: $token');
      debugPrint('💡 This token will be saved to backend after user login');
      // Token will be saved to backend in auth flow after login
      // See: Token saving happens in auth_check_screen or login flow
    } else {
      debugPrint('❌ Failed to retrieve FCM token');
    }

    // Listen for token refresh and log it
    messaging.onTokenRefresh.listen((String newToken) {
      debugPrint('🔄 FCM Token Refreshed: $newToken');
      debugPrint('💡 Updated token will sync to backend on next login');
      // Token refresh will be handled by NotificationService
    });
  } catch (e) {
    debugPrint('❌ Error retrieving FCM token: $e');
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
                  builder: (_) => LeaveManagementScreen(token: token),
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
  }

  @override
  void dispose() {
    // Clear the callback to avoid stale references
    NotificationService.onNotificationTap = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aselea HRMS',
      theme: AppTheme.darkTheme,
      // Wire global navigatorKey so FCM taps can navigate from outside the widget tree
      navigatorKey: NotificationService.navigatorKey,
      // AuthCheckScreen determines whether to show login or dashboard
      home: const AuthCheckScreen(),
    );
  }
}
