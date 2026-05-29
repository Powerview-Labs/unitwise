import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_planner_provider.dart';
import '../utils/budget_constants.dart';

/// Displays calculation results: units, days, burn rate reference
class CalculationResultsCard extends StatelessWidget {
  const CalculationResultsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetPlannerProvider>(
      builder: (context, provider, child) {
        if (provider.calculatedUnits == null || provider.estimatedDays == null) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C896).withOpacity(0.1),
                  const Color(0xFF007BFF).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF00C896),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Your Estimate',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Units result
                _buildResultRow(
                  context,
                  label: 'Estimated Units',
                  value: BudgetConstants.formatUnits(provider.calculatedUnits!),
                  icon: Icons.bolt,
                  color: const Color(0xFFFFA726), // Amber
                ),
                const Divider(height: 24),

                // Days result
                _buildResultRow(
                  context,
                  label: 'Coverage Duration',
                  value: BudgetConstants.formatDays(provider.estimatedDays!),
                  icon: Icons.calendar_today,
                  color: const Color(0xFF00C896), // Electric Green
                ),
                const Divider(height: 24),

                // Burn rate reference
                _buildResultRow(
                  context,
                  label: 'Your Daily Burn Rate',
                  value: BudgetConstants.formatUnits(provider.currentBurnRate!),
                  icon: Icons.trending_up,
                  color: const Color(0xFF007BFF), // Energy Blue
                  isReference: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isReference = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontFamily: 'Inter',
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: isReference ? Colors.grey[700] : Colors.black,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
