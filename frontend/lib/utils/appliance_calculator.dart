import 'dart:math' as math;
import '../models/appliance_model.dart';
import '../models/power_saver_tip_model.dart';
import '../config/app_config.dart';

/// Pure calculation functions for the Appliance Estimator
/// 
/// These functions have NO side effects and are easy to test.
/// All business logic for calculations should be here.
class ApplianceCalculator {
  // Prevent instantiation
  ApplianceCalculator._();
  
  // ========================================================================
  // BAND ADJUSTMENT
  // ========================================================================
  
  /// Calculate adjusted hours based on band supply constraint
  /// 
  /// Rule: adjusted_hours = min(user_hours, band_supply_hours)
  /// 
  /// This is SILENT - no errors, no warnings, just math.
  /// 
  /// Example:
  ///   User sets AC to 24 hours/day
  ///   Band C supplies 12 hours/day average
  ///   Result: adjusted_hours = 12
  static double calculateAdjustedHours({
    required double userHours,
    required int bandSupplyHours,
  }) {
    if (userHours <= 0) return 0;
    if (userHours <= bandSupplyHours) return userHours;
    return bandSupplyHours.toDouble();
  }
  
  // ========================================================================
  // UNIT CALCULATIONS
  // ========================================================================
  
  /// Calculate daily unit consumption for a single appliance
  /// 
  /// Formula: (Wattage × Quantity × Adjusted Hours) ÷ 1000
  /// 
  /// Example:
  ///   AC: 1000W × 1 unit × 12 hours = 12,000 Wh = 12 kWh = 12 units
  ///   TV: 100W × 2 units × 6 hours = 1,200 Wh = 1.2 kWh = 1.2 units
  static double calculateDailyUnits({
    required double wattage,
    required int quantity,
    required double adjustedHours,
  }) {
    if (wattage <= 0 || quantity <= 0 || adjustedHours <= 0) return 0.0;
    return (wattage * quantity * adjustedHours) / 1000.0;
  }
  
  /// Calculate total daily burn across all appliances
  /// 
  /// Returns sum of all appliance daily units
  static double calculateTotalDailyBurn(List<Appliance> appliances) {
    if (appliances.isEmpty) return 0.0;
    return appliances.fold(0.0, (sum, appliance) => sum + appliance.dailyUnits);
  }
  
  // ========================================================================
  // BAND ADJUSTMENT DETECTION
  // ========================================================================
  
  /// Check if any appliance was band-adjusted
  /// 
  /// Returns true if at least one appliance had hours reduced
  static bool anyBandAdjusted(List<Appliance> appliances) {
    return appliances.any((a) => a.wasBandAdjusted);
  }
  
  /// Get total hours reduced across all appliances due to band adjustment
  static double totalHoursReduced(List<Appliance> appliances) {
    return appliances.fold(
      0.0,
      (sum, appliance) => sum + appliance.hoursReduced,
    );
  }
  
  // ========================================================================
  // POWER SAVER TIPS ENGINE
  // ========================================================================
  
  /// Generate power saver tips based on high-consumption appliances
  /// 
  /// Logic:
  /// 1. Rank appliances by daily unit consumption (highest first)
  /// 2. Select candidates where:
  ///    - Wattage > 500W OR
  ///    - Daily units > 2.5 OR
  ///    - Hours > 8
  /// 3. For each candidate, simulate reductions of 1-3 hours
  /// 4. Calculate savings in units and Naira
  /// 5. Return top 3 tips
  /// 
  /// Returns up to 3 PowerSaverTip objects
  static List<PowerSaverTip> generatePowerSaverTips({
    required List<Appliance> appliances,
    required double unitRate,  // ₦ per kWh
  }) {
    if (appliances.isEmpty) return [];
    
    final List<PowerSaverTip> tips = [];
    
    // Step 1: Filter high-consumption appliances
    final candidates = appliances
        .where((a) => _isHighConsumptionCandidate(a))
        .toList()
      ..sort((a, b) => b.dailyUnits.compareTo(a.dailyUnits));  // Highest first
    
    // Step 2: Generate tips for each candidate
    for (final appliance in candidates) {
      // Don't suggest reducing below 1 hour
      if (appliance.adjustedHours <= 1) continue;
      
      // Try reductions of 1, 2, 3 hours (pick best)
      final possibleReductions = [1, 2, 3]
          .where((delta) => appliance.adjustedHours - delta >= 0)
          .toList();
      
      if (possibleReductions.isEmpty) continue;
      
      // Use the first viable reduction (simplest)
      final deltaHours = possibleReductions.first;
      final suggestedHours = (appliance.adjustedHours - deltaHours).toInt();
      
      // Calculate savings
      final unitsSaved = calculateDailyUnits(
        wattage: appliance.wattage,
        quantity: appliance.quantity,
        adjustedHours: deltaHours.toDouble(),
      );
      
      final nairaSavedPerMonth = unitsSaved * unitRate * 30;
      
      // Create tip
      tips.add(PowerSaverTip(
        applianceId: appliance.id,
        applianceName: appliance.name,
        currentHours: appliance.adjustedHours.toInt(),
        suggestedHours: suggestedHours,
        unitsSavedPerDay: unitsSaved,
        nairaSavedPerMonth: nairaSavedPerMonth,
        recommendation: _formatTipRecommendation(
          applianceName: appliance.name,
          deltaHours: deltaHours,
          unitsSaved: unitsSaved,
          nairaSaved: nairaSavedPerMonth,
        ),
      ));
      
      // Stop after top 3 tips
      if (tips.length >= AppConfig.maxTipsToShow) break;
    }
    
    return tips;
  }
  
  /// Check if appliance qualifies as high-consumption candidate
  /// 
  /// Criteria (any of):
  ///   - Wattage > 500W
  ///   - Daily units > 2.5
  ///   - Hours > 8
  static bool _isHighConsumptionCandidate(Appliance appliance) {
    return appliance.wattage > AppConfig.highConsumptionWattage ||
        appliance.dailyUnits > AppConfig.highConsumptionUnits ||
        appliance.hoursPerDay > AppConfig.highConsumptionHours;
  }
  
  /// Format tip recommendation text
  static String _formatTipRecommendation({
    required String applianceName,
    required int deltaHours,
    required double unitsSaved,
    required double nairaSaved,
  }) {
    final unitsText = unitsSaved.toStringAsFixed(1);
    final nairaText = nairaSaved.toStringAsFixed(0);
    
    return 'Reduce $applianceName by ${deltaHours}h → '
        'save $unitsText units/day (~₦$nairaText/month)';
  }
  
  // ========================================================================
  // UTILITY FUNCTIONS
  // ========================================================================
  
  /// Round value to specified decimal places
  static double roundToDecimal(double value, int places) {
    final mod = math.pow(10, places);
    return (value * mod).round() / mod;
  }
  
  /// Get daily burn bucket for analytics (anonymized)
  /// 
  /// Examples: "0-10", "10-20", "20-30", "30+"
  static String getDailyBurnBucket(double dailyBurn) {
    if (dailyBurn < 10) return '0-10';
    if (dailyBurn < 20) return '10-20';
    if (dailyBurn < 30) return '20-30';
    return '30+';
  }
}
