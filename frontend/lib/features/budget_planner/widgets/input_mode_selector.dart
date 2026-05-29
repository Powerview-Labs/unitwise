import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/budget_input_mode.dart';
import '../providers/budget_planner_provider.dart';

/// Toggle widget for switching between ₦ and units input
/// WHY: Enforces mutual exclusivity between input modes
class InputModeSelector extends StatelessWidget {
  const InputModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetPlannerProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  context,
                  mode: BudgetInputMode.budgetAmount,
                  label: 'Budget Amount',
                  icon: Icons.attach_money,
                  isSelected: provider.inputMode == BudgetInputMode.budgetAmount,
                  onTap: () {
                    provider.switchInputMode(BudgetInputMode.budgetAmount);
                  },
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  context,
                  mode: BudgetInputMode.targetUnits,
                  label: 'Target Units',
                  icon: Icons.bolt,
                  isSelected: provider.inputMode == BudgetInputMode.targetUnits,
                  onTap: () {
                    provider.switchInputMode(BudgetInputMode.targetUnits);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeButton(
    BuildContext context, {
    required BudgetInputMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007BFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
