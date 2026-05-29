/**
 * Starter Appliances Data
 * 
 * CRITICAL: This is NOT the full catalog!
 * This is a small, realistic starter set (5-7 items) that loads when user clicks "Load Defaults".
 * 
 * Mental Model:
 * - These are TEMPLATES, not saved data
 * - All start with hours = 0 (user must configure)
 * - User can add more from the full catalog via Add (+) button
 * - Only appliances with hours > 0 OR quantity > 0 are saved
 * 
 * Design Rationale:
 * - Reduces cognitive load
 * - Prevents deletion fatigue
 * - Encourages user to configure only what they use
 * - Keeps database lean
 */

import '../models/appliance_model.dart';

class StarterAppliancesData {
  /// Get the starter set of appliances (5-7 common items)
  /// These load when user taps "Load Defaults"
  /// All start with hours = 0 - user must configure
  static List<Appliance> getStarterAppliances() {
    return [
      // 1. LED Bulb - Most common
      Appliance(
        id: 'starter_led_bulb_7w',
        name: 'LED Bulb (7W)',
        category: 'Lighting',
        wattage: 7.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set
        isCustom: false,
      ),

      // 2. Standing Fan - Very common in Nigeria
      Appliance(
        id: 'starter_standing_fan',
        name: 'Standing Fan',
        category: 'Cooling',
        wattage: 60.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set
        isCustom: false,
      ),

      // 3. LED TV - Common entertainment
      Appliance(
        id: 'starter_led_tv_43',
        name: 'LED TV (43")',
        category: 'Entertainment',
        wattage: 80.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set
        isCustom: false,
      ),

      // 4. Refrigerator - Essential appliance
      Appliance(
        id: 'starter_refrigerator',
        name: 'Refrigerator',
        category: 'Kitchen',
        wattage: 150.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set (typically 24hrs but let user decide)
        isCustom: false,
      ),

      // 5. Phone Charger - Universal
      Appliance(
        id: 'starter_phone_charger',
        name: 'Phone Charger',
        category: 'Electronics',
        wattage: 5.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set
        isCustom: false,
      ),

      // 6. AC (Optional) - Common in urban areas
      Appliance(
        id: 'starter_ac_1hp',
        name: 'AC (1HP)',
        category: 'Cooling',
        wattage: 1000.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set
        isCustom: false,
      ),

      // 7. Freezer (Optional) - Common in households
      Appliance(
        id: 'starter_freezer',
        name: 'Freezer',
        category: 'Kitchen',
        wattage: 200.0,
        quantity: 1,
        hoursPerDay: 0.0, // User must set
        isCustom: false,
      ),
    ];
  }

  /// Get count of starter appliances
  static int get starterCount => 7;

  /// Check if an appliance is in the starter set
  static bool isStarterAppliance(String applianceId) {
    final starterIds = getStarterAppliances().map((a) => a.id).toSet();
    return starterIds.contains(applianceId);
  }
}
