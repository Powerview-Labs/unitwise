import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_planner_provider.dart';
import '../utils/budget_constants.dart';

/// Displays current tariff rate, DisCo, and Band information
/// WHY: Transparency about what rate is being used in calculations
class RateInfoDisplay extends StatelessWidget {
  const RateInfoDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetPlannerProvider>(
      builder: (context, provider, child) {
        if (provider.currentRate == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF007BFF).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: const Color(0xFF007BFF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'Inter',
                          color: Colors.blue[900],
                        ),
                    children: [
                      TextSpan(
                        text: BudgetConstants.formatCurrency(provider.currentRate!),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const TextSpan(text: ' per unit • Band '),
                      TextSpan(
                        text: provider.band ?? '?',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' • '),
                      TextSpan(
                        text: provider.disco ?? 'Unknown DisCo',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
