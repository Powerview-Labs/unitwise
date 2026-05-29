import '../models/appliance_model.dart';

/// Default appliance list for UnitWise Appliance Estimator
/// 
/// IMPORTANT DESIGN PRINCIPLES:
/// 1. This is a BASELINE, not a source of truth
/// 2. Users can FREELY edit wattage, hours, quantity
/// 3. Custom appliances are treated IDENTICALLY
/// 4. Defaults are NEVER locked or mandatory
/// 5. Once edited, appliance becomes "user-owned"
/// 
/// Purpose: Reduce friction, speed up first-time setup, provide
/// reasonable wattage assumptions for common Nigerian appliances
class DefaultAppliances {
  // Prevent instantiation
  DefaultAppliances._();
  
  /// Complete list of default appliances
  /// 
  /// Notes:
  /// - Wattages are typical values for Nigerian market
  /// - Hours default to 0 (user must set)
  /// - Quantity defaults to 1
  /// - All values are FULLY EDITABLE by users
  static final List<Appliance> list = [
    // ======================================================================
    // LIGHTING (Category)
    // ======================================================================
    Appliance(
      name: 'LED Bulb (7W)',
      wattage: 7,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Lighting',
      isCustom: false,
    ),
    Appliance(
      name: 'LED Bulb (9W)',
      wattage: 9,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Lighting',
      isCustom: false,
    ),
    Appliance(
      name: 'LED Bulb (12W)',
      wattage: 12,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Lighting',
      isCustom: false,
    ),
    Appliance(
      name: 'Fluorescent Tube',
      wattage: 40,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Lighting',
      isCustom: false,
    ),
    
    // ======================================================================
    // COOLING (Category)
    // ======================================================================
    Appliance(
      name: 'Standing Fan',
      wattage: 60,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Cooling',
      isCustom: false,
    ),
    Appliance(
      name: 'Table/Ceiling Fan',
      wattage: 75,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Cooling',
      isCustom: false,
    ),
    Appliance(
      name: 'AC (0.75HP)',
      wattage: 800,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Cooling',
      isCustom: false,
    ),
    Appliance(
      name: 'AC (1HP)',
      wattage: 1000,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Cooling',
      isCustom: false,
    ),
    Appliance(
      name: 'AC (1.5HP)',
      wattage: 1500,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Cooling',
      isCustom: false,
    ),
    Appliance(
      name: 'AC (2HP)',
      wattage: 2000,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Cooling',
      isCustom: false,
    ),
    
    // ======================================================================
    // ENTERTAINMENT (Category)
    // ======================================================================
    Appliance(
      name: 'LED TV (32")',
      wattage: 50,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Entertainment',
      isCustom: false,
    ),
    Appliance(
      name: 'LED TV (43")',
      wattage: 80,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Entertainment',
      isCustom: false,
    ),
    Appliance(
      name: 'LED TV (55")',
      wattage: 100,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Entertainment',
      isCustom: false,
    ),
    Appliance(
      name: 'Plasma TV (43")',
      wattage: 150,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Entertainment',
      isCustom: false,
    ),
    Appliance(
      name: 'Home Theater',
      wattage: 200,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Entertainment',
      isCustom: false,
    ),
    
    // ======================================================================
    // KITCHEN (Category)
    // ======================================================================
    Appliance(
      name: 'Fridge (Small)',
      wattage: 120,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    Appliance(
      name: 'Fridge (Medium)',
      wattage: 150,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    Appliance(
      name: 'Fridge (Large)',
      wattage: 250,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    Appliance(
      name: 'Freezer',
      wattage: 200,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    Appliance(
      name: 'Microwave',
      wattage: 1000,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    Appliance(
      name: 'Electric Kettle',
      wattage: 1500,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    Appliance(
      name: 'Blender',
      wattage: 400,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Kitchen',
      isCustom: false,
    ),
    
    // ======================================================================
    // HEATING (Category)
    // ======================================================================
    Appliance(
      name: 'Electric Iron',
      wattage: 1000,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Heating',
      isCustom: false,
    ),
    Appliance(
      name: 'Water Heater',
      wattage: 2000,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Heating',
      isCustom: false,
    ),
    
    // ======================================================================
    // LAUNDRY (Category)
    // ======================================================================
    Appliance(
      name: 'Washing Machine',
      wattage: 500,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Laundry',
      isCustom: false,
    ),
    
    // ======================================================================
    // ELECTRONICS (Category)
    // ======================================================================
    Appliance(
      name: 'Laptop',
      wattage: 65,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Electronics',
      isCustom: false,
    ),
    Appliance(
      name: 'Desktop PC',
      wattage: 200,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Electronics',
      isCustom: false,
    ),
    Appliance(
      name: 'Phone Charger',
      wattage: 10,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Electronics',
      isCustom: false,
    ),
    Appliance(
      name: 'Router/Modem',
      wattage: 15,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Electronics',
      isCustom: false,
    ),
    Appliance(
      name: 'Printer',
      wattage: 50,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Electronics',
      isCustom: false,
    ),
    
    // ======================================================================
    // SECURITY (Category)
    // ======================================================================
    Appliance(
      name: 'CCTV Camera',
      wattage: 10,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Security',
      isCustom: false,
    ),
    
    // ======================================================================
    // OTHER (Category)
    // ======================================================================
    Appliance(
      name: 'Water Pump',
      wattage: 750,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Other',
      isCustom: false,
    ),
    Appliance(
      name: 'Vacuum Cleaner',
      wattage: 1200,
      quantity: 1,
      hoursPerDay: 0,
      category: 'Other',
      isCustom: false,
    ),
  ];
  
  /// Get appliances by category
  static List<Appliance> getByCategory(String category) {
    return list.where((a) => a.category == category).toList();
  }
  
  /// Get all unique categories
  static List<String> get categories {
    final categorySet = list.map((a) => a.category).toSet();
    return categorySet.toList()..sort();
  }
  
  /// Search appliances by name
  static List<Appliance> search(String query) {
    final lowerQuery = query.toLowerCase();
    return list.where((a) => 
      a.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
