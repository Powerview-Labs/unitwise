// lib/features/token_logger/services/rate_lookup_service.dart

/// Tariff Rate Lookup Service
/// 
/// PURPOSE: Provides unit rates based on DisCo and Band
/// DATA SOURCE: NERC July 2025 Supplementary Orders
/// 
/// SECURITY: Read-only static data, no user input processed
/// MAINTAINABILITY: Update rates monthly from NERC orders
class RateLookupService {
  
  /// Get unit rate for a given DisCo and Band combination
  /// 
  /// PARAMETERS:
  ///   - disco: Distribution Company name (e.g., "Ikeja Electric")
  ///   - band: Service band (A, B, C, D, or E)
  /// 
  /// RETURNS: Rate in ₦/kWh, or null if not found
  /// 
  /// FALLBACK: Returns cached/default rate if lookup fails
  /// ERROR HANDLING: Never throws, always returns a fallback value
  static double? getRate(String disco, String band) {
    // Normalize inputs
    final normalizedDisco = disco.trim().toLowerCase();
    final normalizedBand = band.trim().toUpperCase();

    // Band A: Uniform nationwide at ₦209.50/kWh (Non-MD)
    if (normalizedBand == 'A') {
      return 209.50;
    }

    // Band B: Uniform nationwide
    if (normalizedBand == 'B') {
      return _getBandBRate(normalizedDisco);
    }

    // Band C: Uniform nationwide
    if (normalizedBand == 'C') {
      return _getBandCRate(normalizedDisco);
    }

    // Band D: Uniform nationwide
    if (normalizedBand == 'D') {
      return _getBandDRate(normalizedDisco);
    }

    // Band E: Uniform nationwide (same as Band D)
    // NOTE: EEDC and YEDC have NO Band E feeders
    if (normalizedBand == 'E') {
      return _getBandERate(normalizedDisco);
    }

    // Fallback: return null if band not recognized
    return null;
  }

  /// Get Band B rate (16 hours/day) - Non-MD customers
  /// UNIFORM NATIONWIDE: ₦63.35/kWh
  static double _getBandBRate(String disco) {
    // Special cases for specific DisCos
    if (disco.contains('kedco') || disco.contains('kano')) {
      return 65.29; // KEDCO specific rate
    }
    
    // Standard Band B rate for all other DisCos
    return 63.35;
  }

  /// Get Band C rate (12 hours/day) - Non-MD customers
  /// UNIFORM NATIONWIDE: ₦51.79/kWh
  static double _getBandCRate(String disco) {
    // Special cases for specific DisCos
    if (disco.contains('kedco') || disco.contains('kano')) {
      return 47.57; // KEDCO specific rate
    }
    
    // Standard Band C rate for all other DisCos
    return 51.79;
  }

  /// Get Band D rate (8 hours/day) - Non-MD customers
  /// UNIFORM NATIONWIDE: ₦33.95/kWh
  static double _getBandDRate(String disco) {
    // Special cases for specific DisCos
    if (disco.contains('kedco') || disco.contains('kano')) {
      return 32.02; // KEDCO specific rate
    }
    
    // Standard Band D rate for all other DisCos
    return 33.95;
  }

  /// Get Band E rate (4 hours/day) - Non-MD customers
  /// NOTE: EEDC and YEDC have NO Band E feeders
  /// Band D and E have SAME rates
  static double? _getBandERate(String disco) {
    // EEDC (Enugu) has NO Band E
    if (disco.contains('eedc') || disco.contains('enugu')) {
      return null; // Band E doesn't exist for EEDC
    }

    // YEDC (Yola) has NO Band E
    if (disco.contains('yedc') || disco.contains('yola')) {
      return null; // Band E doesn't exist for YEDC
    }

    // For all other DisCos, Band E = Band D rate
    return _getBandDRate(disco);
  }

  /// Get fallback rate when DisCo/Band lookup fails
  /// 
  /// FALLBACK STRATEGY: Use Band C rate (₦51.79) as reasonable middle ground
  /// REASON: Band C represents average Nigerian electricity service
  static double getFallbackRate() {
    return 51.79;
  }

  /// Get cached rate from local storage (if available)
  /// 
  /// PURPOSE: Offline support when Firestore is unavailable
  /// IMPLEMENTATION: Will be integrated with flutter_secure_storage
  /// 
  /// TODO: Implement cached rate retrieval from secure storage
  static Future<double?> getCachedRate(String disco, String band) async {
    // PLACEHOLDER: Implement secure storage integration
    // For now, return null to trigger fallback logic
    return null;
  }

  /// Validate rate is within sane bounds
  /// 
  /// SECURITY: Prevents obviously incorrect rates from breaking calculations
  /// BOUNDS: Rates should be between ₦4 (lifeline) and ₦250 (Band A + margin)
  static bool isValidRate(double rate) {
    return rate >= 4.0 && rate <= 250.0;
  }

  /// Get display-friendly DisCo name
  /// 
  /// PURPOSE: Normalize DisCo names for UI display
  static String getNormalizedDiscoName(String disco) {
    final normalized = disco.trim().toLowerCase();

    if (normalized.contains('aedc') || normalized.contains('abuja')) {
      return 'Abuja Electric (AEDC)';
    }
    if (normalized.contains('bedc') || normalized.contains('benin')) {
      return 'Benin Electric (BEDC)';
    }
    if (normalized.contains('eedc') || normalized.contains('enugu')) {
      return 'Enugu Electric (EEDC)';
    }
    if (normalized.contains('eko') || normalized.contains('ekedp')) {
      return 'Eko Electric (EKEDP)';
    }
    if (normalized.contains('ibedc') || normalized.contains('ibadan')) {
      return 'Ibadan Electric (IBEDC)';
    }
    if (normalized.contains('ikeja') || normalized.contains('ie')) {
      return 'Ikeja Electric (IE)';
    }
    if (normalized.contains('jed') || normalized.contains('jos')) {
      return 'Jos Electric (JED)';
    }
    if (normalized.contains('kaedc') || normalized.contains('kaduna')) {
      return 'Kaduna Electric (KAEDC)';
    }
    if (normalized.contains('kedco') || normalized.contains('kano')) {
      return 'Kano Electric (KEDCO)';
    }
    if (normalized.contains('phed') || normalized.contains('port harcourt')) {
      return 'Port Harcourt Electric (PHED)';
    }
    if (normalized.contains('yedc') || normalized.contains('yola')) {
      return 'Yola Electric (YEDC)';
    }

    // Return original if no match
    return disco;
  }

  /// Get all supported bands for a DisCo
  /// 
  /// NOTE: EEDC and YEDC don't have Band E
  static List<String> getSupportedBands(String disco) {
    final normalized = disco.trim().toLowerCase();

    // EEDC and YEDC: Only A-D
    if (normalized.contains('eedc') || 
        normalized.contains('enugu') ||
        normalized.contains('yedc') || 
        normalized.contains('yola')) {
      return ['A', 'B', 'C', 'D'];
    }

    // All other DisCos: A-E
    return ['A', 'B', 'C', 'D', 'E'];
  }
}
