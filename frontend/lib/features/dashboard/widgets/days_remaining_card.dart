import 'package:flutter/material.dart';
import '../models/dashboard_state.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Days Remaining Card - Shows estimated days until unit depletion
/// 
/// FEATURES:
/// - Only shown if estimator is completed
/// - Large days display
/// - Warning when days < 2
/// - "~Estimated" label
/// 
/// BEHAVIOR:
/// - Hidden if hasEstimatorCompleted = false
/// - Shows recharge warning if days < 2
class DaysRemainingCard extends StatelessWidget {
  final DashboardState state;
  
  const DaysRemainingCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Only show if estimator is completed
    if (!state.hasEstimatorCompleted) {
      return const SizedBox.shrink();
    }
    
    final days = state.daysRemaining ?? 0.0;
    final isLowDays = days < 2.0;
    final displayColor = isLowDays 
        ? DashboardConstants.dangerColor 
        : DashboardConstants.safeColor;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DashboardConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              DashboardConstants.daysRemainingLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Days display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '~${days.toStringAsFixed(1)}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'days',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            // Warning if low days
            if (isLowDays) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardConstants.dangerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DashboardConstants.dangerColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: DashboardConstants.dangerColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Consider recharging soon',
                        style: TextStyle(
                          color: DashboardConstants.dangerColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
