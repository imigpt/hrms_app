// lib/screen/auth_check_screen.dart

import 'package:flutter/material.dart';
import 'package:hrms_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hrms_app/features/auth/presentation/screens/login_screen.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';
import 'package:hrms_app/shared/services/core/token_storage_service.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final TokenStorageService _tokenStorage = TokenStorageService();
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAuthStatus();
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    debugPrint('🔐 AuthCheckScreen: Starting auth check...');

    try {
      // Step 1: Check if user is logged in
      final isLoggedIn = await _tokenStorage.isLoggedIn();
      debugPrint('🔐 AuthCheckScreen: Is logged in? $isLoggedIn');

      if (!mounted) return;

      if (isLoggedIn) {
        // Step 2: Get stored token and user info
        final token = await _tokenStorage.getToken();
        final email = await _tokenStorage.getUserEmail();
        final name = await _tokenStorage.getUserName();
        final role = await _tokenStorage.getUserRole();
        final userId = await _tokenStorage.getUserId();

        debugPrint('🔐 AuthCheckScreen: Retrieved stored data for $email');

        if (token == null || token.isEmpty) {
          debugPrint(
            '⚠ AuthCheckScreen: Token is empty, clearing and showing login',
          );
          await _tokenStorage.clearLoginData();
          if (mounted) {
            _navigateToLogin();
          }
          return;
        }

        // Register / refresh FCM token so backend always has a valid token.
        // Fire-and-forget — do not block navigation on this.
        NotificationService().registerFcmToken(token).catchError((_) {});

        // Step 3: Try to fetch fresh profile with stored token
        try {
          debugPrint('🔐 AuthCheckScreen: Fetching profile with token...');

          // Use a timeout for profile fetch (10 seconds max)
          final profile = await _profileService
              .fetchProfile(token)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  debugPrint('⚠ AuthCheckScreen: Profile fetch timed out');
                  return null;
                },
              );

          if (!mounted) return;

          if (profile != null) {
            // Profile is valid, navigate to dashboard
            debugPrint(
              '✓ AuthCheckScreen: Profile valid, navigating to dashboard',
            );
            _navigateToDashboard(profile, token);
            return;
          } else {
            // Profile fetch failed but token might still be valid
            // Use fallback with cached data
            debugPrint(
              '⚠ AuthCheckScreen: Profile fetch failed, using cached data',
            );
            _navigateToDashboardWithFallback(
              email: email,
              name: name,
              role: role,
              userId: userId,
              token: token,
            );
            return;
          }
        } catch (e) {
          debugPrint('✗ AuthCheckScreen: Error fetching profile: $e');

          // Even if profile fetch fails, if we have a token, navigate with fallback
          // The user can still access the dashboard
          if (token.isNotEmpty) {
            debugPrint(
              '⚠ AuthCheckScreen: Using fallback navigation due to profile error',
            );
            _navigateToDashboardWithFallback(
              email: email,
              name: name,
              role: role,
              userId: userId,
              token: token,
            );
            return;
          }
        }

        // If we reach here, clear token and show login
        debugPrint(
          '🔐 AuthCheckScreen: Token invalid, clearing and showing login',
        );
        await _tokenStorage.clearLoginData();
        if (mounted) {
          _navigateToLogin();
        }
      } else {
        // User is not logged in, navigate to login screen
        debugPrint(
          '🔐 AuthCheckScreen: No login data found, showing login screen',
        );
        _navigateToLogin();
      }
    } catch (e) {
      debugPrint('✗ AuthCheckScreen: Unexpected error: $e');
      if (mounted) {
        _navigateToLogin();
      }
    }
  }

  void _navigateToDashboard(dynamic profile, String token) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(user: profile, token: token),
      ),
    );
  }

  void _navigateToDashboardWithFallback({
    required String? email,
    required String? name,
    required String? role,
    required String? userId,
    required String token,
  }) {
    // Create a minimal ProfileUser from cached data
    final fallbackProfile = _createFallbackProfile(
      email: email,
      name: name,
      role: role,
      userId: userId,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DashboardScreen(user: fallbackProfile, token: token),
      ),
    );
  }

  dynamic _createFallbackProfile({
    required String? email,
    required String? name,
    required String? role,
    required String? userId,
  }) {
    // Create a ProfileUser instance from cached data for fallback
    return ProfileUser(
      id: userId ?? 'unknown',
      employeeId: '',
      name: name ?? 'User',
      email: email ?? 'unknown@example.com',
      phone: '',
      dateOfBirth: null,
      address: '',
      role: role ?? 'employee',
      department: '',
      position: '',
      joinDate: null,
      status: 'active',
      profilePhoto: null,
      leaveBalance: null,
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF88899)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading...',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFFFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}
