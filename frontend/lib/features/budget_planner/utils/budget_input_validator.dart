import 'package:flutter/foundation.dart';
import 'budget_constants.dart';

/// Input validator for Budget Planner
/// SECURITY: Prevents injection, overflow, and invalid calculations
/// WHY: All user inputs must be sanitized before processing
class BudgetInputValidator {
  // ==================== NUMERIC SANITIZATION ====================

  /// Sanitize and parse numeric input from text field
  /// SECURITY: Strips invalid characters, prevents code injection
  /// Returns: Parsed double or null if invalid
  static double? sanitizeNumericInput(String input) {
    if (input.isEmpty) return null;

    // SECURITY: Remove all non-numeric characters except decimal point
    // WHY: Prevents injection of symbols, letters, or malicious code
    final sanitized = input.replaceAll(RegExp(r'[^\d.]'), '');

    if (sanitized.isEmpty) return null;

    // SECURITY: Check for multiple decimal points
    if (sanitized.split('.').length > 2) {
      if (kDebugMode) {
        debugPrint('Invalid input: multiple decimal points in "$input"');
      }
      return null;
    }

    // Parse to double
    final parsed = double.tryParse(sanitized);

    // SECURITY: Prevent NaN and Infinity
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      if (kDebugMode) {
        debugPrint('Invalid numeric value: $sanitized');
      }
      return null;
    }

    // SECURITY: Prevent negative values
    if (parsed < 0) {
      if (kDebugMode) {
        debugPrint('Rejected negative value: $parsed');
      }
      return null;
    }

    return parsed;
  }

  // ==================== BUDGET AMOUNT VALIDATION ====================

  /// Validate budget amount is within acceptable range
  /// Returns: Validation result with error message if invalid
  static ValidationResult validateBudgetAmount(double amount) {
    if (amount < BudgetConstants.minBudgetAmount) {
      return ValidationResult(
        isValid: false,
        errorMessage: BudgetConstants.errorBudgetTooLow,
      );
    }

    if (amount > BudgetConstants.maxBudgetAmount) {
      return ValidationResult(
        isValid: false,
        errorMessage: BudgetConstants.errorBudgetTooHigh,
      );
    }

    // WARNING: Very low budget (< ₦500)
    if (amount < 500) {
      return ValidationResult(
        isValid: true,
        warningMessage: BudgetConstants.warningLowBudget,
      );
    }

    return ValidationResult(isValid: true);
  }

  // ==================== UNITS VALIDATION ====================

  /// Validate target units is within acceptable range
  static ValidationResult validateTargetUnits(double units) {
    if (units < BudgetConstants.minTargetUnits) {
      return ValidationResult(
        isValid: false,
        errorMessage: BudgetConstants.errorUnitsTooLow,
      );
    }

    if (units > BudgetConstants.maxTargetUnits) {
      return ValidationResult(
        isValid: false,
        errorMessage: BudgetConstants.errorUnitsTooHigh,
      );
    }

    return ValidationResult(isValid: true);
  }

  // ==================== BURN RATE VALIDATION ====================

  /// Validate burn rate is safe for calculations
  /// SECURITY: Prevents division by zero
  static bool isValidBurnRate(double burnRate) {
    return burnRate > 0 && !burnRate.isNaN && !burnRate.isInfinite;
  }

  // ==================== RATE VALIDATION ====================

  /// Validate tariff rate is safe for calculations
  /// SECURITY: Prevents division by zero and negative rates
  static bool isValidRate(double rate) {
    return rate > 0 && !rate.isNaN && !rate.isInfinite;
  }

  // ==================== SAFE DIVISION ====================

  /// Perform division with safety checks
  /// SECURITY: Prevents division by zero crashes
  /// Throws: ValidationException if denominator is invalid
  static double safeDivide(double numerator, double denominator) {
    if (denominator == 0 ||
        denominator.isNaN ||
        denominator.isInfinite) {
      throw ValidationException(
        'Invalid divisor: $denominator. Cannot perform calculation.',
      );
    }

    final result = numerator / denominator;

    // SECURITY: Check result is valid
    if (result.isNaN || result.isInfinite) {
      throw ValidationException(
        'Calculation resulted in invalid value',
      );
    }

    return result;
  }

  // ==================== DEPENDENCY VALIDATION ====================

  /// Check if all required dependencies are met
  static DependencyCheckResult checkDependencies({
    required bool applianceSetupComplete,
    required bool locationSet,
    required double? burnRate,
    required String? disco,
    required String? band,
  }) {
    final missingDependencies = <String>[];

    if (!applianceSetupComplete || burnRate == null || burnRate <= 0) {
      missingDependencies.add('Appliance Estimator');
    }

    if (!locationSet || disco == null || band == null) {
      missingDependencies.add('Location Setup');
    }

    return DependencyCheckResult(
      allMet: missingDependencies.isEmpty,
      missingDependencies: missingDependencies,
    );
  }
}

// ==================== VALIDATION RESULT CLASSES ====================

/// Result of input validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? warningMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.warningMessage,
  });

  bool get hasError => errorMessage != null;
  bool get hasWarning => warningMessage != null;
}

/// Result of dependency check
class DependencyCheckResult {
  final bool allMet;
  final List<String> missingDependencies;

  DependencyCheckResult({
    required this.allMet,
    required this.missingDependencies,
  });

  String get errorMessage {
    if (allMet) return '';
    
    if (missingDependencies.length == 1) {
      return 'Please complete ${missingDependencies.first} first';
    } else {
      return 'Please complete: ${missingDependencies.join(", ")}';
    }
  }
}

/// Exception thrown during validation
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
