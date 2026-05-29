/// otp_verification_screen.dart
///
/// OTP Verification Screen (Step 2 of signup / Step 2 of login)
///
/// BUG FIXES APPLIED:
///   ✅ LOGIN OTP — Added `isLogin` flag. When true, successful verification
///              routes directly to MainScaffold (dashboard) instead of
///              LocationSetupScreen. Navigation stack is cleared so user
///              cannot go back to login screen.
///   ✅ COUNTDOWN TIMER — Added `mounted` check inside Future.doWhile to
///              prevent "setState() called after dispose()" crash when the
///              screen is navigated away while the countdown is still running.

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../config/theme/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import 'location_setup_screen.dart';
import 'main_scaffold.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String sessionId;
  final String name;
  final String email;
  final bool isLogin; // ✅ true = login flow, false = signup flow

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.sessionId,
    required this.name,
    required this.email,
    this.isLogin = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  final _authService = AuthService();

  bool _isLoading = false;
  int _resendCountdown = 0;
  late String _currentSessionId;
  bool get _canResend => _resendCountdown == 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _startResendCountdown();
    _currentSessionId = widget.sessionId;
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 30);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      // ✅ FIX: Stop the timer immediately if the screen has been disposed.
      // Without this, setState() fires after dispose() causing a crash.
      if (!mounted) return false;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
        return true;
      }
      return false;
    });
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit code'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.verifyOtp(
        _currentSessionId,
        otp,
        widget.phoneNumber,
      );

      if (!mounted) return;

      if (response["success"]) {
        if (widget.isLogin) {
          // ✅ LOGIN FLOW: Go straight to dashboard, clear entire back stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const MainScaffold(initialIndex: 0),
            ),
            (route) => false,
          );
        } else {
          // SIGNUP FLOW: Continue to location setup
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LocationSetupScreen(
                phoneNumber: widget.phoneNumber,
                name: widget.name,
                email: widget.email,
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response["message"] ?? 'Verification failed'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    try {
      final response = await _authService.sendOtp(widget.phoneNumber);
      if (response["success"] && response["sessionId"] != null) {
        _currentSessionId = response["sessionId"]!;
      }
      if (!mounted) return;
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent!'),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Verifying code...',
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Verify Your Number',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                    children: [
                      const TextSpan(text: 'Enter the 6-digit code sent to '),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // OTP Input
                Center(
                  child: Pinput(
                    controller: _otpController,
                    focusNode: _focusNode,
                    length: 6,
                    autofocus: true,
                    defaultPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onCompleted: (pin) => _handleVerifyOtp(),
                  ),
                ),
                const SizedBox(height: 32),

                CustomButton(
                  text: 'Verify Code',
                  onPressed: _handleVerifyOtp,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),

                Center(
                  child: _canResend
                      ? CustomTextButton(
                          text: 'Resend Code',
                          onPressed: _handleResendOtp,
                        )
                      : Text(
                          'Resend code in $_resendCountdown s',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
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