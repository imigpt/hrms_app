import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hrms_app/features/auth/presentation/providers/auth_notifier.dart';
import 'package:hrms_app/features/profile/data/models/profile_model.dart';
import 'package:hrms_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hrms_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:hrms_app/shared/services/communication/notification_service.dart';
import 'package:hrms_app/features/profile/data/services/profile_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ProfileService _profileService = ProfileService();

  bool _isPasswordVisible = false;
  Timer? _errorTimer;

  final Color kBackground = const Color(0xFF000000);
  final Color kCardBg = const Color(0xFF111111);
  final Color kInputBg = const Color(0xFF1F1F1F);
  final Color kPinkColor = const Color(0xFFF88899);
  final Color kTextWhite = const Color(0xFFFFFFFF);
  final Color kTextGrey = const Color(0xFF9E9E9E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _errorTimer?.cancel();
    super.dispose();
  }

  void _showError(String message) {
    _errorTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    _errorTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && context.mounted) {
        context.read<AuthNotifier>().clearError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: kInputBg,
      hintStyle: TextStyle(color: kTextGrey.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: kPinkColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: kBackground,
      body: Consumer<AuthNotifier>(
        builder: (context, authNotifier, _) {
          // Get current auth state
          final authState = authNotifier.state;

          // Handle navigation when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted &&
                authState.isAuthenticated &&
                authState.status == AuthStatus.authenticated) {
              final user = ProfileUser.fromAuth(authState.currentUser!);
              final token = authState.token!;

              // Register FCM token (fire-and-forget)
              NotificationService().registerFcmToken(token).catchError((_) {});

              // Start background profile fetch for non-admins
              if (authState.currentUser!.role.toLowerCase() != 'admin') {
                _profileService.fetchProfile(token).catchError((_) => null);
              }

              // Navigate to Dashboard with MaterialPageRoute
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => DashboardScreen(
                    user: user,
                    token: token,
                  ),
                ),
              );
            }
          });

          // Show error if present
          if (authState.errorMessage != null &&
              authState.errorMessage!.isNotEmpty) {
            Future.microtask(() => _showError(authState.errorMessage!));
          }

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 450),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: kCardBg,
                      ),
                      child: Image.asset(
                        'assets/images/aselea-logo.jpeg',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Welcome Back",
                      style: TextStyle(
                        color: kTextWhite,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to access your HRMS dashboard",
                      style: TextStyle(color: kTextGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Email Address",
                          style: TextStyle(
                            color: kTextWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: kTextWhite),
                      keyboardType: TextInputType.emailAddress,
                      decoration: inputDecoration.copyWith(
                        hintText: "Enter your email",
                        prefixIcon: Icon(Icons.email_outlined, color: kTextGrey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          "Password",
                          style: TextStyle(
                            color: kTextWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: kTextWhite),
                      decoration: inputDecoration.copyWith(
                        hintText: "Enter your password",
                        prefixIcon: Icon(Icons.lock_outline, color: kTextGrey),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: kTextGrey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                final email = _emailController.text.trim();
                                final password =
                                    _passwordController.text.trim();

                                if (email.isEmpty || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter both email and password",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                authNotifier.login(email, password);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPinkColor,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: authState.isLoading
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Signing in...",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : const Text("Sign In"),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Forgot password?",
                        style: TextStyle(
                          color: kPinkColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
