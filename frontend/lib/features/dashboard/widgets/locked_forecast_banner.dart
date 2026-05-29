import 'package:flutter/material.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Locked Forecast Banner - Shows when estimator is not completed
/// 
/// FEATURES:
/// - Prominent yellow/amber styling
/// - Clear message about locked forecasts
/// - Call-to-action button
/// - Lock icon
/// 
/// BEHAVIOR:
/// - Only shown when hasEstimatorCompleted = false
/// - Clicking "Set Up" navigates to appliance estimator
class LockedForecastBanner extends StatelessWidget {
  final VoidCallback onCompleteEstimator;
  
  const LockedForecastBanner({
    super.key,
    required this.onCompleteEstimator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        border: Border.all(color: Colors.amber[700]!, width: 1.5),
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: Colors.amber[900],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DashboardConstants.estimatorLockedTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DashboardConstants.estimatorLockedMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onCompleteEstimator,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              DashboardConstants.estimatorLockedAction,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
