import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_planner_provider.dart';
import '../models/power_saving_tip.dart';

/// Power Saving Tips Card Widget
/// 
/// Displays contextual tips based on budget calculations
class PowerSavingTipsCard extends StatelessWidget {
  const PowerSavingTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetPlannerProvider>(
      builder: (context, provider, child) {
        // Don't show if no tips
        if (provider.tips.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF00C896), // Electric Green
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Power Saving Tips',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tips list
                ...provider.tips.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTipIcon(tip.tipType),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Get icon emoji for tip type
  String _getTipIcon(TipType tipType) {
    switch (tipType) {
      case TipType.lowCoverage:
        return '⚠️';
      case TipType.highBurn:
        return '🔥';
      case TipType.insufficientBudget:
        return '💰';
      case TipType.applianceOptimization:
        return '💡';
      case TipType.generic:
        return 'ℹ️';
    }
  }
}
