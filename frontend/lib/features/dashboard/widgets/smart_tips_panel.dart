import 'package:flutter/material.dart';
import '../models/dashboard_state.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Smart Tips Panel - Shows power-saving suggestions
/// 
/// FEATURES:
/// - Displays suggestions from alert engine
/// - Clean card layout
/// - Lightbulb icon
/// - Empty state when no suggestions
/// 
/// BEHAVIOR:
/// - Shows up to 3 suggestions
/// - Hides if no suggestions available
class SmartTipsPanel extends StatelessWidget {
  final AlertState alerts;
  
  const SmartTipsPanel({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    // Hide if no suggestions
    if (alerts.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Power Saver Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Divider
            Divider(color: Colors.grey[300], height: 1),
            
            const SizedBox(height: 12),
            
            // Suggestions list
            ...alerts.suggestions.take(3).map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: DashboardConstants.successColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
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
  }
}
