import 'dart:math';
import 'package:flutter/foundation.dart';
import '../utils/budget_input_validator.dart';
import '../utils/budget_constants.dart';

/// Pure calculation service for budget planning
/// WHY: Stateless, testable functions for all ₦ ↔ units ↔ days conversions
/// SECURITY: All inputs validated before calculation
class BudgetCalculationService {
  // ==================== ₦ → UNITS CONVERSION ====================

  /// Convert budget amount to estimated units
  /// Formula: units = amount ÷ rate
  /// 
  /// Example: ₦5,000 ÷ ₦68.85/unit = 72.6 units
  /// 
  /// SECURITY: Validates rate before division
  /// Throws: ValidationException if rate is invalid
  double convertNairaToUnits({
    required double budgetAmount,
    required double ratePerUnit,
  }) {
    // SECURITY: Validate inputs
    if (!BudgetInputValidator.isValidRate(ratePerUnit)) {
      throw ValidationException('Invalid rate: $ratePerUnit');
    }

    if (budgetAmount < 0) {
      throw ValidationException('Budget amount cannot be negative');
    }

    // Perform calculation
    final units = BudgetInputValidator.safeDivide(
      budgetAmount,
      ratePerUnit,
    );

    if (kDebugMode) {
      debugPrint(
        'Converted ₦${budgetAmount.toStringAsFixed(2)} '
        '@ ₦${ratePerUnit.toStringAsFixed(2)}/unit '
        '→ ${units.toStringAsFixed(1)} units',
      );
    }

    return units;
  }

  // ==================== UNITS → DAYS CONVERSION ====================

  /// Convert units to estimated days of coverage
  /// Formula: days = units ÷ burnRate
  /// 
  /// Example: 72.6 units ÷ 12.1 units/day = 6.0 days
  /// 
  /// SECURITY: Validates burn rate before division
  /// Throws: ValidationException if burn rate is invalid
  double convertUnitsToDays({
    required double units,
    required double dailyBurnRate,
  }) {
    // SECURITY: Validate burn rate
    if (!BudgetInputValidator.isValidBurnRate(dailyBurnRate)) {
      throw ValidationException('Invalid burn rate: $dailyBurnRate');
    }

    if (units < 0) {
      throw ValidationException('Units cannot be negative');
    }

    // Perform calculation
    final days = BudgetInputValidator.safeDivide(
      units,
      dailyBurnRate,
    );

    if (kDebugMode) {
      debugPrint(
        'Converted ${units.toStringAsFixed(1)} units '
        '@ ${dailyBurnRate.toStringAsFixed(1)} units/day '
        '→ ${days.toStringAsFixed(1)} days',
      );
    }

    return days;
  }

  // ==================== UNITS → ₦ CONVERSION ====================

  /// Convert target units to estimated cost
  /// Formula: amount = units × rate
  /// 
  /// Example: 150 units × ₦68.85/unit = ₦10,327.50
  /// 
  /// SECURITY: Validates rate before multiplication
  /// Throws: ValidationException if rate is invalid
  double convertUnitsToNaira({
    required double targetUnits,
    required double ratePerUnit,
  }) {
    // SECURITY: Validate inputs
    if (!BudgetInputValidator.isValidRate(ratePerUnit)) {
      throw ValidationException('Invalid rate: $ratePerUnit');
    }

    if (targetUnits < 0) {
      throw ValidationException('Target units cannot be negative');
    }

    // Perform calculation
    final amount = targetUnits * ratePerUnit;

    // SECURITY: Check for overflow
    if (amount.isInfinite || amount.isNaN) {
      throw ValidationException('Calculation resulted in invalid amount');
    }

    if (kDebugMode) {
      debugPrint(
        'Converted ${targetUnits.toStringAsFixed(1)} units '
        '@ ₦${ratePerUnit.toStringAsFixed(2)}/unit '
        '→ ₦${amount.toStringAsFixed(2)}',
      );
    }

    return amount;
  }

  // ==================== COMPLETE CALCULATION PIPELINE ====================

  /// Calculate complete budget plan from budget amount
  /// Returns: Map with calculatedUnits and estimatedDays
  Map<String, double> calculateFromBudget({
    required double budgetAmount,
    required double ratePerUnit,
    required double dailyBurnRate,
  }) {
    final units = convertNairaToUnits(
      budgetAmount: budgetAmount,
      ratePerUnit: ratePerUnit,
    );

    final days = convertUnitsToDays(
      units: units,
      dailyBurnRate: dailyBurnRate,
    );

    return {
      'calculatedUnits': units,
      'estimatedDays': days,
    };
  }

  /// Calculate complete budget plan from target units
  /// Returns: Map with estimatedCost and estimatedDays
  Map<String, double> calculateFromUnits({
    required double targetUnits,
    required double ratePerUnit,
    required double dailyBurnRate,
  }) {
    final cost = convertUnitsToNaira(
      targetUnits: targetUnits,
      ratePerUnit: ratePerUnit,
    );

    final days = convertUnitsToDays(
      units: targetUnits,
      dailyBurnRate: dailyBurnRate,
    );

    return {
      'estimatedCost': cost,
      'estimatedDays': days,
    };
  }

  // ==================== REVERSE CALCULATION (TARGET DAYS) ====================

  /// Calculate required units for target number of days
  /// Formula: units = days × burnRate
  /// 
  /// Example: 7 days × 12.1 units/day = 84.7 units
  double calculateUnitsForDays({
    required double targetDays,
    required double dailyBurnRate,
  }) {
    if (targetDays < 0) {
      throw ValidationException('Target days cannot be negative');
    }

    if (!BudgetInputValidator.isValidBurnRate(dailyBurnRate)) {
      throw ValidationException('Invalid burn rate: $dailyBurnRate');
    }

    return targetDays * dailyBurnRate;
  }

  /// Calculate required budget for target number of days
  /// Formula: amount = (days × burnRate) × rate
  /// 
  /// Example: (7 days × 12.1 units/day) × ₦68.85/unit = ₦5,831.60
  double calculateBudgetForDays({
    required double targetDays,
    required double dailyBurnRate,
    required double ratePerUnit,
  }) {
    final requiredUnits = calculateUnitsForDays(
      targetDays: targetDays,
      dailyBurnRate: dailyBurnRate,
    );

    return convertUnitsToNaira(
      targetUnits: requiredUnits,
      ratePerUnit: ratePerUnit,
    );
  }

  // ==================== HELPER UTILITIES ====================

  /// Round value to specified decimal places
  /// WHY: Consistent formatting across UI
  double roundToDecimalPlaces(double value, int places) {
    final factor = pow(10, places).toDouble();
    return (value * factor).round() / factor;
  }

  /// Calculate percentage difference between two values
  /// WHY: Useful for showing savings or budget adjustments
  double calculatePercentageDifference(double original, double adjusted) {
    if (original == 0) return 0;
    return ((adjusted - original) / original) * 100;
  }
}
