// lib/screen/auth_check_screen.dart

import 'package:flutter/material.dart';
import 'package:hrms_app/screen/dashboard_screen.dart';
import 'package:hrms_app/screen/login_screen.dart';
import 'package:hrms_app/services/profile_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';

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
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Check if user is logged in
    final isLoggedIn = await _tokenStorage.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      // Get stored token and fetch user profile
      final token = await _tokenStorage.getToken();
      
      if (token != null) {
        try {
          // Try to fetch profile with stored token
          final profile = await _profileService.fetchProfile(token);
          
          if (!mounted) return;
          
          if (profile != null) {
            // Token is valid, navigate to dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardScreen(
                  user: profile,
                  token: token,
                ),
              ),
            );
            return;
          }
        } catch (e) {
          // Token might be expired or invalid
          debugPrint('Error fetching profile: $e');
        }
      }
      
      // If we reach here, token is invalid - clear it and show login
      await _tokenStorage.clearLoginData();
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    } else {
      // User is not logged in, navigate to login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000000),
      body: SizedBox.expand(),
    );
  }
}
