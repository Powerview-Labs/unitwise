import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UNITWISE — PRIVACY POLICY',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Last updated: 10 November 2025',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This Privacy Policy explains how PowerView Labs Limited ("we," "our," "UnitWise," or "the App") collects, uses, discloses, and protects your information when you use the UnitWise mobile application and related services.\n\n'
              'By using UnitWise, you agree to the collection and use of information in accordance with this policy.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'a) Personal Information\n\n'
              'We may collect:\n'
              '• Full name\n'
              '• Email address\n'
              '• Phone number\n'
              '• Account login credentials\n\n'
              'b) Meter & Usage Information\n\n'
              '• Meter number(s)\n'
              '• Token purchase history\n'
              '• Estimated electricity usage\n'
              '• Band category & supply estimation\n'
              '• Optional manual entries\n\n'
              'c) Device Information\n\n'
              '• Device model / OS\n'
              '• IP address\n'
              '• App usage activity\n'
              '• Diagnostic logs\n\n'
              'd) Optional Location Data\n\n'
              'If enabled, we may collect approximate location to help estimate supply and improve predictions.\n\n'
              'e) Automatically Collected Data\n\n'
              '• Cookies (if applicable)\n'
              '• Analytics\n'
              '• Crash logs',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use your data to:\n\n'
              '• Provide electricity usage predictions\n'
              '• Display token history and budgets\n'
              '• Improve app services and algorithms\n'
              '• Send low-unit notifications\n'
              '• Provide customer support\n'
              '• Communicate feature updates\n'
              '• Maintain security and prevent misuse\n\n'
              'We may use aggregated or anonymized data for analytics and product improvement. No personal identity will be attached.',
            ),
            _buildSection(
              '3. How We Share Your Information',
              'We do NOT sell your personal data.\n\n'
              'We may share your data only with:\n\n'
              '• Service providers (e.g., cloud hosting, analytics tools)\n'
              '• Authorities, if legally required\n'
              '• Business transfers — in case of merger, acquisition, or restructuring\n\n'
              'All third parties are required to maintain confidentiality.',
            ),
            _buildSection(
              '4. Data Storage & Security',
              'We take appropriate measures to protect your data using:\n\n'
              '• Encryption\n'
              '• Limited access control\n'
              '• Secure authentication\n\n'
              'However, no electronic transmission is completely secure; use the app at your own risk.',
            ),
            _buildSection(
              '5. Your Rights',
              'You may:\n\n'
              '• Request to view your data\n'
              '• Update your information\n'
              '• Request data deletion\n'
              '• Request to close your account\n\n'
              'To exercise rights, contact:\n'
              '📩 support@powerviewlabs.com',
            ),
            _buildSection(
              '6. Data Retention',
              'We retain your information as long as:\n\n'
              '• Your account is active, or\n'
              '• Necessary to comply with legal obligations\n\n'
              'You may request deletion anytime.',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'UnitWise is not intended for users under 16 years.\n'
              'We do not knowingly collect data from minors.',
            ),
            _buildSection(
              '8. Third-Party Services',
              'We may use third-party tools (analytics, storage, authentication).\n'
              'Each third party has its own privacy policy.\n\n'
              'We are not responsible for their practices.',
            ),
            _buildSection(
              '9. International Users',
              'The App is primarily intended for use in Nigeria, and data is governed by Nigerian laws. Users outside Nigeria do so at their own risk.',
            ),
            _buildSection(
              '10. Changes to This Policy',
              'We may update this Privacy Policy periodically.\n'
              'Continued use constitutes acceptance of the updated policy.',
            ),
            _buildSection(
              '11. Contact Us',
              'For questions or concerns, contact:\n'
              '📩 support@powerviewlabs.com\n\n'
              '📍 PowerView Labs Limited, Nigeria',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
