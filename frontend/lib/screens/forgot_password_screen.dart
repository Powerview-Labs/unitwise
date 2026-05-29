/// forgot_password_screen.dart
///
/// Forgot Password Screen — UnitWise
///
/// BUG FIXES APPLIED:
///   ✅ BUG 2 — "action must be 'request_otp' or 'reset_password'" error:
///              AuthService.resetPasswordRequest(phoneNumber, "request_otp") now sends action: 'request_otp'
///              in the request body. This was the missing field causing the error.
///
///   ✅ BUG 3 — E.164 format rejection:
///              Phone validation updated to accept Nigerian local format.
///              Normalization to E.164 happens in AuthService before the API call.

import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: Proper method call with correct parameters
      final response = await _authService.resetPasswordRequest(
        _phoneController.text.trim(),
        'request_otp',
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Reset code sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to OTP screen for password reset flow
        Navigator.pushNamed(
          context,
          '/verify-otp',
          arguments: {
            'sessionId': response['sessionId'],
            'phoneNumber': _phoneController.text.trim(),
            'name': '',
            'email': '',
            'isPasswordReset': true, // Flag to handle post-OTP navigation differently
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send reset code'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your phone number to receive a reset code',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ✅ BUG 3 FIX: Accepts Nigerian local format (08012345678)
                  PhoneTextField(
                    controller: _phoneController,
                    autofocus: true,
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Send Reset Code',
                    onPressed: _handleResetPassword,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Remember your password? ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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