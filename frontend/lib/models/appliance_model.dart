import 'package:uuid/uuid.dart';

/// Represents a single appliance with usage details
/// 
/// IMPORTANT: All appliances (default and custom) are fully editable.
/// Default appliances are NOT authoritative - they're just starting suggestions.
class Appliance {
  /// Unique identifier for this appliance instance
  final String id;
  
  /// Display name (e.g., "AC", "LED Bulb (7W)", "My Bedroom Fan")
  final String name;
  
  /// Number of this appliance (e.g., 2 TVs, 3 fans)
  final int quantity;
  
  /// Power consumption in watts (e.g., 1000W for AC)
  final double wattage;
  
  /// User-entered hours of usage per day (0-24)
  final double hoursPerDay;
  
  /// Adjusted hours after band supply constraint applied
  /// Formula: min(hoursPerDay, bandSupplyHours)
  final double adjustedHours;
  
  /// Category for grouping (e.g., 'Cooling', 'Lighting', 'Heating')
  final String category;
  
  /// Whether this is a user-added custom appliance
  /// false = from default list (but still fully editable)
  /// true = user created
  final bool isCustom;
  
  Appliance({
    String? id,
    required this.name,
    required this.quantity,
    required this.wattage,
    required this.hoursPerDay,
    double? adjustedHours,
    this.category = 'Other',
    this.isCustom = false,
  })  : id = id ?? const Uuid().v4(),
        adjustedHours = adjustedHours ?? hoursPerDay;
  
  // ========================================================================
  // COMPUTED PROPERTIES
  // ========================================================================
  
  /// Calculate daily unit consumption for this appliance
  /// 
  /// Formula: (Wattage × Quantity × Adjusted Hours) ÷ 1000
  /// 
  /// Example:
  ///   AC: 1000W × 1 × 12h = 12,000 Wh = 12 kWh = 12 units/day
  double get dailyUnits {
    return (wattage * quantity * adjustedHours) / 1000.0;
  }
  
  /// Is this a high-consumption appliance?
  /// 
  /// Criteria (any of):
  ///   - Wattage > 500W
  ///   - Daily units > 2.5
  ///   - Hours per day > 8
  bool get isHighConsumption {
    return wattage > 500 || dailyUnits > 2.5 || hoursPerDay > 8;
  }
  
  /// Was band adjustment applied to this appliance?
  /// 
  /// true = user entered more hours than band can supply
  /// false = user hours are within band supply limits
  bool get wasBandAdjusted {
    return adjustedHours < hoursPerDay;
  }
  
  /// How many hours were reduced due to band adjustment?
  double get hoursReduced {
    return hoursPerDay - adjustedHours;
  }
  
  // ========================================================================
  // SERIALIZATION
  // ========================================================================
  
  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'wattage': wattage,
      'hours_per_day': hoursPerDay,
      'adjusted_hours': adjustedHours,
      'daily_units': dailyUnits,
      'category': category,
      'is_custom': isCustom,
    };
  }
  
  /// Create from Firestore JSON
  factory Appliance.fromJson(Map<String, dynamic> json) {
    return Appliance(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      wattage: (json['wattage'] as num).toDouble(),
      hoursPerDay: (json['hours_per_day'] as num).toDouble(),
      adjustedHours: (json['adjusted_hours'] as num).toDouble(),
      category: json['category'] as String? ?? 'Other',
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }
  
  /// Create a copy with modified fields (immutable pattern)
  Appliance copyWith({
    String? id,
    String? name,
    int? quantity,
    double? wattage,
    double? hoursPerDay,
    double? adjustedHours,
    String? category,
    bool? isCustom,
  }) {
    return Appliance(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      wattage: wattage ?? this.wattage,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      adjustedHours: adjustedHours ?? this.adjustedHours,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }
  
  // ========================================================================
  // UTILITIES
  // ========================================================================
  
  @override
  String toString() {
    return 'Appliance('
        'name: $name, '
        'qty: $quantity, '
        'wattage: ${wattage}W, '
        'hours: ${hoursPerDay}h, '
        'adjusted: ${adjustedHours}h, '
        'units: ${dailyUnits.toStringAsFixed(2)}'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appliance &&
        other.id == id &&
        other.name == name &&
        other.quantity == quantity &&
        other.wattage == wattage &&
        other.hoursPerDay == hoursPerDay &&
        other.adjustedHours == adjustedHours &&
        other.category == category &&
        other.isCustom == isCustom;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      quantity,
      wattage,
      hoursPerDay,
      adjustedHours,
      category,
      isCustom,
    );
  }
}
