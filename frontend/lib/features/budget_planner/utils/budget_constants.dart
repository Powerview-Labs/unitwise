/// Constants for Budget Planner module
/// SECURITY: Centralized validation rules and fallback values
class BudgetConstants {
  // ==================== INPUT VALIDATION ====================
  
  /// Minimum budget amount in Naira
  /// WHY: Below ₦100 unlikely to cover 1 day for most users
  static const double minBudgetAmount = 100.0;

  /// Maximum budget amount in Naira
  /// SECURITY: Prevents overflow and unrealistic inputs
  static const double maxBudgetAmount = 1000000.0; // ₦1M

  /// Minimum target units
  /// WHY: 0.1 units is ~0.145 kWh, minimal but realistic
  static const double minTargetUnits = 0.1;

  /// Maximum target units
  /// SECURITY: Prevents overflow and unrealistic inputs
  static const double maxTargetUnits = 10000.0;

  // ==================== TIPS THRESHOLDS ====================

  /// Coverage threshold for "low coverage" tips (days)
  /// WHY: Less than 5 days is concerning for most users
  static const double lowCoverageThreshold = 5.0;

  /// Burn rate threshold for "high burn" tips (units/day)
  /// WHY: Above 20 units/day indicates heavy usage
  static const double highBurnThreshold = 20.0;

  /// Minimum appliance wattage to consider for tips
  /// WHY: Focus on high-impact appliances (500W+)
  static const double minApplianceWattageForTips = 500.0;

  /// Minimum daily burn for appliance-specific tips
  /// WHY: Focus on appliances burning 2.5+ units/day
  static const double minApplianceBurnForTips = 2.5;

  // ==================== FALLBACK VALUES ====================

  /// Fallback rate if Firestore lookup fails
  /// WHY: National average ~₦68.85/unit (Band B typical)
  /// SECURITY: Allows offline functionality without crashing
  static const double fallbackRatePerUnit = 68.85;

  /// Fallback DisCo name
  static const String fallbackDisco = 'Unknown DisCo';

  /// Fallback Band
  static const String fallbackBand = 'B';

  // ==================== RATE CACHING ====================

  /// Maximum age of cached rate before refresh (days)
  /// WHY: Tariffs change monthly, 7-day cache is reasonable
  static const int rateCacheMaxAgeDays = 7;

  // ==================== UI FORMATTING ====================

  /// Decimal places for currency display
  static const int currencyDecimalPlaces = 2;

  /// Decimal places for units display
  static const int unitsDecimalPlaces = 1;

  /// Decimal places for days display
  static const int daysDecimalPlaces = 1;

  // ==================== SAVED PLANS ====================

  /// Maximum number of saved plans to display
  /// WHY: Performance optimization for large lists
  static const int maxSavedPlansToDisplay = 50;

  /// Firestore collection path for budget plans
  static const String budgetPlansCollection = 'budget_plans';

  /// Firestore collection path for global rates
  static const String ratesCollection = 'rates';

  // ==================== ERROR MESSAGES ====================

  static const String errorBudgetTooLow = 
      'Min: ₦100';
  
  static const String errorBudgetTooHigh = 
      'Max: ₦1,000,000';
  
  static const String errorUnitsTooLow = 
      'Min: 0.1 units';
  
  static const String errorUnitsTooHigh = 
      'Max: 10,000 units';
  
  static const String errorInvalidInput = 
      'Invalid number';
  
  static const String errorDependenciesNotMet = 
      'Complete appliance setup first';
  
  static const String errorNoConnection = 
      'Using cached rates';

  // ==================== WARNING MESSAGES ====================

  static const String warningLowBudget = 
      'May not cover 1 full day';
  
  static const String warningHighBurn = 
      'High daily usage for this budget';

  // ==================== HELPER METHODS ====================

  /// Format currency for display
  static String formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(currencyDecimalPlaces)}';
  }

  /// Format units for display
  static String formatUnits(double units) {
    return '${units.toStringAsFixed(unitsDecimalPlaces)} units';
  }

  /// Format days for display
  static String formatDays(double days) {
    return '${days.toStringAsFixed(daysDecimalPlaces)} days';
  }

  /// Check if rate is stale and needs refresh
  static bool isRateStale(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated).inDays;
    return difference >= rateCacheMaxAgeDays;
  }
}