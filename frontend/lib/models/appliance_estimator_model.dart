import 'appliance_model.dart';
import 'power_saver_tip_model.dart';

/// Complete appliance estimator state and data
/// 
/// This is the single source of truth for:
/// - Dashboard unit projections
/// - Token remaining calculations
/// - Budget planner forecasts
/// - Smart tips and alerts
class ApplianceEstimatorModel {
  /// List of all appliances (default and custom)
  final List<Appliance> appliances;
  
  /// Total daily electricity burn in units/day (kWh/day)
  /// 
  /// This is the PRIMARY OUTPUT of the estimator module.
  /// Formula: Sum of all appliance daily units
  final double dailyBurnEstimate;
  
  /// Whether band adjustment was applied to any appliance
  /// 
  /// true = at least one appliance had hours reduced by band constraint
  /// false = all appliance hours are within band supply limits
  final bool bandAdjusted;
  
  /// Whether the estimator has been completed and saved
  /// 
  /// CRITICAL: This flag gates the Token Logger (Module 5)
  /// - false = Token Logger is LOCKED
  /// - true = Token Logger is UNLOCKED
  final bool applianceSetupCompleted;
  
  /// When this estimator was last updated
  final DateTime lastUpdated;
  
  /// Generated power saver tips
  final List<PowerSaverTip> tips;
  
  /// Whether this is a draft (local only) or saved (Firestore)
  final bool isDraft;
  
  /// Whether band data is based on assumptions (fallback)
  /// 
  /// true = Module 2 data missing, using 12hr fallback
  /// false = actual user data from Location Setup
  final bool bandDataIsAssumption;
  
  const ApplianceEstimatorModel({
    required this.appliances,
    required this.dailyBurnEstimate,
    required this.bandAdjusted,
    required this.applianceSetupCompleted,
    required this.lastUpdated,
    this.tips = const [],
    this.isDraft = false,
    this.bandDataIsAssumption = false,
  });
  
  // ========================================================================
  // FACTORY CONSTRUCTORS
  // ========================================================================
  
  /// Empty state (for initialization)
  factory ApplianceEstimatorModel.empty() {
    return ApplianceEstimatorModel(
      appliances: const [],
      dailyBurnEstimate: 0.0,
      bandAdjusted: false,
      applianceSetupCompleted: false,
      lastUpdated: DateTime.now(),
      tips: const [],
      isDraft: false,
      bandDataIsAssumption: false,
    );
  }
  
  // ========================================================================
  // COMPUTED PROPERTIES
  // ========================================================================
  
  /// Total number of appliances
  int get applianceCount => appliances.length;
  
  /// Total number of custom appliances
  int get customApplianceCount => 
      appliances.where((a) => a.isCustom).length;
  
  /// Total number of high-consumption appliances
  int get highConsumptionCount => 
      appliances.where((a) => a.isHighConsumption).length;
  
  /// Whether any appliances exist
  bool get hasAppliances => appliances.isNotEmpty;
  
  /// Whether any tips are available
  bool get hasTips => tips.isNotEmpty;
  
  /// Whether the estimator is valid and ready to save
  bool get isValid => hasAppliances && dailyBurnEstimate > 0;
  
  // ========================================================================
  // SERIALIZATION
  // ========================================================================
  
  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() {
    return {
      'daily_burn_estimate': dailyBurnEstimate,
      'band_adjusted': bandAdjusted,
      'appliance_setup_completed': applianceSetupCompleted,
      'appliances': appliances.map((a) => a.toJson()).toList(),
      'tips_generated': tips.map((t) => t.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
      'version': 'v1',
      'source': 'mobile',
      'band_data_is_assumption': bandDataIsAssumption,
    };
  }
  
  /// Create from Firestore JSON
  factory ApplianceEstimatorModel.fromJson(Map<String, dynamic> json) {
    return ApplianceEstimatorModel(
      dailyBurnEstimate: (json['daily_burn_estimate'] as num).toDouble(),
      bandAdjusted: json['band_adjusted'] as bool,
      applianceSetupCompleted: json['appliance_setup_completed'] as bool,
      appliances: (json['appliances'] as List)
          .map((a) => Appliance.fromJson(a as Map<String, dynamic>))
          .toList(),
      tips: (json['tips_generated'] as List?)
              ?.map((t) => PowerSaverTip.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      isDraft: false,  // Always false when loaded from Firestore
      bandDataIsAssumption: json['band_data_is_assumption'] as bool? ?? false,
    );
  }
  
  // ========================================================================
  // COPY WITH
  // ========================================================================
  
  /// Create copy with modifications (immutable pattern)
  ApplianceEstimatorModel copyWith({
    List<Appliance>? appliances,
    double? dailyBurnEstimate,
    bool? bandAdjusted,
    bool? applianceSetupCompleted,
    DateTime? lastUpdated,
    List<PowerSaverTip>? tips,
    bool? isDraft,
    bool? bandDataIsAssumption,
  }) {
    return ApplianceEstimatorModel(
      appliances: appliances ?? this.appliances,
      dailyBurnEstimate: dailyBurnEstimate ?? this.dailyBurnEstimate,
      bandAdjusted: bandAdjusted ?? this.bandAdjusted,
      applianceSetupCompleted:
          applianceSetupCompleted ?? this.applianceSetupCompleted,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      tips: tips ?? this.tips,
      isDraft: isDraft ?? this.isDraft,
      bandDataIsAssumption: bandDataIsAssumption ?? this.bandDataIsAssumption,
    );
  }
  
  // ========================================================================
  // UTILITIES
  // ========================================================================
  
  @override
  String toString() {
    return 'ApplianceEstimatorModel('
        'appliances: $applianceCount, '
        'dailyBurn: ${dailyBurnEstimate.toStringAsFixed(2)} units/day, '
        'completed: $applianceSetupCompleted, '
        'bandAdjusted: $bandAdjusted, '
        'tips: ${tips.length}'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplianceEstimatorModel &&
        other.appliances.length == appliances.length &&
        other.dailyBurnEstimate == dailyBurnEstimate &&
        other.bandAdjusted == bandAdjusted &&
        other.applianceSetupCompleted == applianceSetupCompleted &&
        other.lastUpdated == lastUpdated &&
        other.isDraft == isDraft &&
        other.bandDataIsAssumption == bandDataIsAssumption;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      appliances.length,
      dailyBurnEstimate,
      bandAdjusted,
      applianceSetupCompleted,
      lastUpdated,
      isDraft,
      bandDataIsAssumption,
    );
  }
}
