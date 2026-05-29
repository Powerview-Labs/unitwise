/// ==============================================================================
/// 👤 USER SERVICE - FIRESTORE USER DATA MANAGEMENT - UPDATED
/// ==============================================================================
/// 
/// PURPOSE:
/// Manages user profile data in Firestore, including location and DisCo information.
/// 
/// FEATURES:
/// - Save location data (area, coordinates, etc.)
/// - Save DisCo and Band information
/// - Update setup completion flags
/// - Retrieve user profile
/// - Submit manual locations for database review (Phase 1)
/// - 🆕 UPDATE USER PROFILE (for onboarding completion tracking)
/// - 🆕 SAVE DAILY BURN ESTIMATE (for Token Logger integration)
/// 
/// SECURITY:
/// - Uses Firebase Auth to get current user
/// - All writes include timestamp
/// - Validates data before saving
/// - Only allows users to update their own profiles
/// 
/// FIXES IN THIS VERSION:
/// ✅ Added updateUserProfile() method for dashboard integration
/// ✅ Improved error handling with kDebugMode checks
/// ✅ Added method for checking location setup completion
/// ✅ Added saveDailyBurnEstimate() method for Token Logger gating
/// 
/// ==============================================================================
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class UserService {
  // ==========================================================================
  // CONFIGURATION
  // ==========================================================================

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================================================
  // PUBLIC METHODS
  // ==========================================================================

  /// Get current user's UID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Save location data to user profile
  /// 
  /// **Parameters:**
  /// - `area`: Area name (e.g., "Akoka")
  /// - `city`: City/LGA name (e.g., "Shomolu")
  /// - `state`: State name (e.g., "Lagos State")
  /// - `country`: Country name (e.g., "Nigeria")
  /// - `latitude`: GPS latitude
  /// - `longitude`: GPS longitude
  /// - `detectionMethod`: "auto" or "manual"
  /// 
  /// **Returns:** true if successful, false otherwise
  Future<bool> saveLocation({
    required String area,
    required String city,
    required String state,
    required String country,
    required double latitude,
    required double longitude,
    required String detectionMethod,
  }) async {
    try {
      final userId = getCurrentUserId();
      
      if (userId == null) {
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      // Validate inputs
      if (area.trim().isEmpty || state.trim().isEmpty) {
        developer.log(
          'Invalid location data: area or state is empty',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      final locationData = {
        'area': area.trim(),
        'city': city.trim(),
        'state': state.trim(),
        'country': country.trim(),
        'coordinates': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'detectionMethod': detectionMethod, // "auto" or "manual"
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            {'location': locationData},
            SetOptions(merge: true),
          );

      developer.log(
        'Location saved: $area, $state',
        name: 'UserService',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error saving location: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return false;
    }
  }

  /// Save DisCo and Band information to user profile
  /// 
  /// **Parameters:**
  /// - `disco`: DisCo name (e.g., "Ikeja Electric")
  /// - `band`: Band letter (e.g., "C")
  /// - `confidence`: Confidence score (0.0 to 1.0)
  /// - `manualOverride`: Whether user manually selected DisCo
  /// 
  /// **Returns:** true if successful, false otherwise
  Future<bool> saveDisco({
    required String disco,
    required String band,
    required double confidence,
    required bool manualOverride,
  }) async {
    try {
      final userId = getCurrentUserId();
      
      if (userId == null) {
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      // Validate inputs
      if (disco.trim().isEmpty || band.trim().isEmpty) {
        developer.log(
          'Invalid DisCo data: disco or band is empty',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      final discoData = {
        'name': disco.trim(),
        'band': band.trim().toUpperCase(),
        'confidence': confidence,
        'manualOverride': manualOverride,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            {'disco': discoData},
            SetOptions(merge: true),
          );

      developer.log(
        'DisCo saved: $disco (Band $band, confidence: ${(confidence * 100).toStringAsFixed(0)}%)',
        name: 'UserService',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error saving DisCo: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return false;
    }
  }

  /// Mark location setup as completed
  /// 
  /// **Returns:** true if successful, false otherwise
  Future<bool> markLocationSetupComplete() async {
    try {
      final userId = getCurrentUserId();
      
      if (userId == null) {
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            {
              'setupCompleted': {
                'location': true,
                'timestamp': FieldValue.serverTimestamp(),
              }
            },
            SetOptions(merge: true),
          );

      developer.log(
        'Location setup marked as complete',
        name: 'UserService',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error marking setup complete: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return false;
    }
  }

  /// Save complete location setup (location + disco + completion flag)
  /// 
  /// This is the main method to call after user confirms their location
  /// 
  /// **Parameters:**
  /// - `locationData`: Map with area, city, state, country, lat, lng, method
  /// - `discoData`: Map with disco, band, confidence, manualOverride
  /// 
  /// **Returns:** true if successful, false otherwise
  Future<bool> saveCompleteLocationSetup({
    required Map<String, dynamic> locationData,
    required Map<String, dynamic> discoData,
  }) async {
    try {
      final userId = getCurrentUserId();
      
      if (userId == null) {
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      // Save everything in a single batch write for atomicity
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(userId);

      batch.set(
        userRef,
        {
          'location': {
            'area': locationData['area'],
            'city': locationData['city'],
            'state': locationData['state'],
            'country': locationData['country'],
            'coordinates': {
              'latitude': locationData['latitude'],
              'longitude': locationData['longitude'],
            },
            'detectionMethod': locationData['detectionMethod'],
            'timestamp': FieldValue.serverTimestamp(),
          },
          'disco': {
            'name': discoData['disco'],
            'band': discoData['band'],
            'confidence': discoData['confidence'],
            'manualOverride': discoData['manualOverride'],
            'timestamp': FieldValue.serverTimestamp(),
          },
          'setupCompleted': {
            'location': true,
            'timestamp': FieldValue.serverTimestamp(),
          }
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      developer.log(
        'Complete location setup saved successfully',
        name: 'UserService',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error saving complete setup: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return false;
    }
  }

  /// Retrieve user profile data
  /// 
  /// **Returns:** User data map or null if not found
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final userId = getCurrentUserId();
      
      if (userId == null) {
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return null;
      }

      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        developer.log(
          'User profile not found',
          name: 'UserService',
          level: 900, // WARNING
        );
        return null;
      }

      return doc.data();
    } catch (e, stackTrace) {
      developer.log(
        'Error retrieving user profile: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return null;
    }
  }

  // ==========================================================================
  // 🆕 NEW: SAVE DAILY BURN ESTIMATE - FOR TOKEN LOGGER INTEGRATION
  // ==========================================================================

  /// Save daily burn estimate from Appliance Estimator
  /// 
  /// This is called when user completes the Appliance Estimator.
  /// The daily_burn_estimate is used by:
  /// - Dashboard to calculate days remaining
  /// - Token Logger to calculate past purchase burn
  /// 
  /// **SECURITY:**
  /// - Validates user is authenticated
  /// - Validates positive burn estimate
  /// - Writes to authenticated user's document only
  /// 
  /// **Parameters:**
  /// - `dailyBurnEstimate`: Total daily consumption in kWh/day
  /// - `applianceCount`: Number of appliances configured (optional)
  /// 
  /// **Returns:** true if successful, false otherwise
  /// 
  /// **Example Usage:**
  /// ```dart
  /// final userService = UserService();
  /// await userService.saveDailyBurnEstimate(
  ///   dailyBurnEstimate: 154.022,
  ///   applianceCount: 5,
  /// );
  /// ```
  Future<bool> saveDailyBurnEstimate({
    required double dailyBurnEstimate,
    int? applianceCount,
  }) async {
    try {
      final userId = getCurrentUserId();
      
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('❌ UserService: No user logged in');
        }
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      // Validate input
      if (dailyBurnEstimate <= 0) {
        if (kDebugMode) {
          debugPrint('❌ UserService: Invalid daily burn estimate: $dailyBurnEstimate');
        }
        developer.log(
          'Invalid daily burn estimate: $dailyBurnEstimate',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      // Save to root user document (required for Token Logger gating)
      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            {
              'daily_burn_estimate': dailyBurnEstimate,
              'appliance_setup_completed': true,
              'appliance_completed_at': DateTime.now().toIso8601String(),
              if (applianceCount != null) 'appliance_count': applianceCount,
            },
            SetOptions(merge: true),
          );

      if (kDebugMode) {
        debugPrint('✅ UserService: Daily burn estimate saved: $dailyBurnEstimate units/day');
        if (applianceCount != null) {
          debugPrint('   Appliance count: $applianceCount');
        }
      }

      developer.log(
        'Daily burn estimate saved: $dailyBurnEstimate units/day (appliances: ${applianceCount ?? 'N/A'})',
        name: 'UserService',
      );

      return true;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error saving daily burn estimate: $e');
      }
      
      developer.log(
        'Error saving daily burn estimate: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      
      return false;
    }
  }

  // ==========================================================================
  // 🆕 NEW: UPDATE USER PROFILE - FOR DASHBOARD INTEGRATION
  // ==========================================================================

  /// Update user profile fields
  /// 
  /// Used for onboarding completion tracking and profile updates.
  /// This method allows updating specific fields without overwriting the entire profile.
  /// 
  /// **SECURITY:**
  /// - Only updates fields for authenticated user's own document
  /// - Requires active user session
  /// - Validates that userId exists before attempting update
  /// 
  /// **Common Use Cases:**
  /// ```dart
  /// // Mark onboarding complete
  /// await userService.updateUserProfile({
  ///   'onboarding_completed': true,
  /// });
  /// 
  /// // Mark appliance setup complete
  /// await userService.updateUserProfile({
  ///   'appliance_setup_completed': true,
  ///   'appliance_completed_at': DateTime.now().toIso8601String(),
  /// });
  /// 
  /// // Mark appliance setup skipped
  /// await userService.updateUserProfile({
  ///   'appliance_setup_completed': false,
  ///   'appliance_skipped_at': DateTime.now().toIso8601String(),
  /// });
  /// ```
  /// 
  /// **Parameters:**
  /// - `updates`: Map of field names and values to update
  /// 
  /// **Returns:** true if update successful, false otherwise
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      // Get current user ID
      final uid = getCurrentUserId();
      
      if (uid == null || uid.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ UserService: Cannot update profile - No user ID');
        }
        developer.log(
          'No user logged in',
          name: 'UserService',
          level: 1000, // ERROR
        );
        return false;
      }

      // Validate that we have something to update
      if (updates.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️  UserService: No fields to update');
        }
        return false;
      }

      // Update user document in Firestore
      await _firestore
          .collection('users')
          .doc(uid)
          .update(updates);

      if (kDebugMode) {
        debugPrint('✅ UserService: Profile updated');
        debugPrint('   Fields: ${updates.keys.join(', ')}');
      }
      
      developer.log(
        'Profile updated: ${updates.keys.join(', ')}',
        name: 'UserService',
      );
      
      return true;
      
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error updating profile - $e');
      }
      
      developer.log(
        'Error updating profile: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      
      return false;
    }
  }

  // ==========================================================================
  // 🆕 NEW: CHECK LOCATION SETUP STATUS
  // ==========================================================================

  /// Check if user has completed location setup
  /// 
  /// Used by login flow to determine if user should be redirected to location setup
  /// 
  /// **Returns:** true if location setup is complete, false otherwise
  Future<bool> hasLocationSetup() async {
    try {
      final profile = await getUserProfile();
      
      if (profile == null) {
        return false;
      }

      // Check if location data exists
      final hasLocation = profile['location'] != null;
      
      // Check if disco data exists
      final hasDisco = profile['disco'] != null;
      
      // Check if setup completion flag exists
      final setupCompleted = profile['setupCompleted']?['location'] == true;

      // User has completed location setup if all three conditions are met
      return hasLocation && hasDisco && setupCompleted;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error checking location setup: $e');
      }
      return false;
    }
  }

  // ==========================================================================
  // 🆕 PHASE 1: MANUAL LOCATION SUBMISSION
  // ==========================================================================

  /// Submits manually entered location for admin review and database addition
  /// 
  /// This allows users to contribute missing locations which will be verified
  /// and added to the disco_mappings collection after review.
  /// 
  /// **Background process** - Non-blocking, user can continue using app
  /// 
  /// **Parameters:**
  /// - `area`: Area name entered by user
  /// - `state`: State name entered by user
  /// - `disco`: DisCo name selected by user
  /// - `band`: Band selected by user
  /// - `submittedBy`: User's phone number or identifier
  /// 
  /// **Returns:** true if submitted successfully, false otherwise
  /// 
  /// **Note:** This is a background operation. User's data is already saved
  /// to their profile - this is just for future database expansion.
  Future<bool> submitLocationForReview({
    required String area,
    required String state,
    required String disco,
    required String band,
    required String submittedBy,
  }) async {
    try {
      developer.log(
        'Submitting location for review: $area, $state',
        name: 'UserService',
      );

      // Create submission document
      final submission = {
        'area': area.trim(),
        'state': state.trim(),
        'disco': disco.trim(),
        'band': band.trim().toUpperCase(),
        'submittedBy': submittedBy,
        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, approved, rejected
        'reviewedBy': null,
        'reviewedAt': null,
        'notes': '',
        // Add user context for better review
        'userId': getCurrentUserId(),
        'source': 'mobile_app_v1',
      };

      // Submit to pending_locations collection for admin review
      await _firestore.collection('pending_locations').add(submission);

      developer.log(
        'Location submitted for review successfully',
        name: 'UserService',
      );

      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error submitting location for review: $e',
        name: 'UserService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );

      // Don't throw - this is a background operation
      // User's data is already saved, this is just for database expansion
      return false;
    }
  }

  /// Save basic user profile information during signup
  Future<bool> saveBasicProfile({
    required String name,
    String? email,
    required String phoneNumber,
  }) async {
    try {
      final userId = getCurrentUserId();

      if (userId == null) {
        if (kDebugMode) {
          debugPrint('❌ UserService: No user logged in');
        }
        return false;
      }

      if (name.trim().isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ UserService: Name is required');
        }
        return false;
      }

      await _firestore.collection('users').doc(userId).set(
        {
          'name': name.trim(),
          'email': email?.trim(),
          'phoneNumber': phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (kDebugMode) {
        debugPrint('✅ UserService: Basic profile saved - $name');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error saving basic profile: $e');
      }
      return false;
    }
  }
}
  // ==========================================================================
  // 🆕 NEW: SAVE USER BASIC PROFILE (NAME, EMAIL, PHONE)
  // ==========================================================================

  /// Save basic user profile information during signup
  ///
  /// Called after OTP verification to store user's name, email, and phone
  ///
  /// **Parameters:**
  /// - `name`: User's full name
  /// - `email`: User's email address (optional)
  /// - `phoneNumber`: User's phone number
  ///
  /// **Returns:** true if successful, false otherwise
