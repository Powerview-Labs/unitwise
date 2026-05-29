import 'package:flutter/material.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Last Updated Timestamp - Shows when dashboard was last refreshed
/// 
/// FEATURES:
/// - Displays formatted timestamp
/// - Refresh icon
/// - Grey subtle styling
class LastUpdatedTimestamp extends StatelessWidget {
  final DateTime timestamp;
  
  const LastUpdatedTimestamp({
    super.key,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTime = DashboardConstants.formatLastUpdated(timestamp);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 6),
        Text(
          'Last updated: $formattedTime',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
