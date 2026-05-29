import 'package:flutter/foundation.dart';
import '../models/power_saving_tip.dart';
import '../utils/budget_constants.dart';

/// Service for generating power-saving tips
/// WHY: Context-aware suggestions based on usage patterns and thresholds
/// SECURITY: Read-only, never modifies user data
class TipsEngineService {
  // ==================== MAIN TIP GENERATION ====================

  /// Generate tips based on calculation results and thresholds
  /// 
  /// Returns: List of 1-3 tips, sorted by priority
  /// WHY: Limit to 3 to avoid overwhelming user
  List<PowerSavingTip> generateTips({
    required double estimatedDays,
    required double burnRate,
    required double budgetAmount,
    required double targetDays,
    List<ApplianceInfo>? topAppliances,
  }) {
    final tips = <PowerSavingTip>[];

    if (kDebugMode) {
      debugPrint(
        'TipsEngine: Generating tips for '
        'days=$estimatedDays, burn=$burnRate, budget=$budgetAmount',
      );
    }

    // Check threshold 1: Low coverage
    if (estimatedDays < BudgetConstants.lowCoverageThreshold) {
      tips.add(_generateLowCoverageTip(
        estimatedDays: estimatedDays,
        targetDays: targetDays,
        burnRate: burnRate,
      ));
    }

    // Check threshold 2: High burn rate
    if (burnRate > BudgetConstants.highBurnThreshold) {
      tips.add(_generateHighBurnTip(
        burnRate: burnRate,
        topAppliances: topAppliances,
      ));
    }

    // Check threshold 3: Budget insufficient for target
    if (targetDays > 0 && estimatedDays < targetDays) {
      tips.add(_generateInsufficientBudgetTip(
        currentDays: estimatedDays,
        targetDays: targetDays,
        burnRate: burnRate,
      ));
    }

    // Add appliance-specific tips if available
    if (topAppliances != null && topAppliances.isNotEmpty) {
      final applianceTip = _generateApplianceSpecificTip(topAppliances);
      if (applianceTip != null) {
        tips.add(applianceTip);
      }
    }

    // Sort by priority and limit to top 3
    tips.sort((a, b) => a.tipType.priority.compareTo(b.tipType.priority));
    final finalTips = tips.take(3).toList();

    if (kDebugMode) {
      debugPrint('TipsEngine: Generated ${finalTips.length} tips');
    }

    return finalTips;
  }

  // ==================== SPECIFIC TIP GENERATORS ====================

  /// Generate tip for low coverage scenario
  /// Threshold: estimatedDays < 5
  PowerSavingTip _generateLowCoverageTip({
    required double estimatedDays,
    required double targetDays,
    required double burnRate,
  }) {
    // Calculate units needed for target (or 7 days default)
    final desiredDays = targetDays > 0 ? targetDays : 7.0;
    final unitsNeeded = desiredDays * burnRate;
    
    // Calculate additional budget required
    // NOTE: We don't have rate here, so express in units only
    final additionalUnits = unitsNeeded - (estimatedDays * burnRate);

    return PowerSavingTip(
      message: 'Your budget may last only ${estimatedDays.toStringAsFixed(1)} days. '
          'To last ${desiredDays.toInt()} days, you\'ll need approximately '
          '${additionalUnits.toStringAsFixed(1)} more units.',
      tipType: TipType.lowCoverage,
    );
  }

  /// Generate tip for high burn rate scenario
  /// Threshold: burnRate > 20 units/day
  PowerSavingTip _generateHighBurnTip({
    required double burnRate,
    List<ApplianceInfo>? topAppliances,
  }) {
    // If we have appliance data, be specific
    if (topAppliances != null && topAppliances.isNotEmpty) {
      final topAppliance = topAppliances.first;
      
      return PowerSavingTip(
        message: 'Your daily usage (${burnRate.toStringAsFixed(1)} units/day) is high. '
            'Your ${topAppliance.name} consumes about ${topAppliance.dailyBurn.toStringAsFixed(1)} units/day. '
            'Consider reducing usage to stretch your budget.',
        applianceName: topAppliance.name,
        estimatedSavings: topAppliance.dailyBurn * 0.2, // 20% reduction estimate
        tipType: TipType.highBurn,
      );
    }

    // Generic high burn tip
    return PowerSavingTip(
      message: 'Your daily usage (${burnRate.toStringAsFixed(1)} units/day) is higher than average. '
          'Reducing usage of high-power appliances can significantly extend your budget.',
      tipType: TipType.highBurn,
    );
  }

  /// Generate tip for insufficient budget scenario
  /// Triggered when: estimatedDays < targetDays
  PowerSavingTip _generateInsufficientBudgetTip({
    required double currentDays,
    required double targetDays,
    required double burnRate,
  }) {
    final shortfall = targetDays - currentDays;
    final unitsNeeded = shortfall * burnRate;

    return PowerSavingTip(
      message: 'To last ${targetDays.toInt()} days (${shortfall.toStringAsFixed(1)} more), '
          'you\'ll need about ${unitsNeeded.toStringAsFixed(1)} additional units. '
          'Consider increasing your budget or reducing usage.',
      tipType: TipType.insufficientBudget,
    );
  }

  /// Generate appliance-specific optimization tip
  /// Only for high-impact appliances (500W+, 2.5+ units/day)
  PowerSavingTip? _generateApplianceSpecificTip(
    List<ApplianceInfo> topAppliances,
  ) {
    // Filter for high-impact appliances
    final highImpact = topAppliances.where((a) =>
      a.wattage >= BudgetConstants.minApplianceWattageForTips &&
      a.dailyBurn >= BudgetConstants.minApplianceBurnForTips
    ).toList();

    if (highImpact.isEmpty) return null;

    final appliance = highImpact.first;
    
    // Calculate savings from 2-hour reduction
    final hoursReduction = 2.0;
    final savingsPerDay = (appliance.wattage * hoursReduction) / 1000;

    return PowerSavingTip(
      message: 'Reducing your ${appliance.name} usage by ${hoursReduction.toInt()} hours/day '
          'could save approximately ${savingsPerDay.toStringAsFixed(1)} units daily.',
      applianceName: appliance.name,
      estimatedSavings: savingsPerDay,
      tipType: TipType.applianceOptimization,
    );
  }

  // ==================== HELPER METHODS ====================

  /// Get generic power-saving tips (fallback)
  /// WHY: Useful when no specific thresholds are triggered
  List<PowerSavingTip> getGenericTips() {
    return [
      PowerSavingTip(
        message: 'Turn off appliances when not in use to reduce standby power consumption.',
        tipType: TipType.generic,
      ),
      PowerSavingTip(
        message: 'Use energy-efficient LED bulbs to reduce lighting costs by up to 75%.',
        tipType: TipType.generic,
      ),
      PowerSavingTip(
        message: 'Set your AC to 24-25°C instead of maximum cooling to save power.',
        tipType: TipType.generic,
      ),
    ];
  }

  /// Check if any threshold is triggered
  /// WHY: Useful for UI to show/hide tips section
  bool shouldShowTips({
    required double estimatedDays,
    required double burnRate,
    required double targetDays,
  }) {
    return estimatedDays < BudgetConstants.lowCoverageThreshold ||
        burnRate > BudgetConstants.highBurnThreshold ||
        (targetDays > 0 && estimatedDays < targetDays);
  }
}

// ==================== APPLIANCE INFO CLASS ====================

/// Simplified appliance info for tip generation
/// WHY: Decouples TipsEngine from full Appliance model
class ApplianceInfo {
  final String name;
  final double wattage;
  final double dailyBurn; // units/day
  final double hoursPerDay;

  ApplianceInfo({
    required this.name,
    required this.wattage,
    required this.dailyBurn,
    required this.hoursPerDay,
  });

  /// Create from Appliance Estimator model (if available)
  factory ApplianceInfo.fromEstimator({
    required String name,
    required double wattage,
    required double hoursPerDay,
    required int quantity,
  }) {
    // Calculate daily burn: (W × Q × h) / 1000
    final dailyBurn = (wattage * quantity * hoursPerDay) / 1000;

    return ApplianceInfo(
      name: name,
      wattage: wattage,
      dailyBurn: dailyBurn,
      hoursPerDay: hoursPerDay,
    );
  }

  @override
  String toString() => 'ApplianceInfo($name: ${dailyBurn.toStringAsFixed(1)} units/day)';
}
