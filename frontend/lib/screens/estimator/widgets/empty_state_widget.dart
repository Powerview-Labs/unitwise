/**
 * Empty State Widget
 * 
 * Displays a friendly empty state when the appliance list is empty.
 * Provides clear call-to-action buttons to guide users.
 * 
 * Security: No user data, just UI elements
 * UX: Encourages user action with friendly messaging and clear CTAs
 */

import 'package:flutter/material.dart';
import '../../../constants/estimator/estimator_constants.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback? onAddAppliance;
  final VoidCallback? onLoadDefaults;

  const EmptyStateWidget({
    super.key,
    this.onAddAppliance,
    this.onLoadDefaults,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(context),
            const SizedBox(height: 24),
            _buildMessage(context),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Build the empty state illustration
  Widget _buildIllustration(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: EstimatorConstants.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.devices_other,
        size: 60,
        color: EstimatorConstants.primaryBlue.withOpacity(0.6),
      ),
    );
  }

  /// Build the empty state message
  Widget _buildMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'No Appliances Yet',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Add your appliances to calculate\nyour daily electricity consumption',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build the action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action: Add Appliance
        if (onAddAppliance != null)
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: onAddAppliance,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Appliance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EstimatorConstants.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        
        // Secondary action: Load Defaults
        if (onLoadDefaults != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: OutlinedButton.icon(
              onPressed: onLoadDefaults,
              icon: const Icon(Icons.list_alt, size: 20),
              label: const Text('Load Defaults'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EstimatorConstants.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                side: BorderSide(
                  color: EstimatorConstants.primaryBlue,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Simplified empty state for smaller contexts
class EmptyStateCompactWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateCompactWidget({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
