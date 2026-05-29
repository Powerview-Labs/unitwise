/**
 * Power Saver Tips Widget - FIXED
 *
 * Displays actionable power-saving recommendations for high-consumption appliances.
 * Shows expandable cards with tips, potential savings, and recommendations.
 *
 * Security: Read-only display of tip data
 * UX: Expandable cards prevent overwhelming users with too much info at once
 * 
 * FIXES: Added _getSavingsColor() and _getSavingsIcon() helper methods
 * to derive color/icon from tip data instead of accessing non-existent properties
 */

import 'package:flutter/material.dart';
import '../../../models/power_saver_tip_model.dart';
import '../../../constants/estimator/estimator_constants.dart';
import '../../../utils/estimator/estimator_extensions.dart';

class PowerSaverTipsWidget extends StatefulWidget {
  final List<PowerSaverTip> tips;
  final VoidCallback? onDismiss;

  const PowerSaverTipsWidget({
    super.key,
    required this.tips,
    this.onDismiss,
  });

  @override
  State<PowerSaverTipsWidget> createState() => _PowerSaverTipsWidgetState();
}

class _PowerSaverTipsWidgetState extends State<PowerSaverTipsWidget> {
  final Set<String> _expandedTips = {};

  // ✅ NEW: Helper to get color based on savings amount
  Color _getSavingsColor(double unitsSaved) {
    if (unitsSaved >= 2.0) {
      return EstimatorConstants.warningRed; // High savings opportunity
    } else if (unitsSaved >= 1.0) {
      return Colors.orange; // Medium savings
    } else {
      return EstimatorConstants.successGreen; // Low but good savings
    }
  }

  // ✅ NEW: Helper to get icon based on savings amount
  IconData _getSavingsIcon(double unitsSaved) {
    if (unitsSaved >= 2.0) {
      return Icons.warning_amber_rounded; // High consumption warning
    } else if (unitsSaved >= 1.0) {
      return Icons.info_outline; // Medium tip
    } else {
      return Icons.tips_and_updates; // General tip
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          _buildTipsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: EstimatorConstants.successGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Power Saving Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${widget.tips.length} ${widget.tips.length == 1 ? 'tip' : 'tips'} to reduce consumption',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          if (widget.onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: widget.onDismiss,
              tooltip: 'Dismiss tips',
            ),
        ],
      ),
    );
  }

  Widget _buildTipsList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.tips.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tip = widget.tips[index];
        return _buildTipCard(context, tip);
      },
    );
  }

  Widget _buildTipCard(BuildContext context, PowerSaverTip tip) {
    final isExpanded = _expandedTips.contains(tip.applianceName);

    return InkWell(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedTips.remove(tip.applianceName);
          } else {
            _expandedTips.add(tip.applianceName);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipHeader(context, tip, isExpanded),
            if (isExpanded) ...[
              const SizedBox(height: 12),
              _buildTipDetails(context, tip),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipHeader(BuildContext context, PowerSaverTip tip, bool isExpanded) {
    // ✅ FIXED: Use helper methods instead of tip.color and tip.icon
    final tipColor = _getSavingsColor(tip.unitsSavedPerDay);
    final tipIcon = _getSavingsIcon(tip.unitsSavedPerDay);
    
    return Row(
      children: [
        // Tip icon with color coding
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            tipIcon,
            color: tipColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Appliance name and savings
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tip.applianceName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Save ${tip.unitsSavedPerDay.toDisplayString()} units/day',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tipColor, // ✅ FIXED: Use local variable
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        // Expand/collapse icon
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey[600],
        ),
      ],
    );
  }

  Widget _buildTipDetails(BuildContext context, PowerSaverTip tip) {
    // ✅ FIXED: Use helper method
    final tipColor = _getSavingsColor(tip.unitsSavedPerDay);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recommendation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: EstimatorConstants.successGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tip.recommendation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Savings breakdown
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tipColor.withOpacity(0.05), // ✅ FIXED: Use local variable
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily savings:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  '${tip.unitsSavedPerDay.toDisplayString()} units',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: tipColor, // ✅ FIXED: Use local variable
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
