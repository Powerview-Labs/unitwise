/**
 * Smart Tooltip Widget
 * 
 * Context-aware tooltip that provides intelligent hints based on appliance data.
 * Triggers on high wattage, high hours, or high daily consumption.
 * 
 * Security: Read-only data, no user input
 * UX: Non-intrusive hints that guide users to optimize consumption
 */

import 'package:flutter/material.dart';
import '../../../constants/estimator/estimator_constants.dart';

enum TooltipTrigger {
  highWattage,
  highHours,
  highDailyUnits,
}

class SmartTooltipWidget extends StatelessWidget {
  final TooltipTrigger trigger;
  final double value;
  final Widget child;

  const SmartTooltipWidget({
    super.key,
    required this.trigger,
    required this.value,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Only show tooltip if threshold is exceeded
    if (!_shouldShowTooltip()) {
      return child;
    }

    return Tooltip(
      message: _getTooltipMessage(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _getTooltipColor(),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      preferBelow: false,
      verticalOffset: 8,
      waitDuration: const Duration(milliseconds: 500),
      child: _buildTooltipTrigger(),
    );
  }

  /// Check if tooltip should be shown based on threshold
  bool _shouldShowTooltip() {
    switch (trigger) {
      case TooltipTrigger.highWattage:
        return value >= EstimatorConstants.highWattageThreshold;
      case TooltipTrigger.highHours:
        return value >= EstimatorConstants.highHoursThreshold;
      case TooltipTrigger.highDailyUnits:
        return value >= EstimatorConstants.highDailyUnitsThreshold;
    }
  }

  /// Get tooltip message based on trigger type
  String _getTooltipMessage() {
    switch (trigger) {
      case TooltipTrigger.highWattage:
        return 'High power consumption! Consider using this appliance less frequently.';
      case TooltipTrigger.highHours:
        return 'Running for many hours! Reducing usage time can save significant energy.';
      case TooltipTrigger.highDailyUnits:
        return 'This appliance uses a lot of electricity! Review your usage patterns.';
    }
  }

  /// Get tooltip color based on trigger type
  Color _getTooltipColor() {
    switch (trigger) {
      case TooltipTrigger.highWattage:
        return EstimatorConstants.warningRed;
      case TooltipTrigger.highHours:
        return EstimatorConstants.warningAmber;
      case TooltipTrigger.highDailyUnits:
        return EstimatorConstants.warningRed;
    }
  }

  /// Get icon based on trigger type
  IconData _getTooltipIcon() {
    switch (trigger) {
      case TooltipTrigger.highWattage:
        return Icons.bolt;
      case TooltipTrigger.highHours:
        return Icons.access_time;
      case TooltipTrigger.highDailyUnits:
        return Icons.warning_amber_rounded;
    }
  }

  /// Build the visual trigger indicator
  Widget _buildTooltipTrigger() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: 4),
        Icon(
          _getTooltipIcon(),
          size: 16,
          color: _getTooltipColor(),
        ),
      ],
    );
  }
}

/// Extension for easy tooltip wrapping
extension SmartTooltipExtension on Widget {
  /// Wrap widget with smart tooltip for high wattage
  Widget withWattageTooltip(double wattage) {
    return SmartTooltipWidget(
      trigger: TooltipTrigger.highWattage,
      value: wattage,
      child: this,
    );
  }

  /// Wrap widget with smart tooltip for high hours
  Widget withHoursTooltip(double hours) {
    return SmartTooltipWidget(
      trigger: TooltipTrigger.highHours,
      value: hours,
      child: this,
    );
  }

  /// Wrap widget with smart tooltip for high daily units
  Widget withUnitsTooltip(double units) {
    return SmartTooltipWidget(
      trigger: TooltipTrigger.highDailyUnits,
      value: units,
      child: this,
    );
  }
}
