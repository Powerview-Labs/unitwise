import 'package:flutter/foundation.dart';
import '../models/dashboard_state.dart';
import '../models/alert_config.dart';

/// Alert and suggestion generation engine
/// 
/// PURPOSE:
/// - Generate alerts based on current dashboard state
/// - Provide context-aware power-saving suggestions
/// - Determine alert severity (low vs critical)
/// 
/// PRINCIPLES:
/// - All alerts are STATE-DRIVEN (not rule-based guesses)
/// - Suggestions are actionable and specific
/// - Never show too many alerts (max 3-4 suggestions)
/// - ✅ ISSUE #5 FIX: All messages probabilistic, not alarmist
/// 
/// TRIGGERS:
/// - Low/critical unit thresholds
/// - Low/critical days remaining
/// - High burn rates
class AlertEngine {
  /// Generate alerts based on current dashboard state
  /// 
  /// This is the main entry point for alert generation.
  /// Returns an [AlertState] with flags and suggestions.
  /// 
  /// Parameters:
  /// - [estimatedUnits]: Current unit balance
  /// - [daysRemaining]: Estimated days until depletion
  /// - [dailyBurnRate]: Daily consumption rate
  /// 
  /// Returns: [AlertState] with appropriate alerts and suggestions
  AlertState generateAlerts({
    required double estimatedUnits,
    required double daysRemaining,
    required double dailyBurnRate,
  }) {
    if (kDebugMode) {
      debugPrint('[AlertEngine] 🚨 Generating alerts...');
      debugPrint('[AlertEngine]    Units: ${estimatedUnits.toStringAsFixed(1)}');
      debugPrint('[AlertEngine]    Days: ${daysRemaining.toStringAsFixed(1)}');
      debugPrint('[AlertEngine]    Burn: ${dailyBurnRate.toStringAsFixed(1)} units/day');
    }
    
    bool lowUnits = false;
    bool critical = false;
    List<String> suggestions = [];
    
    // 1. Check critical state (highest priority)
    if (_isCritical(estimatedUnits, daysRemaining)) {
      critical = true;
      suggestions.addAll(_getCriticalSuggestions(estimatedUnits, daysRemaining));
      
      if (kDebugMode) {
        debugPrint('[AlertEngine] 🔴 CRITICAL state detected!');
      }
    }
    
    // 2. Check low units state
    else if (_isLowUnits(estimatedUnits, daysRemaining)) {
      lowUnits = true;
      suggestions.addAll(_getLowUnitsSuggestions(estimatedUnits, daysRemaining));
      
      if (kDebugMode) {
        debugPrint('[AlertEngine] 🟡 Low units state detected');
      }
    }
    
    // 3. Check high burn rate (can coexist with low units)
    if (_isHighBurnRate(dailyBurnRate)) {
      suggestions.addAll(_getHighBurnSuggestions(dailyBurnRate));
      
      if (kDebugMode) {
        debugPrint('[AlertEngine] ⚠️  High burn rate detected');
      }
    }
    
    // Limit suggestions to avoid overwhelming user
    final limitedSuggestions = suggestions.take(4).toList();
    
    if (kDebugMode) {
      debugPrint('[AlertEngine] 💡 Generated ${limitedSuggestions.length} suggestions');
    }
    
    return AlertState(
      lowUnits: lowUnits,
      critical: critical,
      suggestions: limitedSuggestions,
    );
  }

  /// Generate alerts for a specific future date (forecasting)
  /// Useful for budget planner and what-if scenarios
  AlertState generateAlertsForDate({
    required double currentUnits,
    required double dailyBurnRate,
    required DateTime targetDate,
  }) {
    final now = DateTime.now();
    final daysUntilTarget = targetDate.difference(now).inDays;
    
    if (daysUntilTarget <= 0) {
      // Target is in past or today - use current values
      return generateAlerts(
        estimatedUnits: currentUnits,
        daysRemaining: dailyBurnRate > 0 ? currentUnits / dailyBurnRate : 0,
        dailyBurnRate: dailyBurnRate,
      );
    }
    
    // Project units at target date
    final projectedBurn = dailyBurnRate * daysUntilTarget;
    final projectedUnits = (currentUnits - projectedBurn).clamp(0.0, double.infinity);
    final projectedDaysRemaining = dailyBurnRate > 0 
        ? projectedUnits / dailyBurnRate 
        : 0.0;
    
    return generateAlerts(
      estimatedUnits: projectedUnits,
      daysRemaining: projectedDaysRemaining,
      dailyBurnRate: dailyBurnRate,
    );
  }

  // ===== PRIVATE HELPERS =====

  /// Check if state is critical
  bool _isCritical(double units, double days) {
    return units <= AlertConfig.criticalUnitsThreshold ||
           days <= AlertConfig.criticalDaysThreshold;
  }

  /// Check if units are low
  bool _isLowUnits(double units, double days) {
    return units <= AlertConfig.lowUnitsThreshold ||
           days <= AlertConfig.lowDaysThreshold;
  }

  /// Check if burn rate is high
  bool _isHighBurnRate(double burnRate) {
    return burnRate >= AlertConfig.highBurnRateThreshold;
  }

  /// Get critical suggestions
  /// ✅ ISSUE #5 FIX: Removed hardcoded alarmist message
  List<String> _getCriticalSuggestions(double units, double days) {
    List<String> suggestions = [];
    
    if (units <= AlertConfig.criticalUnitsThreshold) {
      suggestions.add(AlertConfig.alertMessages['critical_units']!);
    }
    
    // ✅ FIX: Use probabilistic message from config, not hardcoded
    if (days <= AlertConfig.criticalDaysThreshold) {
      suggestions.add(
        'Estimated to last ~${days.toStringAsFixed(1)} day${days > 1 ? 's' : ''}'
      );
    }
    
    // Add critical action items
    suggestions.addAll(AlertConfig.criticalSuggestions.take(2));
    
    return suggestions;
  }

  /// Get low units suggestions
  List<String> _getLowUnitsSuggestions(double units, double days) {
    List<String> suggestions = [];
    
    // Primary message
    suggestions.add(
      AlertConfig.alertMessages['low_units']!.replaceAll(
        '{days}',
        days.toStringAsFixed(1),
      ),
    );
    
    // Secondary actions
    suggestions.add(AlertConfig.alertMessages['low_days']!);
    
    // Add one default suggestion
    suggestions.add(AlertConfig.defaultSuggestions.first);
    
    return suggestions;
  }

  /// Get high burn rate suggestions
  List<String> _getHighBurnSuggestions(double burnRate) {
    List<String> suggestions = [];
    
    if (burnRate >= AlertConfig.veryHighBurnRateThreshold) {
      suggestions.add(AlertConfig.alertMessages['very_high_burn']!);
      suggestions.addAll(AlertConfig.highUsageSuggestions.take(2));
    } else {
      suggestions.add(AlertConfig.alertMessages['high_burn']!);
      suggestions.add(AlertConfig.highUsageSuggestions.first);
    }
    
    return suggestions;
  }

  /// Get suggestion priority score (for sorting)
  /// Higher score = higher priority
  int _getSuggestionPriority(String suggestion) {
    if (suggestion.toLowerCase().contains('critical') ||
        suggestion.toLowerCase().contains('immediately')) {
      return 3;
    } else if (suggestion.toLowerCase().contains('recharge') ||
               suggestion.toLowerCase().contains('soon')) {
      return 2;
    } else {
      return 1;
    }
  }
}