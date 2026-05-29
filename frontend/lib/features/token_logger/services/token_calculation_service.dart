// lib/features/token_logger/services/token_calculation_service.dart

import 'package:intl/intl.dart';

/// Token Calculation Service
/// 
/// RESPONSIBILITIES:
///   1. Calculate units from amount paid
///   2. Calculate elapsed burn for past purchases
///   3. Estimate remaining units at time of log
/// 
/// MODULE BOUNDARIES:
///   - Does NOT own balance evolution (that's Dashboard's job)
///   - Does NOT track ongoing consumption
///   - Only calculates snapshot at log time
class TokenCalculationService {
  
  /// Calculate units purchased from amount paid
  /// 
  /// FORMULA: units = amount_paid ÷ unit_rate
  /// ROUNDING: To 1 decimal place for user display
  /// 
  /// SECURITY: Validates inputs are positive numbers
  /// ERROR HANDLING: Returns 0 if calculation fails
  static double calculateUnitsPurchased({
    required double amountPaid,
    required double unitRate,
  }) {
    // SECURITY: Validate inputs
    if (amountPaid <= 0 || unitRate <= 0) {
      return 0.0;
    }

    // Calculate units
    final units = amountPaid / unitRate;

    // Round to 1 decimal place
    return double.parse(units.toStringAsFixed(1));
  }

  /// Calculate estimated burn for past purchases
  /// 
  /// PURPOSE: When user logs a token bought days ago, estimate usage since then
  /// 
  /// INPUTS:
  ///   - purchaseDate: When token was actually bought
  ///   - dailyBurnRate: From Appliance Estimator
  /// 
  /// FORMULA:
  ///   days_elapsed = today - purchase_date
  ///   estimated_burn = daily_burn_rate × days_elapsed
  /// 
  /// EDGE CASES:
  ///   - If purchaseDate is today, returns 0
  ///   - If purchaseDate is future, returns 0 (invalid)
  static double calculateElapsedBurn({
    required DateTime purchaseDate,
    required double dailyBurnRate,
  }) {
    final today = DateTime.now();
    
    // Normalize dates to midnight for accurate day calculation
    final purchaseDateMidnight = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    final todayMidnight = DateTime(
      today.year,
      today.month,
      today.day,
    );

    // Calculate days elapsed
    final daysElapsed = todayMidnight.difference(purchaseDateMidnight).inDays;

    // EDGE CASE: Purchase date is today or future
    if (daysElapsed <= 0) {
      return 0.0;
    }

    // Calculate estimated burn
    final estimatedBurn = dailyBurnRate * daysElapsed;

    // Round to 1 decimal place
    return double.parse(estimatedBurn.toStringAsFixed(1));
  }

  /// Calculate estimated remaining units at time of log
  /// 
  /// PURPOSE: Show user realistic remaining balance for past purchases
  /// 
  /// FORMULA:
  ///   estimated_remaining = units_purchased - estimated_burn
  /// 
  /// EDGE CASE: If result is negative, clamp to 0
  /// REASON: User may have already run out, but we never show negative
  static double calculateEstimatedRemaining({
    required double unitsPurchased,
    required double estimatedBurn,
  }) {
    final remaining = unitsPurchased - estimatedBurn;

    // EDGE CASE: Clamp to 0 if negative
    if (remaining < 0) {
      return 0.0;
    }

    // Round to 1 decimal place
    return double.parse(remaining.toStringAsFixed(1));
  }

  /// Get user-friendly explanation for elapsed burn
  /// 
  /// PURPOSE: Build trust by explaining calculation
  /// 
  /// RETURNS: Human-readable string like:
  ///   "This token was bought 7 days ago. We estimated usage during 
  ///    that period based on your appliance setup."
  static String getElapsedBurnExplanation({
    required DateTime purchaseDate,
    required double dailyBurnRate,
  }) {
    final today = DateTime.now();
    final daysElapsed = today.difference(purchaseDate).inDays;

    if (daysElapsed <= 0) {
      return "Token logged for today. No past usage calculated.";
    }

    if (daysElapsed == 1) {
      return "This token was bought yesterday. We estimated usage during "
             "that period based on your appliance setup (${dailyBurnRate.toStringAsFixed(1)} units/day).";
    }

    return "This token was bought $daysElapsed days ago. We estimated usage during "
           "that period based on your appliance setup (${dailyBurnRate.toStringAsFixed(1)} units/day).";
  }

  /// Format amount for display
  /// 
  /// SECURITY: Prevents injection by using number formatting
  static String formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format units for display
  static String formatUnits(double units) {
    return '${units.toStringAsFixed(1)} units';
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }

  /// Validate purchase date
  /// 
  /// SECURITY: Prevent future dates or absurdly old dates
  /// BOUNDS: Date must be within last 365 days and not future
  static bool isValidPurchaseDate(DateTime date) {
    final today = DateTime.now();
    final oneYearAgo = today.subtract(const Duration(days: 365));

    // Date must not be in the future
    if (date.isAfter(today)) {
      return false;
    }

    // Date must not be more than 1 year old
    if (date.isBefore(oneYearAgo)) {
      return false;
    }

    return true;
  }

  /// Validate amount paid
  /// 
  /// SECURITY: Prevent unrealistic amounts
  /// BOUNDS: ₦100 - ₦100,000 (reasonable range for Nigerian tokens)
  static bool isValidAmount(double amount) {
    return amount >= 100.0 && amount <= 100000.0;
  }

  /// Get warning message for low remaining units
  /// 
  /// PURPOSE: Alert user if past purchase may have already run out
  static String? getLowRemainingWarning(double estimatedRemaining) {
    if (estimatedRemaining <= 0) {
      return "⚠️ Based on your usage, these units may have already been consumed. "
             "You can manually adjust your balance on the Dashboard.";
    }

    if (estimatedRemaining < 5) {
      return "⚠️ Very low remaining units estimated. Consider recharging soon.";
    }

    return null; // No warning needed
  }

  /// Calculate estimated days covered by this token purchase
  /// 
  /// PURPOSE: Give user sense of how long token will last
  /// Only shown if estimator is complete
  static double? calculateDaysCovered({
    required double unitsPurchased,
    required double dailyBurnRate,
  }) {
    if (dailyBurnRate <= 0) {
      return null; // Cannot calculate without burn rate
    }

    final days = unitsPurchased / dailyBurnRate;
    return double.parse(days.toStringAsFixed(1));
  }
}
