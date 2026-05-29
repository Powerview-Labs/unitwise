import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/band_lookup_result.dart';
import '../config/app_config.dart';

/// Abstract interface for band data lookup
/// 
/// CRITICAL ARCHITECTURE RULE:
/// - Module 3 (Appliance Estimator) depends on this INTERFACE
/// - Band data comes from Module 2 (Location Setup)
/// - Module 3 NEVER calculates or infers band data itself
/// - Module 3 is READ-ONLY consumer of band data
/// 
/// Source of Truth: users/{uid}/profile/location (created by Module 2)
/// 
/// This abstraction allows future implementations:
/// - Firestore (current)
/// - Cached values
/// - API sync
/// - Outage state adjustments
abstract class BandLookupService {
  /// Get band supply hours for a user
  /// 
  /// Returns BandLookupResult with:
  /// - hours: average daily supply hours for user's band
  /// - unitRate: ₦/kWh for user's DisCo and band
  /// - isAssumption: whether this is fallback data (Module 2 missing)
  /// 
  /// Never throws - returns fallback if data unavailable
  Future<BandLookupResult> getBandSupplyHours(String userId);
  
  /// Get unit rate for a user
  /// 
  /// Convenience method that extracts just the rate
  Future<double> getUnitRate(String userId);
}

/// Firestore implementation (current MVP)
/// 
/// Reads from Module 2's location profile data
class FirestoreBandLookupService implements BandLookupService {
  final FirebaseFirestore _firestore;
  
  FirestoreBandLookupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<BandLookupResult> getBandSupplyHours(String userId) async {
    try {
      // Read from Module 2's location profile document
      final profileDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profile')
          .doc('location')  // Module 2 creates this
          .get();
      
      // Module 2 data missing - use safe fallback
      if (!profileDoc.exists) {
        if (AppConfig.isTestMode) {
          debugPrint('⚠️ Module 2 location profile not found');
          debugPrint('   Using fallback: ${AppConfig.bandHoursFallback} hrs');
        }
        
        return BandLookupResult.fallback(
          hours: AppConfig.bandHoursFallback,
          unitRate: AppConfig.defaultUnitRate,
        );
      }
      
      final data = profileDoc.data()!;
      
      // Extract band hours
      final bandHours = data['band_hours'] as int?;
      if (bandHours == null) {
        if (AppConfig.isTestMode) {
          debugPrint('⚠️ band_hours field missing in profile');
          debugPrint('   Using fallback: ${AppConfig.bandHoursFallback} hrs');
        }
        
        return BandLookupResult.fallback(
          hours: AppConfig.bandHoursFallback,
          unitRate: AppConfig.defaultUnitRate,
        );
      }
      
      // Extract unit rate
      final unitRate = (data['unit_rate'] as num?)?.toDouble() ?? 
          AppConfig.defaultUnitRate;
      
      // Extract optional fields
      final band = data['band'] as String?;
      final disco = data['disco'] as String?;
      
      if (AppConfig.isTestMode) {
        debugPrint('✅ Band data loaded from Module 2');
        debugPrint('   DisCo: $disco');
        debugPrint('   Band: $band');
        debugPrint('   Supply hours: $bandHours hrs/day');
        debugPrint('   Unit rate: ₦$unitRate/kWh');
      }
      
      return BandLookupResult.fromProfile(
        hours: bandHours,
        unitRate: unitRate,
        band: band,
        disco: disco,
      );
    } catch (e) {
      // Network error or Firestore unavailable - safe fallback
      debugPrint('❌ Error fetching band hours: $e');
      debugPrint('   Using fallback: ${AppConfig.bandHoursFallback} hrs');
      
      return BandLookupResult.fallback(
        hours: AppConfig.bandHoursFallback,
        unitRate: AppConfig.defaultUnitRate,
      );
    }
  }
  
  @override
  Future<double> getUnitRate(String userId) async {
    final result = await getBandSupplyHours(userId);
    return result.unitRate;
  }
}

/// Mock implementation (for testing)
/// 
/// Use this in tests to avoid Firestore dependencies
class MockBandLookupService implements BandLookupService {
  final int mockHours;
  final double mockUnitRate;
  final bool mockIsAssumption;
  
  const MockBandLookupService({
    this.mockHours = 12,
    this.mockUnitRate = 69.0,
    this.mockIsAssumption = false,
  });
  
  @override
  Future<BandLookupResult> getBandSupplyHours(String userId) async {
    return BandLookupResult(
      hours: mockHours,
      unitRate: mockUnitRate,
      isAssumption: mockIsAssumption,
      source: 'mock',
      band: 'C',
      disco: 'Test DisCo',
    );
  }
  
  @override
  Future<double> getUnitRate(String userId) async {
    return mockUnitRate;
  }
}
