import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_planner_provider.dart';

/// Button to save current calculation as a plan
/// WHY: Allows users to keep planning snapshots for reference
class SavePlanButton extends StatelessWidget {
  const SavePlanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetPlannerProvider>(
      builder: (context, provider, child) {
        return OutlinedButton.icon(
          onPressed: provider.calculatedUnits != null && !provider.isLoading
              ? () async {
                  await provider.savePlan();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Plan saved successfully!'),
                        backgroundColor: Color(0xFF00C896),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              : null,
          icon: provider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF007BFF),
                  ),
                )
              : const Icon(Icons.bookmark_add_outlined),
          label: const Text(
            'Save This Plan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF007BFF),
            side: const BorderSide(
              color: Color(0xFF007BFF),
              width: 2,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }
}
