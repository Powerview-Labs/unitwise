// lib/features/token_logger/services/token_logger_gating_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TokenLoggerGatingService {
  final FirebaseFirestore _firestore;

  TokenLoggerGatingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<GatingResult> checkAccess(String userId) async {
    if (kDebugMode) {
      debugPrint('🔵 [GATING] Starting access check for user: $userId');
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore timeout - check emulator connection');
            },
          );

      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('❌ [GATING] User document not found');
        }
        return GatingResult(
          canAccess: false,
          missingStep: GatingStep.profile,
          message: 'User profile not found. Please complete signup.',
        );
      }

      final userData = userDoc.data();
      
      if (userData == null) {
        if (kDebugMode) {
          debugPrint('❌ [GATING] User data is null');
        }
        return GatingResult(
          canAccess: false,
          missingStep: GatingStep.profile,
          message: 'User profile is empty. Please complete signup.',
        );
      }

      if (kDebugMode) {
        debugPrint('🔍 [GATING DEBUG] User data keys: ${userData.keys.toList()}');
        debugPrint('🔍 [GATING DEBUG] Full user data: $userData');
      }

      // GATE 1: Check location setup (nested structure)
      String? disco;
      String? band;
      
      final discoValue = userData['disco'];
      if (kDebugMode) {
        debugPrint('🔍 [GATING DEBUG] disco raw value: $discoValue');
      }
      
      if (discoValue is Map) {
        disco = discoValue['name'] as String?;
        band = discoValue['band'] as String?;
        
        if (kDebugMode) {
          debugPrint('🔍 [GATING DEBUG] Extracted from nested disco object:');
          debugPrint('🔍 [GATING DEBUG]   - disco name: $disco');
          debugPrint('🔍 [GATING DEBUG]   - band: $band');
        }
      } else if (discoValue is String) {
        disco = discoValue;
        final bandValue = userData['band'];
        if (bandValue is String) {
          band = bandValue;
        }
      }
      
      final locationComplete = disco != null && 
                               disco.isNotEmpty && 
                               band != null && 
                               band.isNotEmpty;
      
      if (kDebugMode) {
        debugPrint('🔍 [GATING DEBUG] locationComplete: $locationComplete');
      }
      
      if (!locationComplete) {
        if (kDebugMode) {
          debugPrint('❌ [GATING] Location setup incomplete');
        }
        return GatingResult(
          canAccess: false,
          missingStep: GatingStep.location,
          message: 'Please set up your location and DisCo first.',
        );
      }

      // ✅ GATE 2: Check appliance estimator (ONLY check daily_burn_estimate)
      final dailyBurnValue = userData['daily_burn_estimate'];
      double? dailyBurnEstimate;
      
      if (dailyBurnValue is num) {
        dailyBurnEstimate = dailyBurnValue.toDouble();
      }
      
      if (kDebugMode) {
        debugPrint('🔍 [GATING DEBUG] daily_burn_estimate type: ${dailyBurnValue.runtimeType}');
        debugPrint('🔍 [GATING DEBUG] daily_burn_estimate value: $dailyBurnEstimate');
      }
      
      // ✅ SIMPLIFIED: Only check if daily_burn_estimate exists and > 0
      // Don't check for appliance_setup_completed flag since it's not being set
      final applianceComplete = dailyBurnEstimate != null && dailyBurnEstimate > 0;
      
      if (kDebugMode) {
        debugPrint('🔍 [GATING DEBUG] applianceComplete: $applianceComplete');
      }
      
      if (!applianceComplete) {
        if (kDebugMode) {
          debugPrint('❌ [GATING] Appliance estimator incomplete - daily_burn_estimate not found or zero');
        }
        return GatingResult(
          canAccess: false,
          missingStep: GatingStep.appliance,
          message: 'Please complete the Appliance Estimator to calculate your daily consumption.',
        );
      }

      if (kDebugMode) {
        debugPrint('✅ [GATING] All gates passed!');
        debugPrint('✅ [GATING] Location: $disco (Band $band)');
        debugPrint('✅ [GATING] Daily burn: $dailyBurnEstimate units/day');
      }
      
      return GatingResult(
        canAccess: true,
        missingStep: null,
        message: null,
      );

    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [GATING ERROR] Failed to check access: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      return GatingResult(
        canAccess: false,
        missingStep: GatingStep.error,
        message: 'Error checking prerequisites: ${e.toString()}',
      );
    }
  }

  Future<SetupStatus> getSetupStatus(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        return SetupStatus(
          authComplete: true,
          locationComplete: false,
          applianceComplete: false,
        );
      }

      final userData = userDoc.data();
      if (userData == null) {
        return SetupStatus(
          authComplete: true,
          locationComplete: false,
          applianceComplete: false,
        );
      }

      String? disco;
      String? band;
      
      final discoValue = userData['disco'];
      if (discoValue is Map) {
        disco = discoValue['name'] as String?;
        band = discoValue['band'] as String?;
      }
      
      final locationComplete = disco != null && 
                               disco.isNotEmpty && 
                               band != null && 
                               band.isNotEmpty;

      final dailyBurnValue = userData['daily_burn_estimate'];
      double? dailyBurnEstimate;
      
      if (dailyBurnValue is num) {
        dailyBurnEstimate = dailyBurnValue.toDouble();
      }
      
      final applianceComplete = dailyBurnEstimate != null && dailyBurnEstimate > 0;

      return SetupStatus(
        authComplete: true,
        locationComplete: locationComplete,
        applianceComplete: applianceComplete,
      );

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GATING ERROR] Failed to get setup status: $e');
      }
      
      return SetupStatus(
        authComplete: true,
        locationComplete: false,
        applianceComplete: false,
      );
    }
  }

  Future<LocationData?> getLocationData(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      String? disco;
      String? band;
      
      final discoValue = userData['disco'];
      if (discoValue is Map) {
        disco = discoValue['name'] as String?;
        band = discoValue['band'] as String?;
      }

      if (disco == null || band == null) {
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ [GATING] Retrieved location: $disco, Band $band');
      }

      return LocationData(
        disco: disco,
        band: band,
      );

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GATING ERROR] Failed to get location data: $e');
      }
      return null;
    }
  }

  Future<double?> getDailyBurnRate(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        return null;
      }

      final userData = userDoc.data();
      if (userData == null) {
        return null;
      }

      final dailyBurnValue = userData['daily_burn_estimate'];
      double? dailyBurnEstimate;
      
      if (dailyBurnValue is num) {
        dailyBurnEstimate = dailyBurnValue.toDouble();
      }

      if (dailyBurnEstimate == null) {
        return null;
      }

      if (kDebugMode) {
        debugPrint('✅ [GATING] Retrieved daily burn: $dailyBurnEstimate units/day');
      }

      return dailyBurnEstimate;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [GATING ERROR] Failed to get daily burn rate: $e');
      }
      return null;
    }
  }
}

class GatingResult {
  final bool canAccess;
  final GatingStep? missingStep;
  final String? message;

  const GatingResult({
    required this.canAccess,
    this.missingStep,
    this.message,
  });

  @override
  String toString() {
    return 'GatingResult(canAccess: $canAccess, missingStep: $missingStep, message: $message)';
  }
}

enum GatingStep {
  profile,
  location,
  appliance,
  error,
}

class SetupStatus {
  final bool authComplete;
  final bool locationComplete;
  final bool applianceComplete;

  const SetupStatus({
    required this.authComplete,
    required this.locationComplete,
    required this.applianceComplete,
  });

  bool get isFullySetup => authComplete && locationComplete && applianceComplete;

  @override
  String toString() {
    return 'SetupStatus(auth: $authComplete, location: $locationComplete, '
           'appliance: $applianceComplete)';
  }
}

class LocationData {
  final String disco;
  final String band;

  const LocationData({
    required this.disco,
    required this.band,
  });

  @override
  String toString() {
    return 'LocationData(disco: $disco, band: $band)';
  }
}