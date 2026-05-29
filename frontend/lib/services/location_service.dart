/// ==============================================================================
/// 📍 LOCATION SERVICE - COMPLETE LOCATION SETUP FLOW (FIXED)
/// ==============================================================================
/// 
/// PURPOSE:
/// Orchestrates the complete location setup process:
/// 1. Get GPS coordinates from device
/// 2. Reverse geocode to get area name
/// 3. Lookup DisCo and Band for the area
/// 4. Return complete location data
/// 
/// FEATURES:
/// - Device GPS integration (geolocator package)
/// - Permission handling
/// - Combines geocode_service and disco_service
/// - Manual area lookup (no GPS)
/// - Fallback to manual entry
/// - Case-insensitive search (akoka = Akoka = AKOKA)
/// - Fixed GPS auto-detect to work for all locations
/// 
/// FIXES APPLIED:
/// - ✅ _lookupDisco now searches only area name (not "area + state")
/// - ✅ Case-insensitive search works for all variations
/// - ✅ Auto-detect works correctly for Akoka and all other locations
/// 
/// ==============================================================================
library;

import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'geocode_service.dart';
import 'disco_service.dart';

class LocationService {
  // ==========================================================================
  // DEPENDENCIES
  // ==========================================================================

  final GeocodeService _geocodeService = GeocodeService();
  final DiscoService _discoService = DiscoService();

  // ==========================================================================
  // CONFIGURATION
  // ==========================================================================

  /// GPS accuracy requirement
  static const LocationAccuracy _desiredAccuracy = LocationAccuracy.high;

  /// GPS timeout duration
  static const Duration _gpsTimeout = Duration(seconds: 15);

  // ==========================================================================
  // PUBLIC METHODS - COMPLETE FLOW
  // ==========================================================================

  /// Executes complete location setup flow
  /// 
  /// **Flow:**
  /// 1. Check/request location permissions
  /// 2. Get GPS coordinates
  /// 3. Reverse geocode to area name
  /// 4. Lookup DisCo and Band
  /// 5. Return combined data
  /// 
  /// **Returns:**
  /// ```dart
  /// {
  ///   // Geocoding data
  ///   'area': 'Yaba',
  ///   'city': 'Lagos',
  ///   'state': 'Lagos State',
  ///   'country': 'Nigeria',
  ///   'locationString': 'Yaba, Lagos, Lagos State',
  ///   
  ///   // GPS coordinates
  ///   'coordinates': {'lat': 6.5244, 'lng': 3.3792},
  ///   'accuracy': 10.5, // meters
  ///   
  ///   // DisCo/Band data
  ///   'disco': 'Ikeja Electric',
  ///   'band': 'B',
  ///   'confidence': 0.95,
  ///   
  ///   // Status flags
  ///   'needsManualSelection': false,
  ///   'geoSource': 'auto', // or 'manual'
  /// }
  /// ```
  Future<Map<String, dynamic>?> setupUserLocation() async {
    try {
      developer.log(
        'Starting location setup...',
        name: 'LocationService',
      );

      // STEP 1: Get current location and area name
      final areaData = await getCurrentLocationArea();

      if (areaData == null) {
        developer.log(
          'Could not determine area from GPS',
          name: 'LocationService',
          level: 900, // WARNING
        );
        return null;
      }

      developer.log(
        'Area detected: ${areaData['area']}, ${areaData['state']}',
        name: 'LocationService',
      );

      // STEP 2: Lookup DisCo and Band
      developer.log(
        'Looking up DisCo and Band...',
        name: 'LocationService',
      );

      final discoData = await _lookupDisco(
        areaData['area'] as String,
        areaData['state'] as String,
      );

      if (discoData == null) {
        developer.log(
          'Could not find DisCo match automatically',
          name: 'LocationService',
          level: 900, // WARNING
        );

        // Return location data but flag for manual selection
        return {
          ...areaData,
          'disco': null,
          'band': null,
          'confidence': null,
          'needsManualSelection': true,
          'geoSource': 'auto',
        };
      }

      // STEP 3: Combine results
      final result = {
        ...areaData,
        'disco': discoData['disco'],
        'band': discoData['band'],
        'confidence': discoData['confidence'],
        'needsManualSelection': false,
        'geoSource': 'auto',
      };

      developer.log(
        'Location setup complete!',
        name: 'LocationService',
      );
      developer.log(
        'Area: ${result['area']} | DisCo: ${result['disco']} | Band: ${result['band']}',
        name: 'LocationService',
      );

      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Location setup error: $e',
        name: 'LocationService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return null;
    }
  }

  // ==========================================================================
  // PUBLIC METHODS - GPS & PERMISSIONS
  // ==========================================================================

  /// Gets current location and reverse geocodes it to area name
  /// 
  /// **Returns:**
  /// ```dart
  /// {
  ///   'area': 'Yaba',
  ///   'city': 'Lagos',
  ///   'state': 'Lagos State',
  ///   'country': 'Nigeria',
  ///   'locationString': 'Yaba, Lagos, Lagos State',
  ///   'coordinates': {'lat': 6.5244, 'lng': 3.3792},
  ///   'accuracy': 10.5
  /// }
  /// ```
  Future<Map<String, dynamic>?> getCurrentLocationArea() async {
    try {
      // STEP 1: Check location permissions
      developer.log(
        'Checking location permissions...',
        name: 'LocationService',
      );

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        developer.log(
          'Location permission denied, requesting...',
          name: 'LocationService',
        );

        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          developer.log(
            'Location permission denied by user',
            name: 'LocationService',
            level: 900, // WARNING
          );
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log(
          'Location permission permanently denied',
          name: 'LocationService',
          level: 1000, // ERROR
        );
        return null;
      }

      // STEP 2: Get current position
      developer.log(
        'Getting current position...',
        name: 'LocationService',
      );

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: _desiredAccuracy,
          timeLimit: _gpsTimeout,
        );
      } catch (e) {
        developer.log(
          'GPS timeout or error: $e',
          name: 'LocationService',
          level: 1000, // ERROR
        );
        return null;
      }

      developer.log(
        'Position obtained: (${position.latitude}, ${position.longitude})',
        name: 'LocationService',
      );
      developer.log(
        'Accuracy: ${position.accuracy}m',
        name: 'LocationService',
      );

      // STEP 3: Reverse geocode
      developer.log(
        'Reverse geocoding coordinates...',
        name: 'LocationService',
      );

      final areaData = await _geocodeService.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (areaData == null) {
        developer.log(
          'Reverse geocoding failed',
          name: 'LocationService',
          level: 1000, // ERROR
        );
        return null;
      }

      // STEP 4: Add GPS metadata
      final result = {
        ...areaData,
        'accuracy': position.accuracy,
      };

      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Get current location error: $e',
        name: 'LocationService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return null;
    }
  }

  /// Checks if location services are enabled on device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Checks current location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Requests location permission from user
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Opens device settings for location permissions
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  // ==========================================================================
  // PUBLIC METHODS - MANUAL AREA LOOKUP
  // ==========================================================================

  /// Manual area lookup (no GPS required)
  /// 
  /// Use this when user types an area name instead of using GPS
  /// 
  /// **Case-insensitive:** Works for "akoka", "Akoka", "AKOKA"
  /// 
  /// **Parameters:**
  /// - `query`: Area name to search (e.g., "Yaba", "Victoria Island", "akoka")
  /// 
  /// **Returns:**
  /// - `Map<String, dynamic>?`: Location data with disco/band info
  /// - `null`: If lookup fails
  Future<Map<String, dynamic>?> manualAreaLookup(String query) async {
    try {
      developer.log(
        'Manual area lookup: $query',
        name: 'LocationService',
      );

      // STEP 1: Lookup DisCo and Band (no geocoding needed)
      // DiscoService handles case-insensitive search internally
      final discoResult = await _discoService.lookup(query: query);

      if (discoResult == null || discoResult['matches'].isEmpty) {
        developer.log(
          'No DisCo matches found for: $query',
          name: 'LocationService',
          level: 900, // WARNING
        );
        return null;
      }

      // Get best match
      final bestMatch = _discoService.getBestMatch(discoResult);
      if (bestMatch == null) return null;

      // STEP 2: Extract data
      final area = _discoService.getArea(bestMatch) ?? query;
      final state = _discoService.getState(bestMatch) ?? '';
      final disco = _discoService.getDisco(bestMatch) ?? 'Unknown';
      final band = _discoService.getBand(bestMatch) ?? 'C';
      final confidence = _discoService.getConfidence(bestMatch) ?? 0.5;
      final isConfident = _discoService.isConfident(bestMatch);

      developer.log(
        'Manual lookup successful: $area → $disco (Band $band)',
        name: 'LocationService',
      );

      // STEP 3: Return data (no coordinates since no GPS)
      return {
        'area': area,
        'city': '', // Not available from manual search
        'state': state,
        'country': 'Nigeria',
        'disco': disco,
        'band': band,
        'confidence': confidence,
        'latitude': 0.0, // Not available
        'longitude': 0.0, // Not available
        'accuracy': 0.0,
        'needsManual': !isConfident,
        'source': 'manual',
      };
    } catch (e, stackTrace) {
      developer.log(
        'Manual lookup error: $e',
        name: 'LocationService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return null;
    }
  }

  // ==========================================================================
  // PUBLIC METHODS - MANUAL LOOKUP (LEGACY)
  // ==========================================================================

  /// Manually looks up DisCo/Band for a given area query
  /// 
  /// Use this when GPS is not available or user wants to search manually
  /// 
  /// **Case-insensitive:** Works for any case variation
  Future<Map<String, dynamic>?> manualLookup({
    required String query,
  }) async {
    try {
      developer.log(
        'Manual lookup for: "$query"',
        name: 'LocationService',
      );

      final result = await _discoService.lookup(query: query);

      if (result == null || result['matches'].isEmpty) {
        developer.log(
          'No matches found for: "$query"',
          name: 'LocationService',
          level: 900, // WARNING
        );
        return null;
      }

      final bestMatch = _discoService.getBestMatch(result);

      if (bestMatch == null) {
        return null;
      }

      return {
        'area': _discoService.getArea(bestMatch),
        'state': _discoService.getState(bestMatch),
        'disco': _discoService.getDisco(bestMatch),
        'band': _discoService.getBand(bestMatch),
        'confidence': _discoService.getConfidence(bestMatch),
        'needsManualSelection': false,
        'geoSource': 'manual',
      };
    } catch (e, stackTrace) {
      developer.log(
        'Manual lookup error: $e',
        name: 'LocationService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return null;
    }
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Looks up DisCo and Band for given area and state
  /// 
  /// ✅ FIXED: Now searches only area name (not "area + state")
  /// This allows GPS auto-detect to work correctly for all locations
  /// 
  /// **Why this fix:**
  /// - Database search_terms are single words: ["akoka", "yaba"]
  /// - Searching "Akoka Lagos State" won't match ["akoka"]
  /// - Searching just "Akoka" WILL match ["akoka"] (case-insensitive)
  /// 
  /// **Case-insensitive:** Backend converts to lowercase automatically
  Future<Map<String, dynamic>?> _lookupDisco(
    String area,
    String state,
  ) async {
    try {
      // ✅ FIXED: Search only area name (not combined with state)
      // Backend search_terms are single words, combining breaks matching
      final query = area; // Changed from '$area $state'

      developer.log(
        'Disco lookup query: "$query" (for area: $area, state: $state)',
        name: 'LocationService',
      );

      final result = await _discoService.lookup(query: query);

      if (result == null || result['matches'].isEmpty) {
        developer.log(
          'No disco matches for: "$query"',
          name: 'LocationService',
          level: 900,
        );
        return null;
      }

      final bestMatch = _discoService.getBestMatch(result);

      if (bestMatch == null) {
        return null;
      }

      final disco = _discoService.getDisco(bestMatch);
      final band = _discoService.getBand(bestMatch);
      final confidence = _discoService.getConfidence(bestMatch);

      developer.log(
        'Disco found: $disco, Band: $band, Confidence: $confidence',
        name: 'LocationService',
      );

      return {
        'disco': disco,
        'band': band,
        'confidence': confidence,
      };
    } catch (e) {
      developer.log(
        'DisCo lookup error: $e',
        name: 'LocationService',
        level: 1000, // ERROR
      );
      return null;
    }
  }

  // ==========================================================================
  // ERROR HANDLING
  // ==========================================================================

  /// Gets user-friendly error message based on error type
  String getUserFriendlyError(dynamic error) {
    if (error == null) {
      return 'Could not determine your location. Please try again or enter manually.';
    }

    final errorString = error.toString().toLowerCase();

    // Permission errors
    if (errorString.contains('permission')) {
      return 'Location permission is required. Please enable location access in your device settings.';
    }

    // GPS errors
    if (errorString.contains('location service') ||
        errorString.contains('gps')) {
      return 'Please turn on location services in your device settings.';
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'Could not get your location. Please make sure you have a clear view of the sky and try again.';
    }

    // Network errors
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }

    // Generic error
    return 'Could not determine your location. Please try again or enter your area manually.';
  }
}