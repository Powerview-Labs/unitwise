/// ==============================================================================
/// 📱 APPLIANCE ESTIMATOR PROMPT SCREEN
/// ==============================================================================
///
/// Shown after Location Setup during onboarding.
///
/// BUG FIXES:
/// ✅ Bug 4 — "Set Up Now" navigates to estimator with isFromDashboard: false
///            so the estimator only shows Save (no Skip) during onboarding.
/// ✅ Bug 2 — "Skip for Now" sets appliance_setup_completed = false immediately
///            so the dashboard shows the "forecasts locked" banner right away.
///
/// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../config/theme/colors.dart';
import '../../services/user_service.dart';
import 'estimator/appliance_estimator_screen.dart';

class ApplianceEstimatorPromptScreen extends StatelessWidget {
  const ApplianceEstimatorPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.power,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Track Your Electricity Usage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Add your appliances to get accurate daily consumption estimates and see how long your units will last.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 48),

              // ✅ Bug 4: isFromDashboard: false → estimator shows Save only (no Skip)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ApplianceEstimatorScreen(
                          isFromDashboard: false,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Set Up Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ Bug 2: Skip sets flag immediately → dashboard shows locked banner
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _skipToDashboard(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Skip for Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'You can add appliances later from the dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Bug 2: Sets appliance_setup_completed = false BEFORE navigating
  /// so the dashboard reads it immediately and shows the locked banner.
  Future<void> _skipToDashboard(BuildContext context) async {
    final userService = context.read<UserService>();

    try {
      await userService.updateUserProfile({
        'appliance_setup_completed': false,
        'onboarding_completed': true,
        'appliance_skipped_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Error skipping appliance setup: $e');
    }

    // Navigate regardless of whether the save succeeded
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}