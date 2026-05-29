/// Result of burn engine calculation
/// This model encapsulates the output of the burn engine
/// to ensure type safety and validation
/// 
/// SECURITY: All values validated before creating result
class BurnCalculationResult {
  /// Estimated remaining units (always >= 0)
  final double estimatedUnits;
  
  /// Estimated days remaining (always >= 0)
  final double daysRemaining;
  
  /// When this calculation was performed
  final DateTime calculatedAt;
  
  /// Number of effective days used in calculation
  /// (accounting for outages)
  final int effectiveDays;
  
  /// How this result was generated
  /// Values: 'auto' (burn engine) or 'manual' (user override)
  final String calculationMethod;
  
  /// Total units burned in this calculation
  final double unitsBurned;

  const BurnCalculationResult({
    required this.estimatedUnits,
    required this.daysRemaining,
    required this.calculatedAt,
    required this.effectiveDays,
    required this.calculationMethod,
    required this.unitsBurned,
  });
  
  /// Check if result is valid
  /// Invalid results should not be used to update dashboard state
  bool get isValid {
    if (estimatedUnits.isNaN || estimatedUnits.isInfinite) return false;
    if (estimatedUnits < 0) return false;
    if (daysRemaining.isNaN || daysRemaining.isInfinite) return false;
    if (daysRemaining < 0) return false;
    if (effectiveDays < 0) return false;
    if (unitsBurned.isNaN || unitsBurned.isInfinite) return false;
    if (unitsBurned < 0) return false;
    return true;
  }
  
  /// Check if units are critically low
  bool get isCritical => estimatedUnits < 5.0;
  
  /// Check if units are low
  bool get isLow => estimatedUnits < 15.0;
  
  /// Check if burn rate seems unusually high
  /// (More than 30 units/day is very unusual)
  bool get hasUnusualBurnRate {
    if (effectiveDays <= 0) return false;
    final dailyBurn = unitsBurned / effectiveDays;
    return dailyBurn > 30.0;
  }

  @override
  String toString() {
    return 'BurnCalculationResult('
        'units: ${estimatedUnits.toStringAsFixed(1)}, '
        'days: ${daysRemaining.toStringAsFixed(1)}, '
        'method: $calculationMethod, '
        'effective_days: $effectiveDays)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BurnCalculationResult &&
          runtimeType == other.runtimeType &&
          estimatedUnits == other.estimatedUnits &&
          effectiveDays == other.effectiveDays &&
          calculationMethod == other.calculationMethod;

  @override
  int get hashCode =>
      estimatedUnits.hashCode ^
      effectiveDays.hashCode ^
      calculationMethod.hashCode;
}
