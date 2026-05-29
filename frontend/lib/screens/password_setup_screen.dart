/// password_setup_screen.dart
///
/// Password Setup Screen (Step 3 of 4) — UnitWise
///
/// BUG FIXES APPLIED:
///   ✅ BUG 5 — Password not saved for future logins:
///              Now calls AuthService.setPasswordForUser(widget.phoneNumber, password) which uses
///              Firebase's linkWithCredential() to attach an email+password
///              credential to the user created during OTP verification.
///
///   ✅ BUG 6 — Back arrow takes user back to OTP screen:
///              AppBar automaticallyImplyLeading: false — no back arrow.
///              Navigator.pushAndRemoveUntil() clears the entire back stack
///              when moving to location setup so the user cannot go back.

library;

import 'package:flutter/material.dart';
import '../config/theme/colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import '../services/auth_service.dart';
import 'location_setup_screen.dart';

class PasswordSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;
  final String email;

  const PasswordSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.name,
    required this.email,
  });

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  final _authService = AuthService();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// ✅ BUG 5 FIX: Handle password setup by saving to Firebase Auth.
  Future<void> _handlePasswordSetup() async {
    if (!_formKey.currentState!.validate()) return;

    // Check passwords match before making any API call
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ FIXED: Proper method call with correct parameters
      final result = await _authService.setPasswordForUser(
        widget.phoneNumber,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // ✅ BUG 6 FIX: pushAndRemoveUntil clears entire navigation stack.
        // User cannot press back to return to OTP or password screen.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LocationSetupScreen(
              phoneNumber: widget.phoneNumber,
              name: widget.name,
              email: widget.email,
            ),
          ),
          (route) => false, // Remove ALL previous routes
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to set password. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred. Please try again.'),
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
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          // ✅ BUG 6 FIX: No back arrow — user must not return to OTP screen
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.lock_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header
                  Text(
                    'Create Password',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a secure password to protect your account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                  ),
                  const SizedBox(height: 48),

                  // Password field
                  PasswordTextField(
                    label: 'Password',
                    controller: _passwordController,
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),

                  // Confirm password field
                  PasswordTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: 32),

                  // Continue button
                  CustomButton(
                    text: 'Continue',
                    onPressed: _handlePasswordSetup,
                    isLoading: _isLoading,
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