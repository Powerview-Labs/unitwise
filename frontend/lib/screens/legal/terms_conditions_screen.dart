import 'package:flutter/material.dart';
import '../../config/theme/colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'UNITWISE — TERMS & CONDITIONS',
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
              'These Terms & Conditions ("Terms") govern your use of UnitWise ("the App") provided by PowerView Labs Limited.\n\n'
              'By using UnitWise, you agree to these Terms.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Eligibility',
              'To use UnitWise, you must:\n\n'
              '• Be at least 16 years old\n'
              '• Provide accurate information\n'
              '• Comply with these Terms',
            ),
            _buildSection(
              '2. Account Registration',
              'You may need to create an account to use some features.\n'
              'You agree to:\n\n'
              '• Provide accurate information\n'
              '• Keep login credentials secure\n'
              '• Notify us if unauthorized access occurs\n\n'
              'We may suspend accounts for suspicious activity.',
            ),
            _buildSection(
              '3. App Usage',
              'You agree NOT to:\n\n'
              '• Use the app for illegal purposes\n'
              '• Interfere with app functionality\n'
              '• Reverse engineer or copy the app\n'
              '• Upload harmful files\n\n'
              'UnitWise is for personal use only.',
            ),
            _buildSection(
              '4. Features & Services',
              'UnitWise provides:\n\n'
              '• Token purchase tracking\n'
              '• Usage predictions and forecasting\n'
              '• Low-unit notifications\n'
              '• Appliance estimation & budgeting\n'
              '• Historical usage display\n\n'
              'Services may evolve, pause, or discontinue without notice.',
            ),
            _buildSection(
              '5. Data Accuracy & Limitations',
              'UnitWise provides estimated information only.\n\n'
              'We:\n\n'
              '• Are not a utility company\n'
              '• Do NOT sell tokens\n'
              '• Do NOT guarantee consumption accuracy\n'
              '• Do NOT control electricity supply\n'
              '• Are NOT responsible for outages, billing, or delays\n\n'
              'Users must verify token entries and consumption logs.',
            ),
            _buildSection(
              '6. Alerts & Notifications',
              'Low-unit alerts and predictions are best-effort estimates.\n'
              'We are not responsible for losses related to:\n\n'
              '• Missed notifications\n'
              '• Inaccurate predictions\n'
              '• Changes in power supply',
            ),
            _buildSection(
              '7. Intellectual Property',
              'All content, features, designs, and trademarks within UnitWise belong to PowerView Labs Limited.\n\n'
              'You may not modify, copy, sell, or resell the App or its data.',
            ),
            _buildSection(
              '8. Subscription & Fees',
              '(Optional future clause)\n\n'
              'Some features may require subscription.\n'
              'Price and features may change with notice.',
            ),
            _buildSection(
              '9. Termination',
              'We may suspend or terminate your account if:\n\n'
              '• You violate these terms\n'
              '• You misuse the platform\n\n'
              'You may delete your account anytime.',
            ),
            _buildSection(
              '10. Limitation of Liability',
              'PowerView Labs Limited is not liable for:\n\n'
              '• Financial losses\n'
              '• Token purchase errors\n'
              '• Blackouts/outages\n'
              '• Billing disagreements\n'
              '• App unavailability\n'
              '• Data loss\n'
              '• Inaccurate predictions\n\n'
              'USE THE APP AT YOUR OWN RISK.',
            ),
            _buildSection(
              '11. Indemnification',
              'You agree to indemnify PowerView Labs Limited from claims arising from:\n\n'
              '• Misuse\n'
              '• Violations of these Terms\n'
              '• Third-party disputes',
            ),
            _buildSection(
              '12. Governing Law',
              'These Terms are governed by the laws of Nigeria.\n\n'
              'Any dispute will be resolved under Nigerian jurisdiction.',
            ),
            _buildSection(
              '13. Changes to Terms',
              'We may update these Terms periodically.\n\n'
              'Continued use = Acceptance of updates.',
            ),
            _buildSection(
              '14. Contact Us',
              'For questions or complaints:\n'
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
