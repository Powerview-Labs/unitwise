/**
 * Appliance Row Widget - WITH INLINE TIPS (FIXED)
 * 
 * Displays individual appliance with consumption badge and inline power saving tips.
 * Tips appear directly in the card for high-consumption appliances.
 * 
 * UX: Immediate visibility of power saving opportunities
 * Security: Read-only display of appliance data
 * 
 * FIXED: ConsumptionBadgeWidget parameter compatibility
 */

import 'package:flutter/material.dart';
import '../../../models/appliance_model.dart';
import '../../../models/power_saver_tip_model.dart';
import '../../../constants/estimator/estimator_constants.dart';
import 'category_icon_widget.dart';
import 'consumption_badge_widget.dart';

class ApplianceRowWidget extends StatelessWidget {
  final Appliance appliance;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final PowerSaverTip? tip; // ✅ NEW: Optional inline tip

  const ApplianceRowWidget({
    super.key,
    required this.appliance,
    required this.onTap,
    this.onDelete,
    this.tip, // ✅ NEW: Pass tip if exists
  });

  // ✅ NEW: Get color based on consumption level
  Color _getConsumptionColor(double units) {
    if (units >= 10.0) return EstimatorConstants.warningRed;
    if (units >= 5.0) return Colors.orange;
    return EstimatorConstants.successGreen;
  }

  // ✅ NEW: Get icon based on consumption level
  IconData _getConsumptionIcon(double units) {
    if (units >= 10.0) return Icons.warning_amber_rounded;
    if (units >= 5.0) return Icons.info_outline;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final units = appliance.dailyUnits;
    final showTip = tip != null && units >= 2.0; // Show tip for consumption >= 2 units

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: showTip
            ? BorderSide(color: _getConsumptionColor(units), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main appliance info
              Row(
                children: [
                  // Category icon
                  CategoryIconWidget(
                    category: appliance.category,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  
                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appliance.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appliance.wattage.toInt()}W × ${appliance.quantity} × ${appliance.hoursPerDay.toStringAsFixed(1)} hrs',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Consumption badge - try without size parameter
                  ConsumptionBadgeWidget(
                    dailyUnits: units,
                  ),
                  
                  // Delete button
                  if (onDelete != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: EstimatorConstants.warningRed,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
              
              // ✅ NEW: Inline Power Saving Tip
              if (showTip) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getConsumptionColor(units).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getConsumptionColor(units).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getConsumptionIcon(units),
                        color: _getConsumptionColor(units),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  size: 16,
                                  color: _getConsumptionColor(units),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Power Saving Tip',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getConsumptionColor(units),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip!.recommendation,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.electric_bolt,
                                  size: 14,
                                  color: EstimatorConstants.successGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Save ${tip!.unitsSavedPerDay.toStringAsFixed(1)} units/day',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: EstimatorConstants.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}