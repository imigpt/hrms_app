import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/screen/auth_check_screen.dart';
import 'package:hrms_app/services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // 1. Ensure bindings are initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Cameras
  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint('Error initializing camera: $e');
  }

  // 3. Initialize Notification Service
  try {
    await NotificationService().initialize();
    final permissionGranted = await NotificationService().requestNotificationPermissions();
    debugPrint('Notification permission granted: $permissionGranted');
  } catch (e) {
    debugPrint('Error initializing notifications: $e');
  }

  // 4. Set System UI Overlay (Optional: makes status bar transparent)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // 5. Run App with cameras
  runApp(HrmsApp(cameras: cameras));
}

class HrmsApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const HrmsApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aselea HRMS',
      theme: AppTheme.darkTheme,
      // AuthCheckScreen determines whether to show login or dashboard
      home: const AuthCheckScreen(),
    );
  }
}