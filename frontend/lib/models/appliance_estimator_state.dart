/**
 * Appliance Estimator State
 * 
 * Immutable state model for ApplianceEstimatorController.
 * Represents the current state of the appliance estimator.
 * 
 * Security: Immutable design prevents accidental state mutations
 * Performance: copyWith pattern enables efficient state updates
 */

import 'appliance_model.dart';
import 'power_saver_tip_model.dart';

/// State for Appliance Estimator
/// 
/// Immutable state container used by ApplianceEstimatorController.
/// Uses copyWith pattern for efficient state updates.
class ApplianceEstimatorState {
  /// List of appliances
  final List<Appliance> appliances;

  /// Total daily burn (units/day)
  final double totalDailyBurn;

  /// Power saver tips
  final List<PowerSaverTip> tips;

  /// Is loading
  final bool isLoading;

  /// Error message (null if no error)
  final String? error;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  const ApplianceEstimatorState({
    required this.appliances,
    required this.totalDailyBurn,
    required this.tips,
    required this.isLoading,
    this.error,
  });

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Create initial empty state
  factory ApplianceEstimatorState.initial() {
    return const ApplianceEstimatorState(
      appliances: [],
      totalDailyBurn: 0.0,
      tips: [],
      isLoading: false,
      error: null,
    );
  }

  /// Create loading state
  factory ApplianceEstimatorState.loading() {
    return const ApplianceEstimatorState(
      appliances: [],
      totalDailyBurn: 0.0,
      tips: [],
      isLoading: true,
      error: null,
    );
  }

  /// Create error state
  factory ApplianceEstimatorState.error(String message) {
    return ApplianceEstimatorState(
      appliances: const [],
      totalDailyBurn: 0.0,
      tips: const [],
      isLoading: false,
      error: message,
    );
  }

  // ============================================================================
  // COPYWITH (Immutable Updates)
  // ============================================================================

  /// Create a copy with updated fields
  /// 
  /// Only updates fields that are provided, keeping others unchanged.
  /// This enables efficient state updates without mutating the original.
  ApplianceEstimatorState copyWith({
    List<Appliance>? appliances,
    double? totalDailyBurn,
    List<PowerSaverTip>? tips,
    bool? isLoading,
    String? error,
  }) {
    return ApplianceEstimatorState(
      appliances: appliances ?? this.appliances,
      totalDailyBurn: totalDailyBurn ?? this.totalDailyBurn,
      tips: tips ?? this.tips,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // ============================================================================
  // EQUALITY & HASH
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ApplianceEstimatorState &&
        other.appliances == appliances &&
        other.totalDailyBurn == totalDailyBurn &&
        other.tips == tips &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      appliances,
      totalDailyBurn,
      tips,
      isLoading,
      error,
    );
  }

  // ============================================================================
  // DEBUG
  // ============================================================================

  @override
  String toString() {
    return 'ApplianceEstimatorState('
        'appliances: ${appliances.length}, '
        'totalDailyBurn: $totalDailyBurn, '
        'tips: ${tips.length}, '
        'isLoading: $isLoading, '
        'error: $error'
        ')';
  }
}
