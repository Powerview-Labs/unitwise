import 'package:flutter/material.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Shortcut Buttons - Quick action buttons for navigation
/// 
/// FEATURES:
/// - Two-column grid layout
/// - Icons with labels
/// - Navigation callbacks
/// 
/// BUTTONS:
/// - Appliances → Navigate to estimator
/// - Budget → Navigate to budget planner
class ShortcutButtons extends StatelessWidget {
  final VoidCallback onAppliancesPressed;
  final VoidCallback onBudgetPressed;
  
  const ShortcutButtons({
    super.key,
    required this.onAppliancesPressed,
    required this.onBudgetPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DashboardConstants.quickActionsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ShortcutButton(
                icon: Icons.device_hub,
                label: DashboardConstants.appliancesButton,
                onPressed: onAppliancesPressed,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ShortcutButton(
                icon: Icons.calendar_month,
                label: DashboardConstants.budgetButton,
                onPressed: onBudgetPressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Individual shortcut button
class _ShortcutButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  
  const _ShortcutButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
