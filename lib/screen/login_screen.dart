import 'package:flutter/material.dart';
import 'package:hrms_app/models/profile_model.dart';
import 'package:hrms_app/screen/dashboard_screen.dart';
import 'package:hrms_app/services/auth_service.dart';
import 'package:hrms_app/services/profile_service.dart';
import 'package:hrms_app/services/token_storage_service.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen()),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers used to retrieve text values
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  bool _isLoading = false;

  // State for toggling password visibility
  bool _isPasswordVisible = false;

  // --- Color Palette based on the image ---
  final Color kBackground = const Color(0xFF000000);
  final Color kCardBg = const Color(0xFF111111);
  final Color kInputBg = const Color(0xFF1F1F1F);
  // A distinct pink color picked from the button in the image
  final Color kPinkColor = const Color(0xFFF88899);
  final Color kTextWhite = const Color(0xFFFFFFFF);
  final Color kTextGrey = const Color(0xFF9E9E9E);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Input decoration template to keep code clean
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: kInputBg,
      hintStyle: TextStyle(color: kTextGrey.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Removes the default border line
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kPinkColor.withValues(alpha: 0.5), width: 1),
      ),
    );

    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            // The main dark card
            width: double.infinity,
            constraints: const BoxConstraints(
              maxWidth: 450,
            ), // Prevents it from getting too wide on tablets
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(20),
              // Subtle shadow to lift it slightly from the pure black bg
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
                // 1. Logo Placeholder
                // In a real app, use: SvgPicture.asset('assets/logo.svg', height: 50)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/aselea-logo.png', height: 60, width: 100),
                  ],
                ),

                const SizedBox(height: 30),

                // 2. Welcome Text
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

                // 3. Email Field
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

                // 4. Password Field
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
                  obscureText: !_isPasswordVisible, // Hides text based on state
                  style: TextStyle(color: kTextWhite),
                  decoration: inputDecoration.copyWith(
                    hintText: "Enter your password",
                    prefixIcon: Icon(Icons.lock_outline, color: kTextGrey),
                    // Eye icon toggle
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

                // 5. Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                      // 1. Get the text from controllers
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();

                      // 2. simple validation logic
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

                      setState(() {
                        _isLoading = true;
                      });

                      // Capture context-dependent objects before async gaps
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);

                      try {
                        final result = await _authService.login(
                          email,
                          password,
                        );

                        if (!mounted) return;
                        setState(() => _isLoading = false);

                        // Save token and user info
                        await _tokenStorage.saveLoginData(
                          token: result.token,
                          userId: result.user.id,
                          email: result.user.email,
                          name: result.user.name,
                        );
                        if (!mounted) return;

                        final profile = await _profileService.fetchProfile(
                          result.token,
                        );
                        final user =
                            profile ?? ProfileUser.fromAuth(result.user);
                        if (!mounted) return;

                        navigator.pushReplacement(
                          MaterialPageRoute(
                            builder: (context) =>
                                DashboardScreen(user: user, token: result.token),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        final message = e
                            .toString()
                            .replaceFirst('Exception: ', '');
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => _isLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPinkColor,
                      foregroundColor: Colors.black, // Black text color
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text("Sign In"),
                  ),
                ),

                const SizedBox(height: 24),

                // 6. Forgot Password Link
                TextButton(
                  onPressed: () {
                    // Handle forgot password navigation
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
      ),
    );
  }
}
