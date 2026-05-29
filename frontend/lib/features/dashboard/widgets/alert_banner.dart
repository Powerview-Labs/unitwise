import 'package:flutter/material.dart';
import '../models/dashboard_state.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Alert Banner - Shows warnings and suggestions
/// 
/// FEATURES:
/// - Color-coded by severity (orange/red)
/// - Shows first suggestion prominently
/// - Appropriate icons
/// 
/// STATES:
/// - Hidden: No alerts
/// - Low: Orange warning
/// - Critical: Red alert
class AlertBanner extends StatelessWidget {
  final AlertState alerts;
  
  const AlertBanner({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show if no alerts
    if (!alerts.hasAlerts) {
      return const SizedBox.shrink();
    }
    
    final isCritical = alerts.critical;
    final color = isCritical 
        ? DashboardConstants.dangerColor 
        : DashboardConstants.moderateColor;
    
    final icon = isCritical 
        ? Icons.error 
        : Icons.warning;
    
    final title = isCritical 
        ? 'Critical!' 
        : 'Low Units';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 15,
                  ),
                ),
                if (alerts.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...alerts.suggestions.take(3).map((suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 13,
                              color: color,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
