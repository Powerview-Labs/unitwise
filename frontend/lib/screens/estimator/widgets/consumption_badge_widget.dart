/**
 * Consumption Badge Widget
 * 
 * Visual indicator for appliance consumption levels.
 * Color-coded badges: High (red), Medium (amber), Low (green).
 * 
 * Security: Read-only display
 * UX: Quick visual feedback on consumption levels
 */

import 'package:flutter/material.dart';
import '../../../constants/estimator/estimator_constants.dart';
import '../../../utils/estimator/estimator_extensions.dart';

enum BadgeSize {
  small,
  medium,
  large,
}

class ConsumptionBadgeWidget extends StatelessWidget {
  final double dailyUnits;
  final BadgeSize size;
  final bool showLabel;

  const ConsumptionBadgeWidget({
    super.key,
    required this.dailyUnits,
    this.size = BadgeSize.medium,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = dailyUnits.consumptionLevel();
    final color = dailyUnits.consumptionColor();

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(level),
            size: _getIconSize(),
            color: color,
          ),
          if (showLabel) ...[
            SizedBox(width: _getSpacing()),
            Text(
              _getLabel(level),
              style: TextStyle(
                fontSize: _getFontSize(),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get padding based on badge size
  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 6);
    }
  }

  /// Get border radius based on badge size
  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 4;
      case BadgeSize.medium:
        return 6;
      case BadgeSize.large:
        return 8;
    }
  }

  /// Get icon size based on badge size
  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 14;
      case BadgeSize.large:
        return 16;
    }
  }

  /// Get font size based on badge size
  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 10;
      case BadgeSize.medium:
        return 11;
      case BadgeSize.large:
        return 12;
    }
  }

  /// Get spacing between icon and label
  double _getSpacing() {
    switch (size) {
      case BadgeSize.small:
        return 3;
      case BadgeSize.medium:
        return 4;
      case BadgeSize.large:
        return 5;
    }
  }

  /// Get icon based on consumption level
  IconData _getIcon(String level) {
    switch (level) {
      case 'high':
        return Icons.trending_up;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.trending_down;
      default:
        return Icons.remove;
    }
  }

  /// Get label text based on consumption level
  String _getLabel(String level) {
    switch (level) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Unknown';
    }
  }
}

/// Compact version - just the colored dot
class ConsumptionDotWidget extends StatelessWidget {
  final double dailyUnits;
  final double size;

  const ConsumptionDotWidget({
    super.key,
    required this.dailyUnits,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    final color = dailyUnits.consumptionColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

/// Extension for easy badge usage
extension ConsumptionBadgeExtension on double {
  /// Get badge widget for this consumption value
  Widget toBadge({
    BadgeSize size = BadgeSize.medium,
    bool showLabel = true,
  }) {
    return ConsumptionBadgeWidget(
      dailyUnits: this,
      size: size,
      showLabel: showLabel,
    );
  }

  /// Get dot widget for this consumption value
  Widget toDot({double size = 8}) {
    return ConsumptionDotWidget(
      dailyUnits: this,
      size: size,
    );
  }
}
