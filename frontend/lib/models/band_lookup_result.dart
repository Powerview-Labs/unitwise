/// Result of a band lookup query
/// 
/// This model encapsulates band supply hours and unit rates retrieved
/// from the user's location profile (Module 2).
/// 
/// IMPORTANT: The `isAssumption` flag indicates whether the data is
/// actual user data or a fallback default (12 hrs).
class BandLookupResult {
  /// Band supply hours (average daily hours of electricity supply)
  final int hours;
  
  /// Unit rate in Naira per kWh
  final double unitRate;
  
  /// Whether this data is an assumption (fallback) or actual user data
  /// 
  /// true = fallback default (Module 2 data missing/incomplete)
  /// false = actual data from user's location profile
  final bool isAssumption;
  
  /// Source of the data for debugging
  /// Examples: 'firestore', 'fallback', 'cache'
  final String source;
  
  /// Band letter (A-E) if available
  final String? band;
  
  /// DisCo name if available
  final String? disco;
  
  const BandLookupResult({
    required this.hours,
    required this.unitRate,
    required this.isAssumption,
    required this.source,
    this.band,
    this.disco,
  });
  
  /// Create a fallback result when user data is missing
  factory BandLookupResult.fallback({
    int hours = 12,
    double unitRate = 69.0,
  }) {
    return BandLookupResult(
      hours: hours,
      unitRate: unitRate,
      isAssumption: true,
      source: 'fallback',
      band: null,
      disco: null,
    );
  }
  
  /// Create from user's location profile data
  factory BandLookupResult.fromProfile({
    required int hours,
    required double unitRate,
    String? band,
    String? disco,
  }) {
    return BandLookupResult(
      hours: hours,
      unitRate: unitRate,
      isAssumption: false,
      source: 'firestore',
      band: band,
      disco: disco,
    );
  }
  
  /// Convert to JSON for debugging/logging
  Map<String, dynamic> toJson() {
    return {
      'hours': hours,
      'unit_rate': unitRate,
      'is_assumption': isAssumption,
      'source': source,
      if (band != null) 'band': band,
      if (disco != null) 'disco': disco,
    };
  }
  
  @override
  String toString() {
    return 'BandLookupResult('
        'hours: $hours, '
        'rate: ₦$unitRate/kWh, '
        'assumption: $isAssumption, '
        'source: $source'
        '${band != null ? ', band: $band' : ''}'
        '${disco != null ? ', disco: $disco' : ''}'
        ')';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BandLookupResult &&
        other.hours == hours &&
        other.unitRate == unitRate &&
        other.isAssumption == isAssumption &&
        other.source == source &&
        other.band == band &&
        other.disco == disco;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      hours,
      unitRate,
      isAssumption,
      source,
      band,
      disco,
    );
  }
}
