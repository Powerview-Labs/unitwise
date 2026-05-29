/**
 * Full Appliance Catalog
 * 
 * CRITICAL: This is the complete reference catalog (33 appliances)
 * Available via "Add Appliance" (+) button, NOT auto-loaded
 * 
 * Mental Model:
 * - This is a LIBRARY/REFERENCE, not user data
 * - Users search/browse this to add appliances
 * - Nothing from this list is saved unless user explicitly adds + configures
 * - All appliances start with hours = 0
 * 
 * Organization:
 * - Kitchen (9)
 * - Cooling (5)
 * - Lighting (4)
 * - Entertainment (4)
 * - Laundry (3)
 * - Heating (3)
 * - Electronics (3)
 * - Security (2)
 */

import '../models/appliance_model.dart';

class FullApplianceCatalog {
  /// Get the complete appliance catalog (33 items)
  /// Available via Add (+) button
  static List<Appliance> getCatalog() {
    return [
      // ═══════════════════════════════════════════════════════════
      // KITCHEN (9 appliances)
      // ═══════════════════════════════════════════════════════════
      
      Appliance(
        id: 'catalog_refrigerator',
        name: 'Refrigerator',
        category: 'Kitchen',
        wattage: 150.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_freezer',
        name: 'Freezer',
        category: 'Kitchen',
        wattage: 200.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_microwave',
        name: 'Microwave Oven',
        category: 'Kitchen',
        wattage: 1200.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_blender',
        name: 'Blender',
        category: 'Kitchen',
        wattage: 400.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_electric_kettle',
        name: 'Electric Kettle',
        category: 'Kitchen',
        wattage: 1500.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_toaster',
        name: 'Toaster',
        category: 'Kitchen',
        wattage: 800.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_rice_cooker',
        name: 'Rice Cooker',
        category: 'Kitchen',
        wattage: 700.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_electric_stove_2burner',
        name: 'Electric Stove (2-Burner)',
        category: 'Kitchen',
        wattage: 2000.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_water_dispenser',
        name: 'Water Dispenser',
        category: 'Kitchen',
        wattage: 500.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // COOLING (5 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_ac_0_75hp',
        name: 'AC (0.75HP)',
        category: 'Cooling',
        wattage: 850.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_ac_1hp',
        name: 'AC (1HP)',
        category: 'Cooling',
        wattage: 1000.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_ac_1_5hp',
        name: 'AC (1.5HP)',
        category: 'Cooling',
        wattage: 1500.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_standing_fan',
        name: 'Standing Fan',
        category: 'Cooling',
        wattage: 60.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_ceiling_fan',
        name: 'Ceiling Fan',
        category: 'Cooling',
        wattage: 75.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // LIGHTING (4 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_led_bulb_7w',
        name: 'LED Bulb (7W)',
        category: 'Lighting',
        wattage: 7.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_led_bulb_9w',
        name: 'LED Bulb (9W)',
        category: 'Lighting',
        wattage: 9.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_led_bulb_12w',
        name: 'LED Bulb (12W)',
        category: 'Lighting',
        wattage: 12.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_fluorescent_tube',
        name: 'Fluorescent Tube',
        category: 'Lighting',
        wattage: 40.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // ENTERTAINMENT (4 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_led_tv_32',
        name: 'LED TV (32")',
        category: 'Entertainment',
        wattage: 50.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_led_tv_43',
        name: 'LED TV (43")',
        category: 'Entertainment',
        wattage: 80.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_led_tv_55',
        name: 'LED TV (55")',
        category: 'Entertainment',
        wattage: 110.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_home_theatre',
        name: 'Home Theatre System',
        category: 'Entertainment',
        wattage: 150.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // LAUNDRY (3 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_washing_machine',
        name: 'Washing Machine',
        category: 'Laundry',
        wattage: 500.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_iron',
        name: 'Electric Iron',
        category: 'Laundry',
        wattage: 1000.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_dryer',
        name: 'Clothes Dryer',
        category: 'Laundry',
        wattage: 3000.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // HEATING (3 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_water_heater',
        name: 'Water Heater',
        category: 'Heating',
        wattage: 2500.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_space_heater',
        name: 'Space Heater',
        category: 'Heating',
        wattage: 1500.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_hair_dryer',
        name: 'Hair Dryer',
        category: 'Heating',
        wattage: 1200.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // ELECTRONICS (3 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_laptop',
        name: 'Laptop Computer',
        category: 'Electronics',
        wattage: 65.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_desktop',
        name: 'Desktop Computer',
        category: 'Electronics',
        wattage: 200.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_phone_charger',
        name: 'Phone Charger',
        category: 'Electronics',
        wattage: 5.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      // ═══════════════════════════════════════════════════════════
      // SECURITY (2 appliances)
      // ═══════════════════════════════════════════════════════════

      Appliance(
        id: 'catalog_cctv_camera',
        name: 'CCTV Camera',
        category: 'Security',
        wattage: 10.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),

      Appliance(
        id: 'catalog_security_light',
        name: 'Security Light',
        category: 'Security',
        wattage: 20.0,
        quantity: 1,
        hoursPerDay: 0.0,
        isCustom: false,
      ),
    ];
  }

  /// Get catalog count
  static int get catalogCount => 33;

  /// Get appliances by category
  static List<Appliance> getByCategory(String category) {
    return getCatalog().where((a) => a.category == category).toList();
  }

  /// Get all categories
  static List<String> getCategories() {
    return [
      'Kitchen',
      'Cooling',
      'Lighting',
      'Entertainment',
      'Laundry',
      'Heating',
      'Electronics',
      'Security',
    ];
  }

  /// Search catalog by name
  static List<Appliance> search(String query) {
    final lowerQuery = query.toLowerCase();
    return getCatalog().where((a) {
      return a.name.toLowerCase().contains(lowerQuery) ||
          a.category.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Check if an appliance exists in catalog
  static bool existsInCatalog(String applianceId) {
    return getCatalog().any((a) => a.id == applianceId);
  }
}
