import 'package:flutter/material.dart';
import '../models/dashboard_state.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Burn Status Indicator - Shows whether tracking is active or paused
/// 
/// STATES:
/// - Active: Green badge with "Tracking Active"
/// - Paused: Grey badge with "Paused (Outage Mode)" or "Manual Override Active"
/// 
/// LOGIC:
/// - Active when: NOT outage mode AND NOT manual override
/// - Paused when: outage mode OR manual override
class BurnStatusIndicator extends StatelessWidget {
  final DashboardState state;
  
  const BurnStatusIndicator({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = !state.outageModeActive && !state.manualOverride;
    
    // Determine status text
    String statusText;
    IconData statusIcon;
    
    if (state.manualOverride) {
      statusText = DashboardConstants.manualOverrideActive;
      statusIcon = Icons.edit;
    } else if (state.outageModeActive) {
      statusText = DashboardConstants.trackingPaused;
      statusIcon = Icons.pause_circle_outline;
    } else {
      statusText = DashboardConstants.trackingActive;
      statusIcon = Icons.track_changes;
    }
    
    final color = isActive 
        ? DashboardConstants.successColor 
        : Colors.grey[600]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive 
            ? DashboardConstants.successColor.withOpacity(0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive 
              ? DashboardConstants.successColor 
              : Colors.grey[400]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: color,
            size: DashboardConstants.statusIconSize,
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
