import 'package:flutter/material.dart';
import '../models/dashboard_state.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Unit Balance Card - Shows estimated remaining units with color coding
/// 
/// FEATURES:
/// - Large unit display with color coding (blue/yellow/red)
/// - "~Estimated" label for trust preservation
/// - Status badge (Safe/Moderate/Low)
/// - Responsive layout
/// 
/// COLOR LOGIC:
/// - >30 units: Blue (Safe)
/// - 10-30 units: Yellow (Moderate)
/// - <10 units: Red (Danger)
class UnitBalanceCard extends StatelessWidget {
  final DashboardState state;
  
  const UnitBalanceCard({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final color = DashboardConstants.getColorForUnits(state.estimatedUnits);
    final statusLabel = DashboardConstants.getStatusLabelForUnits(state.estimatedUnits);
    final statusIcon = DashboardConstants.getIconForUnits(state.estimatedUnits);
    
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
            // Label with "Estimated" indicator
            Row(
              children: [
                Expanded(
                  child: Text(
                    DashboardConstants.unitsRemainingLabel,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DashboardConstants.estimatedLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Large unit display
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  state.estimatedUnits.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'units',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
