import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../utils/budget_constants.dart';

/// Service for retrieving electricity tariff rates
/// WHY: Abstracts rate lookup with fallback chain for resilience
/// SECURITY: Read-only access, never mutates rate data
class RateLookupService {
  final FirebaseFirestore _firestore;

  RateLookupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════
  // DISCO NAME TO CODE MAPPING
  // WHY: Firestore rates collection uses short codes (IE, AEDC)
  //      but user disco field stores full names (Ikeja Electric)
  // ═══════════════════════════════════════════════════════════
  static const Map<String, String> _discoNameToCode = {
    'Ikeja Electric': 'IE',
    'Eko Electricity Distribution Company': 'EKEDP',
    'Abuja Electricity Distribution Company': 'AEDC',
    'Port Harcourt Electricity Distribution Company': 'PHED',
    'Enugu Electricity Distribution Company': 'EEDC',
    'Ibadan Electricity Distribution Company': 'IBEDC',
    'Jos Electricity Distribution Company': 'JED',
    'Benin Electricity Distribution Company': 'BEDC',
    'Kaduna Electricity Distribution Company': 'KAEDC',
    'Kano Electricity Distribution Company': 'KEDCO',
    'Yola Electricity Distribution Company': 'YEDC',
  };

  /// Convert full DisCo name to code for Firestore lookup
  String _getDiscoCode(String discoName) {
    // Try exact match first
    if (_discoNameToCode.containsKey(discoName)) {
      return _discoNameToCode[discoName]!;
    }

    // Try case-insensitive match
    final lowerName = discoName.toLowerCase();
    for (var entry in _discoNameToCode.entries) {
      if (entry.key.toLowerCase() == lowerName) {
        return entry.value;
      }
    }

    // If no match, return original name (might be already a code)
    if (kDebugMode) {
      debugPrint('⚠️ Unknown DisCo name: $discoName, using as-is');
    }
    return discoName;
  }

  // ==================== MAIN RATE LOOKUP ====================

  /// Get current rate for user's DisCo and Band
  /// 
  /// Lookup chain:
  /// 1. User profile cached rate (if fresh)
  /// 2. Global rates collection from Firestore
  /// 3. Fallback constant (₦68.85)
  /// 
  /// WHY: Ensures app always has a rate, even offline
  /// SECURITY: All Firestore reads are user-scoped or global read-only
  Future<RateLookupResult> getCurrentRate({
    required String userId,
    required String disco,
    required String band,
    double? cachedRate,
    DateTime? cacheTimestamp,
  }) async {
    // Convert disco name to code for Firestore lookup
    final discoCode = _getDiscoCode(disco);
    
    if (kDebugMode) {
      debugPrint('RateLookup: Starting for $disco (code: $discoCode) Band $band');
    }

    // STEP 1: Check if cached rate is fresh
    if (cachedRate != null && cacheTimestamp != null) {
      if (!BudgetConstants.isRateStale(cacheTimestamp)) {
        if (kDebugMode) {
          debugPrint('RateLookup: Using cached rate ₦$cachedRate');
        }
        return RateLookupResult(
          rate: cachedRate,
          source: RateSource.cached,
          disco: disco,
          band: band,
        );
      } else {
        if (kDebugMode) {
          debugPrint('RateLookup: Cached rate is stale, fetching fresh');
        }
      }
    }

    // STEP 2: Fetch from global rates collection
    try {
      final freshRate = await _fetchFromGlobalRates(discoCode, band);
      if (freshRate != null) {
        // Update user profile with fresh rate (fire-and-forget)
        _updateUserProfileRate(userId, freshRate).catchError((e) {
          if (kDebugMode) {
            debugPrint('Failed to update user profile rate: $e');
          }
        });

        return RateLookupResult(
          rate: freshRate,
          source: RateSource.firestore,
          disco: disco,
          band: band,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RateLookup: Firestore fetch failed - $e');
      }
      // Continue to fallback
    }

    // STEP 3: Use cached rate if available (even if stale)
    if (cachedRate != null) {
      if (kDebugMode) {
        debugPrint('RateLookup: Using stale cached rate ₦$cachedRate');
      }
      return RateLookupResult(
        rate: cachedRate,
        source: RateSource.cachedStale,
        disco: disco,
        band: band,
      );
    }

    // STEP 4: Use fallback constant
    if (kDebugMode) {
      debugPrint(
        'RateLookup: Using fallback rate ₦${BudgetConstants.fallbackRatePerUnit}',
      );
    }
    return RateLookupResult(
      rate: BudgetConstants.fallbackRatePerUnit,
      source: RateSource.fallback,
      disco: disco,
      band: band,
    );
  }

  // ==================== FIRESTORE FETCHING ====================

  /// Fetch rate from global rates collection
  /// Path: /rates/{disco}/bands/{band}
  /// 
  /// SECURITY: Read-only access, no authentication required
  /// WHY: Rates are public data, centrally managed by admin
  Future<double?> _fetchFromGlobalRates(String disco, String band) async {
    try {
      final docRef = _firestore
          .collection(BudgetConstants.ratesCollection)
          .doc(disco)
          .collection('bands')
          .doc(band);

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        if (kDebugMode) {
          debugPrint('Rate document not found: $disco/$band');
        }
        return null;
      }

      final data = snapshot.data();
      if (data == null || !data.containsKey('rate_per_unit')) {
        if (kDebugMode) {
          debugPrint('Rate field missing in document');
        }
        return null;
      }

      final rate = (data['rate_per_unit'] as num).toDouble();

      if (kDebugMode) {
        debugPrint('Fetched rate from Firestore: ₦$rate for $disco Band $band');
      }

      return rate;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching rate from Firestore: $e');
      }
      return null;
    }
  }

  /// Update user profile with fresh rate
  /// Path: /users/{uid}/profile
  /// 
  /// SECURITY: User-scoped write (enforced by Firestore rules)
  /// WHY: Cache rate locally for offline use
  Future<void> _updateUserProfileRate(String userId, double rate) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'current_rate': rate,
        'rate_updated_at': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        debugPrint('Updated user profile with rate ₦$rate');
      }
    } catch (e) {
      // SECURITY: Don't throw - this is non-critical
      if (kDebugMode) {
        debugPrint('Failed to update user profile rate: $e');
      }
    }
  }

  // ==================== HELPER METHODS ====================

  /// Fetch all available bands for a DisCo
  /// WHY: Useful for admin UI or settings screen
  Future<List<String>> getAvailableBands(String disco) async {
    try {
      final snapshot = await _firestore
          .collection(BudgetConstants.ratesCollection)
          .doc(disco)
          .collection('bands')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching available bands: $e');
      }
      return ['A', 'B', 'C', 'D', 'E']; // Default Band list
    }
  }

  /// Fetch all available DisCos
  /// WHY: Useful for location setup
  Future<List<String>> getAvailableDiscos() async {
    try {
      final snapshot = await _firestore
          .collection(BudgetConstants.ratesCollection)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching available DisCos: $e');
      }
      return []; // Empty list if fetch fails
    }
  }
}

// ==================== RESULT CLASSES ====================

/// Result of rate lookup with metadata
class RateLookupResult {
  final double rate;
  final RateSource source;
  final String disco;
  final String band;

  RateLookupResult({
    required this.rate,
    required this.source,
    required this.disco,
    required this.band,
  });

  /// User-friendly message about rate source
  String get sourceMessage {
    switch (source) {
      case RateSource.cached:
        return 'Using your saved rate';
      case RateSource.firestore:
        return 'Rate updated from server';
      case RateSource.cachedStale:
        return 'Using offline rate (may be outdated)';
      case RateSource.fallback:
        return 'Using estimated rate (offline)';
    }
  }

  bool get isOffline =>
      source == RateSource.cachedStale || source == RateSource.fallback;

  @override
  String toString() {
    return 'RateLookupResult(₦$rate from $source for $disco Band $band)';
  }
}

/// Source of the rate data
enum RateSource {
  /// Fresh cached rate from user profile (< 7 days old)
  cached,

  /// Fresh rate from Firestore global collection
  firestore,

  /// Stale cached rate (> 7 days old but better than fallback)
  cachedStale,

  /// Hardcoded fallback constant
  fallback,
}