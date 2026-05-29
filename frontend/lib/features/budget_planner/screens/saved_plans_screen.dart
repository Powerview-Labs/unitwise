import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_planner_provider.dart';
import '../widgets/saved_plan_list_item.dart';
import '../widgets/empty_state_widget.dart';

/// Screen displaying user's saved budget plans
/// WHY: Allows users to review and compare past planning scenarios
class SavedPlansScreen extends StatelessWidget {
  const SavedPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Plans'),
        backgroundColor: const Color(0xFF007BFF),
      ),
      body: Consumer<BudgetPlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007BFF),
              ),
            );
          }

          if (provider.savedPlans.isEmpty) {
            return const EmptyStateWidget();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshSavedPlans(),
            color: const Color(0xFF007BFF),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.savedPlans.length,
              itemBuilder: (context, index) {
                final plan = provider.savedPlans[index];
                return SavedPlanListItem(
                  plan: plan,
                  onDelete: () => _confirmDelete(context, provider, plan.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BudgetPlannerProvider provider,
    String planId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan?'),
        content: const Text(
          'Are you sure you want to delete this saved plan? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await provider.deletePlan(planId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
