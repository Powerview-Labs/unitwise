import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a saved budget plan snapshot
/// SECURITY: Immutable after creation - prevents retroactive tampering
/// WHY: Plans are historical records for comparison, not live data
class BudgetPlan {
  final String id;
  final double? budgetAmount; // Nullable: user may input units instead
  final double? targetUnits; // Nullable: user may input ₦ instead
  final double calculatedUnits;
  final double estimatedDays;
  final double burnRate; // Snapshot of burn rate at time of creation
  final String disco;
  final String band;
  final double rateUsed; // ₦/unit rate at time of creation
  final List<String> tipsShown;
  final DateTime createdAt;

  BudgetPlan({
    required this.id,
    this.budgetAmount,
    this.targetUnits,
    required this.calculatedUnits,
    required this.estimatedDays,
    required this.burnRate,
    required this.disco,
    required this.band,
    required this.rateUsed,
    required this.tipsShown,
    required this.createdAt,
  }) {
    // SECURITY: Validate that exactly one input mode was used
    if ((budgetAmount == null && targetUnits == null) ||
        (budgetAmount != null && targetUnits != null)) {
      throw ArgumentError(
        'Exactly one of budgetAmount or targetUnits must be non-null',
      );
    }

    // SECURITY: Validate non-negative values
    if (calculatedUnits < 0 ||
        estimatedDays < 0 ||
        burnRate < 0 ||
        rateUsed <= 0) {
      throw ArgumentError('Invalid plan values: must be non-negative');
    }

    // SECURITY: Validate budget/units if provided
    if (budgetAmount != null && budgetAmount! < 0) {
      throw ArgumentError('Budget amount cannot be negative');
    }
    if (targetUnits != null && targetUnits! < 0) {
      throw ArgumentError('Target units cannot be negative');
    }
  }

  /// Convert model to Firestore map
  /// SECURITY: Only serializes validated data
  Map<String, dynamic> toMap() {
    return {
      'budget_amount': budgetAmount,
      'target_units': targetUnits,
      'calculated_units': calculatedUnits,
      'estimated_days': estimatedDays,
      'burn_rate': burnRate,
      'disco': disco,
      'band': band,
      'rate_used': rateUsed,
      'tips_shown': tipsShown,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Create model from Firestore document
  /// SECURITY: Validates all fields exist before construction
  factory BudgetPlan.fromMap(Map<String, dynamic> map, String documentId) {
    // SECURITY: Validate required fields exist
    if (!map.containsKey('calculated_units') ||
        !map.containsKey('estimated_days') ||
        !map.containsKey('burn_rate') ||
        !map.containsKey('disco') ||
        !map.containsKey('band') ||
        !map.containsKey('rate_used') ||
        !map.containsKey('created_at')) {
      throw ArgumentError('Missing required fields in Firestore document');
    }

    return BudgetPlan(
      id: documentId,
      budgetAmount: map['budget_amount']?.toDouble(),
      targetUnits: map['target_units']?.toDouble(),
      calculatedUnits: (map['calculated_units'] as num).toDouble(),
      estimatedDays: (map['estimated_days'] as num).toDouble(),
      burnRate: (map['burn_rate'] as num).toDouble(),
      disco: map['disco'] as String,
      band: map['band'] as String,
      rateUsed: (map['rate_used'] as num).toDouble(),
      tipsShown: List<String>.from(map['tips_shown'] ?? []),
      createdAt: (map['created_at'] as Timestamp).toDate(),
    );
  }

  /// Create a copy with modified fields
  /// WHY: Useful for UI state management, not for Firestore updates
  BudgetPlan copyWith({
    String? id,
    double? budgetAmount,
    double? targetUnits,
    double? calculatedUnits,
    double? estimatedDays,
    double? burnRate,
    String? disco,
    String? band,
    double? rateUsed,
    List<String>? tipsShown,
    DateTime? createdAt,
  }) {
    return BudgetPlan(
      id: id ?? this.id,
      budgetAmount: budgetAmount ?? this.budgetAmount,
      targetUnits: targetUnits ?? this.targetUnits,
      calculatedUnits: calculatedUnits ?? this.calculatedUnits,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      burnRate: burnRate ?? this.burnRate,
      disco: disco ?? this.disco,
      band: band ?? this.band,
      rateUsed: rateUsed ?? this.rateUsed,
      tipsShown: tipsShown ?? this.tipsShown,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Human-readable summary for UI display
  String get inputSummary {
    if (budgetAmount != null) {
      return '₦${budgetAmount!.toStringAsFixed(2)} budget';
    } else {
      return '${targetUnits!.toStringAsFixed(1)} units target';
    }
  }

  @override
  String toString() {
    return 'BudgetPlan(id: $id, ${inputSummary}, '
        'calculatedUnits: $calculatedUnits, estimatedDays: $estimatedDays)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BudgetPlan &&
        other.id == id &&
        other.budgetAmount == budgetAmount &&
        other.targetUnits == targetUnits &&
        other.calculatedUnits == calculatedUnits;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        budgetAmount.hashCode ^
        targetUnits.hashCode ^
        calculatedUnits.hashCode;
  }
}
