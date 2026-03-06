import 'package:flutter/material.dart';
import 'package:hrms_app/services/auth_service.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // --- Step 1: Email Input ---
  final _emailController = TextEditingController();
  bool _step1Loading = false;
  bool _step1Complete = false;

  // --- Step 2: Reset Code & Password ---
  final _resetCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _step2Loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  // --- Countdown Timer ---
  int _resendCountdown = 0;

  final AuthService _authService = AuthService();

  // --- Colors ---
  final Color kBackground = const Color(0xFF000000);
  final Color kCardBg = const Color(0xFF111111);
  final Color kInputBg = const Color(0xFF1F1F1F);
  final Color kPinkColor = const Color(0xFFF88899);
  final Color kTextWhite = const Color(0xFFFFFFFF);
  final Color kTextGrey = const Color(0xFF9E9E9E);
  final Color kGreen = const Color(0xFF10B981);

  @override
  void dispose() {
    _emailController.dispose();
    _resetCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Step 1: Request reset code ─────────────────────────────────────────────
  Future<void> _requestResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Please enter your email address');
      return;
    }

    setState(() => _step1Loading = true);

    try {
      final message = await _authService.forgotPassword(email);
      if (!mounted) return;

      setState(() {
        _step1Complete = true;
        _resendCountdown = 60;
        _step1Loading = false;
      });

      _startCountdown();
      _showSuccess(
        'Reset code sent to $email',
        'Please check your email for the 6-digit code.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _step1Loading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Step 2: Reset password ─────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final code = _resetCodeController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();
    final email = _emailController.text.trim();

    if (code.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('Reset code must be exactly 6 digits');
      return;
    }

    if (newPwd.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (newPwd != confirmPwd) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _step2Loading = true);

    try {
      final newToken = await _authService.resetPassword(
        email: email,
        resetToken: code,
        newPassword: newPwd,
      );

      if (!mounted) return;

      _showSuccess(
        'Password reset successfully!',
        'You can now log in with your new password.',
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _step2Loading = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ── Countdown timer for resend button ──────────────────────────────────────
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendCountdown > 0) {
        setState(() => _resendCountdown--);
        _startCountdown();
      }
    });
  }

  // ── Snackbars ──────────────────────────────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: kGreen, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: kTextGrey, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: Color(0xFFF88899))),
          ),
        ],
      ),
    );
  }

  // ── Input decoration template ──────────────────────────────────────────────
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kTextGrey.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: kTextGrey),
      filled: true,
      fillColor: kInputBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        borderSide: BorderSide(color: kPinkColor.withOpacity(0.5), width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Back Button ---
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kInputBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: kTextWhite,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Header ---
                  Icon(Icons.lock_reset_rounded, color: kPinkColor, size: 50),
                  const SizedBox(height: 16),
                  Text(
                    'Reset Password',
                    style: TextStyle(
                      color: kTextWhite,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step1Complete
                        ? 'Enter the code we sent to your email'
                        : 'We\'ll send you a code to reset your password',
                    style: TextStyle(color: kTextGrey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // ── STEP 1: Email Input ────────────────────────────────────
                  if (!_step1Complete) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Email Address',
                          style: TextStyle(
                            color: kTextWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _emailController,
                      enabled: !_step1Loading,
                      style: TextStyle(color: kTextWhite),
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'Enter your email',
                        Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _step1Loading ? null : _requestResetCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPinkColor,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _step1Loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.black,
                                  ),
                                ),
                              )
                            : const Text(
                                'Send Reset Code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ]
                  // ── STEP 2: Code & Password ────────────────────────────────
                  else ...[
                    // Reset Code
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Reset Code',
                          style: TextStyle(
                            color: kTextWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _resetCodeController,
                      style: TextStyle(color: kTextWhite),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !_step2Loading,
                      decoration: _inputDecoration(
                        'Enter 6-digit code',
                        Icons.password_rounded,
                      ).copyWith(counterText: ''),
                    ),
                    const SizedBox(height: 16),

                    // Resend button
                    if (_resendCountdown > 0)
                      Center(
                        child: Text(
                          'Resend code in ${_resendCountdown}s',
                          style: TextStyle(color: kTextGrey, fontSize: 12),
                        ),
                      )
                    else
                      Center(
                        child: TextButton(
                          onPressed: _step1Loading ? null : _requestResetCode,
                          child: Text(
                            'Didn\'t receive? Resend code',
                            style: TextStyle(
                              color: kPinkColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // New Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'New Password',
                          style: TextStyle(
                            color: kTextWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_showPassword,
                      enabled: !_step2Loading,
                      style: TextStyle(color: kTextWhite),
                      decoration:
                          _inputDecoration(
                            'Enter new password',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: kTextGrey,
                              ),
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Confirm Password',
                          style: TextStyle(
                            color: kTextWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirm,
                      enabled: !_step2Loading,
                      style: TextStyle(color: kTextWhite),
                      decoration:
                          _inputDecoration(
                            'Confirm password',
                            Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: kTextGrey,
                              ),
                              onPressed: () =>
                                  setState(() => _showConfirm = !_showConfirm),
                            ),
                          ),
                    ),
                    const SizedBox(height: 28),

                    // Reset Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _step2Loading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _step2Loading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Back to Step 1
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _step1Complete = false;
                          _resetCodeController.clear();
                          _newPasswordController.clear();
                          _confirmPasswordController.clear();
                        }),
                        child: Text(
                          '← Back to email',
                          style: TextStyle(color: kTextGrey, fontSize: 12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // --- Back to Login Link ---
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_new,
                          color: kTextGrey,
                          size: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Back to Login',
                          style: TextStyle(
                            color: kTextGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
