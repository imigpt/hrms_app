import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_app/screen/dashboard_screen.dart';
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

  // 3. Set System UI Overlay (Optional: makes status bar transparent)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // 4. Run App with cameras
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
      // 5. Pass cameras to DashboardScreen
      // Note: You must update your DashboardScreen constructor to accept 'cameras'
      home: DashboardScreen(), 
    );
  }
}