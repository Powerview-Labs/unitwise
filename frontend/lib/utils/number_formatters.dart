import 'package:intl/intl.dart';
import '../config/app_config.dart';

/// Number formatting utilities for Appliance Estimator displays
/// 
/// These functions format numbers for user-friendly display.
class ApplianceFormatters {
  // Prevent instantiation
  ApplianceFormatters._();
  
  // ========================================================================
  // UNITS FORMATTING
  // ========================================================================
  
  /// Format units for display
  /// 
  /// Examples:
  ///   formatUnits(16.24) → "16.2 units/day"
  ///   formatUnits(16.24, showSuffix: false) → "16.2"
  static String formatUnits(double units, {bool showSuffix = true}) {
    final formatted = units.toStringAsFixed(AppConfig.decimalPlacesDisplay);
    return showSuffix ? '$formatted units/day' : formatted;
  }
  
  /// Format units with precision
  /// 
  /// Examples:
  ///   formatUnitsPrecise(16.2456, 2) → "16.25"
  static String formatUnitsPrecise(double units, int decimalPlaces) {
    return units.toStringAsFixed(decimalPlaces);
  }
  
  // ========================================================================
  // CURRENCY FORMATTING
  // ========================================================================
  
  /// Format Naira currency
  /// 
  /// Examples:
  ///   formatNaira(5000) → "₦5,000"
  ///   formatNaira(5432.67) → "₦5,433"
  static String formatNaira(double amount, {bool showDecimals = false}) {
    final formatter = NumberFormat.currency(
      symbol: '₦',
      decimalDigits: showDecimals ? 2 : 0,
      locale: 'en_NG',
    );
    return formatter.format(amount);
  }
  
  /// Format Naira compactly (for tips)
  /// 
  /// Examples:
  ///   formatNairaCompact(5000) → "₦5K"
  ///   formatNairaCompact(1500000) → "₦1.5M"
  static String formatNairaCompact(double amount) {
    if (amount >= 1000000) {
      return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₦${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatNaira(amount);
  }
  
  // ========================================================================
  // HOURS FORMATTING
  // ========================================================================
  
  /// Format hours for display
  /// 
  /// Examples:
  ///   formatHours(12) → "12 hrs/day"
  ///   formatHours(12.5) → "12.5 hrs/day"
  ///   formatHours(12, showSuffix: false) → "12"
  static String formatHours(double hours, {bool showSuffix = true}) {
    final formatted = hours % 1 == 0 
        ? hours.toInt().toString()
        : hours.toStringAsFixed(1);
    return showSuffix ? '$formatted hrs/day' : formatted;
  }
  
  /// Format hours range
  /// 
  /// Examples:
  ///   formatHoursRange(8, 12) → "8-12 hrs"
  static String formatHoursRange(double minHours, double maxHours) {
    final min = formatHours(minHours, showSuffix: false);
    final max = formatHours(maxHours, showSuffix: false);
    return '$min-$max hrs';
  }
  
  // ========================================================================
  // WATTAGE FORMATTING
  // ========================================================================
  
  /// Format wattage for display
  /// 
  /// Examples:
  ///   formatWattage(1000) → "1,000W"
  ///   formatWattage(50) → "50W"
  static String formatWattage(double wattage) {
    final formatter = NumberFormat('#,###');
    final formatted = wattage % 1 == 0 
        ? formatter.format(wattage.toInt())
        : wattage.toStringAsFixed(1);
    return '${formatted}W';
  }
  
  /// Format wattage compactly
  /// 
  /// Examples:
  ///   formatWattageCompact(1000) → "1kW"
  ///   formatWattageCompact(2500) → "2.5kW"
  static String formatWattageCompact(double wattage) {
    if (wattage >= 1000) {
      return '${(wattage / 1000).toStringAsFixed(1)}kW';
    }
    return formatWattage(wattage);
  }
  
  // ========================================================================
  // QUANTITY FORMATTING
  // ========================================================================
  
  /// Format quantity for display
  /// 
  /// Examples:
  ///   formatQuantity(1) → "1"
  ///   formatQuantity(5) → "5"
  static String formatQuantity(int quantity) {
    return quantity.toString();
  }
  
  /// Format quantity with units
  /// 
  /// Examples:
  ///   formatQuantityWithUnit(1, 'TV') → "1 TV"
  ///   formatQuantityWithUnit(3, 'fan') → "3 fans"
  static String formatQuantityWithUnit(int quantity, String unit) {
    if (quantity == 1) {
      return '1 $unit';
    }
    // Simple pluralization (add 's')
    final plural = unit.endsWith('s') ? unit : '${unit}s';
    return '$quantity $plural';
  }
  
  // ========================================================================
  // PERCENTAGE FORMATTING
  // ========================================================================
  
  /// Format percentage
  /// 
  /// Examples:
  ///   formatPercentage(0.15) → "15%"
  ///   formatPercentage(0.8542) → "85%"
  static String formatPercentage(double value, {int decimals = 0}) {
    final percent = value * 100;
    return '${percent.toStringAsFixed(decimals)}%';
  }
  
  // ========================================================================
  // DURATION FORMATTING
  // ========================================================================
  
  /// Format duration in days
  /// 
  /// Examples:
  ///   formatDays(5.2) → "5.2 days"
  ///   formatDays(1) → "1 day"
  ///   formatDays(0.5) → "0.5 days"
  static String formatDays(double days) {
    final formatted = days.toStringAsFixed(1);
    return days == 1.0 ? '$formatted day' : '$formatted days';
  }
  
  // ========================================================================
  // COMPARISON FORMATTING
  // ========================================================================
  
  /// Format before/after comparison
  /// 
  /// Examples:
  ///   formatBeforeAfter(16.8, 14.3, 'units/day') → "16.8 → 14.3 units/day"
  static String formatBeforeAfter(
    double before,
    double after,
    String unit,
  ) {
    final beforeStr = before.toStringAsFixed(1);
    final afterStr = after.toStringAsFixed(1);
    return '$beforeStr → $afterStr $unit';
  }
  
  /// Format savings
  /// 
  /// Examples:
  ///   formatSavings(2.5, 'units/day') → "Save 2.5 units/day"
  static String formatSavings(double amount, String unit) {
    final formatted = amount.toStringAsFixed(1);
    return 'Save $formatted $unit';
  }
}
