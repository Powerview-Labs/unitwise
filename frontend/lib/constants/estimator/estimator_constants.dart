/**
 * Appliance Estimator UI Constants
 * 
 * Centralized constants for the Appliance Estimator module.
 * Includes colors, measurements, thresholds, and timing values.
 * 
 * Security: No sensitive data - only UI constants
 * Performance: Const values for compile-time optimization
 */

import 'package:flutter/material.dart';

/// UI Constants for Appliance Estimator Module
class EstimatorConstants {
  EstimatorConstants._(); // Private constructor - utility class

  // ============================================================================
  // COLORS (Energy Blue + Electric Green Theme)
  // ============================================================================

  /// Primary brand color - Energy Blue
  static const Color primaryBlue = Color(0xFF007BFF);

  /// Secondary brand color - Electric Green
  static const Color accentGreen = Color(0xFF00C896);

  /// Warning color for high consumption
  static const Color warningRed = Color(0xFFDC3545);

  /// Warning color (amber) for medium consumption
  static const Color warningAmber = Color(0xFFFFC107);

  /// Success color for low consumption
  static const Color successGreen = Color(0xFF28A745);

  /// Background color for cards
  static const Color cardBackground = Color(0xFFFAFAFA);

  /// Text color - primary (dark)
  static const Color textPrimary = Color(0xFF212529);

  /// Text color - secondary (gray)
  static const Color textSecondary = Color(0xFF6C757D);

  /// Text color - hint (light gray)
  static const Color textHint = Color(0xFFADB5BD);

  /// Divider color
  static const Color dividerColor = Color(0xFFDEE2E6);

  // ============================================================================
  // MEASUREMENTS & SPACING
  // ============================================================================

  /// Standard padding - small (8dp)
  static const double paddingSmall = 8.0;

  /// Standard padding - medium (16dp)
  static const double paddingMedium = 16.0;

  /// Standard padding - large (24dp)
  static const double paddingLarge = 24.0;

  /// Standard padding - extra large (32dp)
  static const double paddingExtraLarge = 32.0;

  /// Border radius for cards and buttons
  static const double borderRadius = 12.0;

  /// Border radius - small (for badges)
  static const double borderRadiusSmall = 6.0;

  /// Elevation for cards
  static const double cardElevation = 2.0;

  /// Elevation for dialogs
  static const double dialogElevation = 8.0;

  /// Icon size - small
  static const double iconSizeSmall = 20.0;

  /// Icon size - medium
  static const double iconSizeMedium = 24.0;

  /// Icon size - large
  static const double iconSizeLarge = 32.0;

  /// Minimum touch target size (accessibility)
  static const double minTouchTarget = 48.0;

  /// Appliance row height
  static const double applianceRowHeight = 80.0;

  /// Daily burn display height
  static const double dailyBurnDisplayHeight = 120.0;

  /// Tips card height
  static const double tipCardHeight = 100.0;

  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================

  /// Font family - headings (Poppins)
  static const String fontFamilyHeading = 'Poppins';

  /// Font family - body text (Inter)
  static const String fontFamilyBody = 'Inter';

  /// Font size - heading 1 (large)
  static const double fontSizeH1 = 32.0;

  /// Font size - heading 2 (medium)
  static const double fontSizeH2 = 24.0;

  /// Font size - heading 3 (small)
  static const double fontSizeH3 = 20.0;

  /// Font size - body text
  static const double fontSizeBody = 16.0;

  /// Font size - caption/secondary text
  static const double fontSizeCaption = 14.0;

  /// Font size - small labels
  static const double fontSizeSmall = 12.0;

  // ============================================================================
  // CONSUMPTION THRESHOLDS
  // ============================================================================

  /// High wattage threshold (watts) - triggers tip
  static const double highWattageThreshold = 500.0;

  /// High daily units threshold - triggers tip
  static const double highDailyUnitsThreshold = 2.5;

  /// High hours threshold - triggers tip
  static const double highHoursThreshold = 8.0;

  /// Very high consumption threshold for red badge (units/day)
  static const double veryHighConsumptionThreshold = 5.0;

  /// Medium consumption threshold for amber badge (units/day)
  static const double mediumConsumptionThreshold = 2.0;

  // ============================================================================
  // ANIMATION & TIMING
  // ============================================================================

  /// Standard animation duration
  static const Duration animationDuration = Duration(milliseconds: 250);

  /// Fast animation duration
  static const Duration animationDurationFast = Duration(milliseconds: 150);

  /// Slow animation duration
  static const Duration animationDurationSlow = Duration(milliseconds: 400);

  /// Auto-save debounce duration (wait after last edit before saving)
  /// Security: Prevents excessive writes to encrypted storage
  static const Duration autoSaveDebounce = Duration(seconds: 1);

  /// Snackbar display duration
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Tip card auto-scroll duration
  static const Duration tipAutoScrollDuration = Duration(seconds: 5);

  // ============================================================================
  // VALIDATION LIMITS
  // ============================================================================

  /// Minimum appliance name length
  static const int minNameLength = 1;

  /// Maximum appliance name length
  /// Security: Prevents excessively long inputs
  static const int maxNameLength = 50;

  /// Minimum wattage value
  static const double minWattage = 1.0;

  /// Maximum wattage value (realistic upper limit)
  /// Security: Prevents unrealistic/malicious inputs
  static const double maxWattage = 10000.0;

  /// Minimum hours per day
  static const double minHours = 0.1;

  /// Maximum hours per day
  static const double maxHours = 24.0;

  /// Minimum quantity
  static const int minQuantity = 1;

  /// Maximum quantity
  /// Security: Prevents unrealistic quantities
  static const int maxQuantity = 99;

  /// Maximum number of appliances allowed
  /// Performance: Prevents UI lag with too many items
  static const int maxAppliances = 100;

  // ============================================================================
  // UI BEHAVIOR
  // ============================================================================

  /// Number of default appliances to show initially
  static const int initialDefaultsToShow = 10;

  /// Maximum tips to display at once
  static const int maxTipsToShow = 3;

  /// Scroll threshold for showing FAB (pixels)
  static const double fabScrollThreshold = 100.0;

  /// Empty state icon size
  static const double emptyStateIconSize = 80.0;

  // ============================================================================
  // CATEGORIES
  // ============================================================================

  /// Available appliance categories
  static const List<String> categories = [
    'Lighting',
    'Kitchen',
    'Cooling',
    'Heating',
    'Entertainment',
    'Office',
    'Laundry',
    'Other',
  ];

  /// Category icons (maps to Icon.name)
  static const Map<String, IconData> categoryIcons = {
    'Lighting': Icons.lightbulb_outline,
    'Kitchen': Icons.kitchen_outlined,
    'Cooling': Icons.ac_unit,
    'Heating': Icons.local_fire_department,
    'Entertainment': Icons.tv,
    'Office': Icons.computer,
    'Laundry': Icons.local_laundry_service,
    'Other': Icons.devices_other,
  };

  // ============================================================================
  // ACCESSIBILITY
  // ============================================================================

  /// Semantic label for daily burn display
  static const String semanticDailyBurn = 'Total daily electricity consumption';

  /// Semantic label for add button
  static const String semanticAddAppliance = 'Add new appliance';

  /// Semantic label for delete button
  static const String semanticDeleteAppliance = 'Delete appliance';

  /// Semantic label for edit button
  static const String semanticEditAppliance = 'Edit appliance';
}
