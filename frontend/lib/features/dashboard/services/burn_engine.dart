import 'package:flutter/foundation.dart';
import '../models/burn_calculation_result.dart';

/// The core burn engine - handles automatic unit reduction over time
/// This is the HEART of the dashboard
/// 
/// RESPONSIBILITY:
/// - Calculate how many units have been consumed since last calculation
/// - Account for outage days (no consumption during outages)
/// - Ensure units never go below zero
/// - Round results for UX clarity
/// 
/// SECURITY:
/// - All inputs validated before calculation
/// - Handles edge cases (zero burn rate, extreme values)
/// - Never throws exceptions (returns safe results instead)
/// 
/// FORMULA:
/// effective_days = days_since_last_calculation − outage_days
/// estimated_remaining = starting_units − (daily_burn × effective_days)
class BurnEngine {
  /// Calculate reduced units based on elapsed time
  /// 
  /// This method implements the core burn logic that makes
  /// the dashboard "remember" consumption even when the app is closed.
  /// 
  /// Parameters:
  /// - [startingUnits]: Units at last calculation (from token log)
  /// - [dailyBurnRate]: Daily burn rate from Appliance Estimator
  /// - [lastCalculatedAt]: When was the last calculation performed
  /// - [outageDays]: How many days have been marked as outage
  /// 
  /// Returns: [BurnCalculationResult] with new estimated values
  /// 
  /// Throws: [ArgumentError] if inputs are invalid
  BurnCalculationResult calculateBurn({
    required double startingUnits,
    required double dailyBurnRate,
    required DateTime lastCalculatedAt,
    required int outageDays,
  }) {
    // SECURITY: Validate all inputs before proceeding
    _validateInputs(
      startingUnits: startingUnits,
      dailyBurnRate: dailyBurnRate,
      lastCalculatedAt: lastCalculatedAt,
      outageDays: outageDays,
    );

    final now = DateTime.now();
    
    // Calculate total days elapsed since last calculation
    final totalDaysElapsed = now.difference(lastCalculatedAt).inDays;
    
    if (kDebugMode) {
      debugPrint('═══════════════════════════════════════');
      debugPrint('[BurnEngine] Starting calculation');
      debugPrint('[BurnEngine] Total days elapsed: $totalDaysElapsed');
      debugPrint('[BurnEngine] Outage days: $outageDays');
    }
    
    // Calculate effective days (days when power was actually used)
    // Cannot be negative, and cannot exceed total days
    final effectiveDays = (totalDaysElapsed - outageDays).clamp(0, totalDaysElapsed);
    
    if (kDebugMode) {
      debugPrint('[BurnEngine] Effective days: $effectiveDays');
      debugPrint('[BurnEngine] Starting units: ${startingUnits.toStringAsFixed(1)}');
      debugPrint('[BurnEngine] Daily burn rate: ${dailyBurnRate.toStringAsFixed(1)}');
    }
    
    // Calculate total units burned during effective days
    final totalBurn = dailyBurnRate * effectiveDays;
    
    if (kDebugMode) {
      debugPrint('[BurnEngine] Total burn: ${totalBurn.toStringAsFixed(1)} units');
    }
    
    // Calculate remaining units
    // IMPORTANT: Never go below zero
    final estimatedRemaining = (startingUnits - totalBurn).clamp(0.0, double.infinity);
    
    // Calculate days remaining
    // If burn rate is 0, we can't estimate days (infinite)
    final daysRemaining = dailyBurnRate > 0 
        ? estimatedRemaining / dailyBurnRate 
        : 0.0;
    
    if (kDebugMode) {
      debugPrint('[BurnEngine] Remaining: ${estimatedRemaining.toStringAsFixed(1)} units');
      debugPrint('[BurnEngine] Days left: ${daysRemaining.toStringAsFixed(1)} days');
      debugPrint('═══════════════════════════════════════');
    }
    
    // Return result with rounded values for UX clarity
    return BurnCalculationResult(
      estimatedUnits: _roundForUX(estimatedRemaining),
      daysRemaining: _roundForUX(daysRemaining),
      calculatedAt: now,
      effectiveDays: effectiveDays,
      calculationMethod: 'auto',
      unitsBurned: _roundForUX(totalBurn),
    );
  }

  /// Check if burn engine should run
  /// Returns false if manual override or outage mode is active
  /// 
  /// This is used to prevent automatic calculations when:
  /// 1. User has manually set their unit balance
  /// 2. Power is currently out (outage mode)
  bool shouldRunBurnEngine({
    required bool manualOverride,
    required bool outageModeActive,
  }) {
    if (manualOverride) {
      if (kDebugMode) {
        debugPrint('[BurnEngine] ⏸️  Manual override active - burn engine paused');
      }
      return false;
    }
    
    if (outageModeActive) {
      if (kDebugMode) {
        debugPrint('[BurnEngine] ⏸️  Outage mode active - burn engine paused');
      }
      return false;
    }
    
    if (kDebugMode) {
      debugPrint('[BurnEngine] ▶️  Burn engine ready to run');
    }
    
    return true;
  }

  /// Calculate projected units at a specific future date
  /// Useful for budget planning and forecasting
  /// 
  /// Parameters:
  /// - [currentUnits]: Current unit balance
  /// - [dailyBurnRate]: Daily burn rate
  /// - [targetDate]: Date to project to
  /// 
  /// Returns: Estimated units at target date (never negative)
  double projectUnitsAtDate({
    required double currentUnits,
    required double dailyBurnRate,
    required DateTime targetDate,
  }) {
    final now = DateTime.now();
    final daysUntilTarget = targetDate.difference(now).inDays;
    
    if (daysUntilTarget <= 0) {
      // Target is in the past or today
      return currentUnits;
    }
    
    final projectedBurn = dailyBurnRate * daysUntilTarget;
    final projectedUnits = (currentUnits - projectedBurn).clamp(0.0, double.infinity);
    
    return _roundForUX(projectedUnits);
  }

  /// Calculate when units will be depleted
  /// Returns null if burn rate is 0 or units will never deplete
  DateTime? calculateDepletionDate({
    required double currentUnits,
    required double dailyBurnRate,
  }) {
    if (dailyBurnRate <= 0 || currentUnits <= 0) {
      return null;
    }
    
    final daysUntilDepletion = (currentUnits / dailyBurnRate).ceil();
    return DateTime.now().add(Duration(days: daysUntilDepletion));
  }

  // ===== PRIVATE VALIDATION & UTILITIES =====

  /// Validate all burn engine inputs
  /// Throws [ArgumentError] if any input is invalid
  void _validateInputs({
    required double startingUnits,
    required double dailyBurnRate,
    required DateTime lastCalculatedAt,
    required int outageDays,
  }) {
    // Validate starting units
    if (startingUnits < 0 || startingUnits.isNaN || startingUnits.isInfinite) {
      throw ArgumentError(
        'Invalid starting units: $startingUnits. '
        'Must be non-negative and finite.'
      );
    }
    
    // Validate daily burn rate
    if (dailyBurnRate < 0 || dailyBurnRate.isNaN || dailyBurnRate.isInfinite) {
      throw ArgumentError(
        'Invalid daily burn rate: $dailyBurnRate. '
        'Must be non-negative and finite.'
      );
    }
    
    // Sanity check: no one burns 1000+ units per day
    if (dailyBurnRate > 1000) {
      throw ArgumentError(
        'Daily burn rate too high: $dailyBurnRate. '
        'Maximum expected is 1000 units/day.'
      );
    }
    
    // Validate last calculated timestamp
    if (lastCalculatedAt.isAfter(DateTime.now())) {
      throw ArgumentError(
        'Last calculated time cannot be in the future: $lastCalculatedAt'
      );
    }
    
    // Validate timestamp isn't too old (before app existed)
    if (lastCalculatedAt.isBefore(DateTime(2024, 1, 1))) {
      throw ArgumentError(
        'Last calculated time is too old: $lastCalculatedAt'
      );
    }
    
    // Validate outage days
    if (outageDays < 0) {
      throw ArgumentError(
        'Outage days cannot be negative: $outageDays'
      );
    }
    
    // Sanity check: outage days shouldn't exceed 1 year
    if (outageDays > 365) {
      throw ArgumentError(
        'Outage days too high: $outageDays. Maximum is 365.'
      );
    }
  }

  /// Round to 1 decimal place for UX clarity
  /// 
  /// Example:
  /// - 23.456789 → 23.5
  /// - 0.999 → 1.0
  /// - 42.0 → 42.0
  double _roundForUX(double value) {
    return (value * 10).round() / 10;
  }
}
