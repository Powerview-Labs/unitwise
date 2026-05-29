/// Represents a recommendation to reduce electricity usage
/// 
/// Tips are generated based on high-consumption appliances and suggest
/// realistic hour reductions with calculated savings.
class PowerSaverTip {
  /// ID of the appliance this tip is about
  final String applianceId;
  
  /// Display name of the appliance
  final String applianceName;
  
  /// Current hours of usage per day
  final int currentHours;
  
  /// Suggested hours of usage per day
  final int suggestedHours;
  
  /// Units saved per day if suggestion is followed
  final double unitsSavedPerDay;
  
  /// Naira saved per month if suggestion is followed
  final double nairaSavedPerMonth;
  
  /// Human-readable recommendation text
  final String recommendation;
  
  const PowerSaverTip({
    required this.applianceId,
    required this.applianceName,
    required this.currentHours,
    required this.suggestedHours,
    required this.unitsSavedPerDay,
    required this.nairaSavedPerMonth,
    required this.recommendation,
  });
  
  /// Number of hours reduced
  int get hoursReduced => currentHours - suggestedHours;
  
  /// Units saved per week
  double get unitsSavedPerWeek => unitsSavedPerDay * 7;
  
  /// Naira saved per day
  double get nairaSavedPerDay => nairaSavedPerMonth / 30;
  
  /// Convert to JSON for storage/analytics
  Map<String, dynamic> toJson() {
    return {
      'appliance_id': applianceId,
      'appliance_name': applianceName,
      'current_hours': currentHours,
      'suggested_hours': suggestedHours,
      'hours_reduced': hoursReduced,
      'units_saved_per_day': unitsSavedPerDay,
      'naira_saved_per_month': nairaSavedPerMonth,
      'recommendation': recommendation,
    };
  }
  
  /// Create from JSON
  factory PowerSaverTip.fromJson(Map<String, dynamic> json) {
    return PowerSaverTip(
      applianceId: json['appliance_id'] as String,
      applianceName: json['appliance_name'] as String,
      currentHours: json['current_hours'] as int,
      suggestedHours: json['suggested_hours'] as int,
      unitsSavedPerDay: (json['units_saved_per_day'] as num).toDouble(),
      nairaSavedPerMonth: (json['naira_saved_per_month'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
    );
  }
  
  @override
  String toString() {
    return 'PowerSaverTip('
        'appliance: $applianceName, '
        'reduce: ${hoursReduced}hrs, '
        'save: ${unitsSavedPerDay.toStringAsFixed(1)} units/day, '
        '₦${nairaSavedPerMonth.toStringAsFixed(0)}/month'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PowerSaverTip &&
        other.applianceId == applianceId &&
        other.currentHours == currentHours &&
        other.suggestedHours == suggestedHours;
  }
  
  @override
  int get hashCode {
    return Object.hash(applianceId, currentHours, suggestedHours);
  }
}
