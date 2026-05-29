/**
 * Category Icon Widget
 * 
 * Displays category-specific icons for appliances.
 * Provides consistent visual categorization across the app.
 * 
 * Security: Read-only icon display
 * UX: Visual categorization helps users quickly identify appliance types
 */

import 'package:flutter/material.dart';
import '../../../constants/estimator/estimator_constants.dart';

enum CategoryIconStyle {
  filled,
  outlined,
  minimal,
}

class CategoryIconWidget extends StatelessWidget {
  final String category;
  final double size;
  final CategoryIconStyle style;
  final Color? color;
  final bool showBackground;

  const CategoryIconWidget({
    super.key,
    required this.category,
    this.size = 24,
    this.style = CategoryIconStyle.filled,
    this.color,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getCategoryIcon(category);
    final iconColor = color ?? _getCategoryColor(category);

    switch (style) {
      case CategoryIconStyle.filled:
        return _buildFilledIcon(iconData, iconColor);
      case CategoryIconStyle.outlined:
        return _buildOutlinedIcon(iconData, iconColor);
      case CategoryIconStyle.minimal:
        return _buildMinimalIcon(iconData, iconColor);
    }
  }

  /// Build filled style icon (with background)
  Widget _buildFilledIcon(IconData iconData, Color iconColor) {
    if (!showBackground) {
      return Icon(iconData, size: size, color: iconColor);
    }

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        iconData,
        size: size,
        color: iconColor,
      ),
    );
  }

  /// Build outlined style icon (with border)
  Widget _buildOutlinedIcon(IconData iconData, Color iconColor) {
    if (!showBackground) {
      return Icon(iconData, size: size, color: iconColor);
    }

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        border: Border.all(color: iconColor.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        iconData,
        size: size,
        color: iconColor,
      ),
    );
  }

  /// Build minimal style icon (no background)
  Widget _buildMinimalIcon(IconData iconData, Color iconColor) {
    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }

  /// Get icon for category (from constants)
  IconData _getCategoryIcon(String category) {
    return EstimatorConstants.categoryIcons[category] ?? Icons.devices_other;
  }

  /// Get color for category
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return const Color(0xFFE57373); // Red
      case 'cooling':
        return const Color(0xFF64B5F6); // Blue
      case 'lighting':
        return const Color(0xFFFFF176); // Yellow
      case 'entertainment':
        return const Color(0xFFBA68C8); // Purple
      case 'laundry':
        return const Color(0xFF81C784); // Green
      case 'heating':
        return const Color(0xFFFF8A65); // Deep Orange
      case 'office':
        return const Color(0xFF90A4AE); // Blue Grey
      case 'security':
        return const Color(0xFF4DB6AC); // Teal
      default:
        return EstimatorConstants.primaryBlue;
    }
  }
}

/// Category icon with label
class CategoryIconWithLabelWidget extends StatelessWidget {
  final String category;
  final double iconSize;
  final CategoryIconStyle iconStyle;

  const CategoryIconWithLabelWidget({
    super.key,
    required this.category,
    this.iconSize = 20,
    this.iconStyle = CategoryIconStyle.filled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryIconWidget(
          category: category,
          size: iconSize,
          style: iconStyle,
        ),
        const SizedBox(width: 8),
        Text(
          _formatCategoryName(category),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  /// Format category name for display
  String _formatCategoryName(String category) {
    if (category.isEmpty) return 'Other';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }
}

/// Compact category badge
class CategoryBadgeWidget extends StatelessWidget {
  final String category;
  final bool compact;

  const CategoryBadgeWidget({
    super.key,
    required this.category,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          if (!compact) ...[
            const SizedBox(width: 4),
            Text(
              _formatCategoryName(category),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    return EstimatorConstants.categoryIcons[category] ?? Icons.devices_other;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'kitchen':
        return const Color(0xFFE57373);
      case 'cooling':
        return const Color(0xFF64B5F6);
      case 'lighting':
        return const Color(0xFFFFF176);
      case 'entertainment':
        return const Color(0xFFBA68C8);
      case 'laundry':
        return const Color(0xFF81C784);
      case 'heating':
        return const Color(0xFFFF8A65);
      case 'office':
        return const Color(0xFF90A4AE);
      case 'security':
        return const Color(0xFF4DB6AC);
      default:
        return EstimatorConstants.primaryBlue;
    }
  }

  String _formatCategoryName(String category) {
    if (category.isEmpty) return 'Other';
    return category[0].toUpperCase() + category.substring(1).toLowerCase();
  }
}
