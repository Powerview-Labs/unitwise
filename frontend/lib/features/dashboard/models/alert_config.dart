/// Alert configuration and thresholds
/// All alert logic is driven by these constants
///
/// IMPORTANT: These thresholds are business logic decisions
/// Changes here affect when users receive warnings
///
/// ✅ ISSUE #5 FIX: All alerts use probabilistic, non-alarmist language
/// - Use "may", "estimated", "~" (not "you WILL")
/// - Suggestive, not commanding
/// - Trust-preserving tone
class AlertConfig {
  // Unit thresholds
  /// Show low units warning when below this
  static const double lowUnitsThreshold = 15.0;

  /// Show critical warning when below this
  static const double criticalUnitsThreshold = 5.0;

  // Days remaining thresholds
  /// Show warning when days remaining drops below this
  static const double lowDaysThreshold = 2.0;

  /// Show critical warning when days remaining drops below this
  static const double criticalDaysThreshold = 1.0;

  // Burn rate thresholds (high usage detection)
  /// Flag as high usage when daily burn exceeds this
  static const double highBurnRateThreshold = 20.0;

  /// Very high usage threshold
  static const double veryHighBurnRateThreshold = 30.0;

  // ✅ ISSUE #5 FIX: Alert message templates with probabilistic language
  /// Placeholder: {days} will be replaced with actual days
  static const Map<String, String> alertMessages = {
    // ✅ Changed from "You may run out" to "Estimated to last"
    'low_units': 'Estimated to last ~{days} days',
    
    // ✅ Changed from "critically low" to "running low" + "may need"
    'critical_units': 'Units running low. May need recharge soon',
    
    // ✅ Changed from "Reduce AC" (commanding) to "Consider reducing" (suggestive)
    'low_days': 'Consider reducing high-usage appliances',
    
    // ✅ Changed from "is high" to "appears elevated" (less alarmist)
    'high_burn': 'Usage appears elevated. Review appliance hours',
    
    // ✅ Changed from "Very high" to "Unusually high" + "may want to"
    'very_high_burn': 'Unusually high usage detected. May want to review settings',
  };

  // ✅ ISSUE #5 FIX: Default suggestions with probabilistic language
  static const List<String> defaultSuggestions = [
    'Consider adjusting AC hours', // ✅ "Consider" not "Reduce"
    'Review appliances left on overnight', // ✅ Specific + neutral
    'Recharge when convenient', // ✅ Not "before your units finish" (alarmist)
    'Check for idle appliances', // ✅ Suggestive, not commanding
  ];

  // ✅ ISSUE #5 FIX: High-usage suggestions (neutral tone)
  static const List<String> highUsageSuggestions = [
    'AC may be contributing significantly to daily usage', // ✅ "may be"
    'Consider adjusting water heater schedule', // ✅ "Consider"
    'Review appliance hours in estimator', // ✅ Neutral instruction
    'Try reducing usage by ~2-3 hours daily', // ✅ "~" probabilistic marker
  ];

  // ✅ ISSUE #5 FIX: Critical suggestions (urgent but not alarmist)
  static const List<String> criticalSuggestions = [
    'May need recharge soon to avoid interruption', // ✅ "May need" not "Recharge immediately"
    'Estimated to finish within a day', // ✅ Factual + "Estimated"
    'Consider recharging when convenient', // ✅ Suggestive
  ];

  /// Get suggestion based on unit level and burn rate
  /// ✅ ISSUE #5 FIX: Returns probabilistic suggestions
  static List<String> getSuggestionsFor({
    required double units,
    required double burnRate,
    required double daysRemaining,
  }) {
    List<String> suggestions = [];

    // Critical state
    if (units <= criticalUnitsThreshold || daysRemaining <= criticalDaysThreshold) {
      suggestions.addAll(criticalSuggestions);
    }

    // Low units
    else if (units <= lowUnitsThreshold || daysRemaining <= lowDaysThreshold) {
      suggestions.add(
        alertMessages['low_units']!.replaceAll(
          '{days}',
          daysRemaining.toStringAsFixed(1),
        ),
      );
      suggestions.add(alertMessages['low_days']!);
    }

    // High burn rate
    if (burnRate >= veryHighBurnRateThreshold) {
      suggestions.add(alertMessages['very_high_burn']!);
      suggestions.addAll(highUsageSuggestions.take(2));
    } else if (burnRate >= highBurnRateThreshold) {
      suggestions.add(alertMessages['high_burn']!);
      suggestions.add(highUsageSuggestions.first);
    }

    // Add default suggestions if none added
    if (suggestions.isEmpty) {
      suggestions.addAll(defaultSuggestions.take(2));
    }

    return suggestions;
  }
}