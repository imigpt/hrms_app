import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:hrms_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hrms_app/features/auth/presentation/screens/login_screen.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _authCheckInitiated = false;
  bool _navigationHandled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Trigger auth check only once
    if (!_authCheckInitiated) {
      _authCheckInitiated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AuthNotifier>().checkAuthStatus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, _) {
        final authState = authNotifier.state;

        // Handle navigation only once when status changes from checking
        if (!_navigationHandled && !authState.isCheckingAuth) {
          _navigationHandled = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            if (authState.status == AuthStatus.authenticated) {
              final user = ProfileUser.fromAuth(authState.currentUser!);
              final token = authState.token!;

              // Register FCM token (fire-and-forget)
              NotificationService().registerFcmToken(token).catchError((_) {});

              // Start background profile fetch for non-admins
              if (authState.currentUser!.role.toLowerCase() != 'admin') {
                ProfileService().fetchProfile(token).catchError((_) {});
              }

              // Navigate to Dashboard
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    user: user,
                    token: token,
                  ),
                ),
              );
            } else if (authState.status == AuthStatus.unauthenticated) {
              // Navigate to Login
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            }
          });
        }

        // Show splash screen while checking
        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFF88899)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading...',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: const Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
