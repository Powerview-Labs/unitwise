/// ==============================================================================
/// 🌍 GEOCODE SERVICE - GPS COORDINATES TO AREA NAME
/// ==============================================================================
/// 
/// PURPOSE:
/// Wrapper service for the geocode_reverse Cloud Function.
/// Converts GPS coordinates (latitude, longitude) to human-readable area names.
/// 
/// FEATURES:
/// - Calls geocode_reverse Cloud Function
/// - Client-side input validation
/// - Error handling with user-friendly messages
/// - Automatic timeout handling
/// - Logging for debugging
/// 
/// USAGE:
/// ```dart
/// final geocodeService = GeocodeService();
/// final result = await geocodeService.reverseGeocode(
///   latitude: 6.5244,
///   longitude: 3.3792,
/// );
/// 
/// if (result != null) {
///   debugPrint('Area: ${result['area']}');
///   debugPrint('State: ${result['state']}');
/// }
/// ```
/// 
/// ==============================================================================
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class GeocodeService {
  // ==========================================================================
  // CONFIGURATION
  // ==========================================================================
  
  /// Cloud Function URL for reverse geocoding
  /// 
  /// SECURITY: This should come from environment config in production
  /// For now, using the deployed function URL
  static const String _functionUrl =
      'https://us-central1-unitwise-83a71.cloudfunctions.net/geocode_reverse';
  
  /// Request timeout duration
  static const Duration _timeout = Duration(seconds: 10);
  
  /// Nigeria coordinate bounds for validation
  static const double _latMin = 4.0;
  static const double _latMax = 14.0;
  static const double _lngMin = 2.5;
  static const double _lngMax = 15.0;

  // ==========================================================================
  // PUBLIC METHODS
  // ==========================================================================
  
  /// Reverse geocodes GPS coordinates to area name
  /// 
  /// **Parameters:**
  /// - `latitude`: Latitude coordinate (4.0 to 14.0 for Nigeria)
  /// - `longitude`: Longitude coordinate (2.5 to 15.0 for Nigeria)
  /// 
  /// **Returns:**
  /// - `Map<String, dynamic>?`: Area data including area, city, state, country
  /// - `null`: If geocoding fails or validation error
  /// 
  /// **Response format:**
  /// ```dart
  /// {
  ///   'success': true,
  ///   'area': 'Yaba',
  ///   'city': 'Lagos',
  ///   'state': 'Lagos State',
  ///   'country': 'Nigeria',
  ///   'locationString': 'Yaba, Lagos, Lagos State',
  ///   'displayName': 'Yaba, Lagos Mainland, Lagos State, Nigeria',
  ///   'coordinates': {'lat': 6.5244, 'lng': 3.3792},
  ///   'cached': false
  /// }
  /// ```
  Future<Map<String, dynamic>?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // STEP 1: Client-side validation (defense in depth)
      if (!_isValidCoordinates(latitude, longitude)) {
        developer.log(
          'Invalid coordinates: lat=$latitude, lng=$longitude',
          name: 'GeocodeService',
          level: 900, // WARNING
        );
        return null;
      }

      developer.log(
        'Reverse geocoding: ($latitude, $longitude)',
        name: 'GeocodeService',
      );

      // STEP 2: Prepare request
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
      };

      // STEP 3: Call Cloud Function
      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
            _timeout,
            onTimeout: () {
              throw Exception('Request timeout - please check your connection');
            },
          );

      // STEP 4: Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          developer.log(
            'Geocoding success: ${data['area']}, ${data['state']}',
            name: 'GeocodeService',
          );
          developer.log(
            'Cached: ${data['cached']}',
            name: 'GeocodeService',
          );
          return data;
        } else {
          developer.log(
            'Geocoding failed: ${data['error']}',
            name: 'GeocodeService',
            level: 1000, // ERROR
          );
          return null;
        }
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        developer.log(
          'Rate limit exceeded. Retry after ${data['retryAfter']} seconds',
          name: 'GeocodeService',
          level: 900, // WARNING
        );
        return null;
      } else {
        developer.log(
          'HTTP error: ${response.statusCode}',
          name: 'GeocodeService',
          level: 1000, // ERROR
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Geocoding error: $e',
        name: 'GeocodeService',
        error: e,
        stackTrace: stackTrace,
        level: 1000, // ERROR
      );
      return null;
    }
  }

  /// Gets user-friendly error message for display
  /// 
  /// Use this to convert technical errors into messages users can understand
  String getUserFriendlyError(dynamic error) {
    if (error == null) {
      return 'Could not determine your location. Please try again.';
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your internet connection.';
    }

    if (errorString.contains('429') || errorString.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('invalid') || errorString.contains('coordinate')) {
      return 'Invalid location. Please try again or enter manually.';
    }

    if (errorString.contains('geocoding')) {
      return 'We couldn\'t find your area. Please enter your location manually.';
    }

    // Generic error
    return 'Something went wrong. Please try again or enter your location manually.';
  }

  // ==========================================================================
  // PRIVATE HELPER METHODS
  // ==========================================================================

  /// Validates latitude and longitude coordinates
  /// 
  /// **Validation rules:**
  /// - Latitude must be between 4.0 and 14.0 (Nigeria bounds)
  /// - Longitude must be between 2.5 and 15.0 (Nigeria bounds)
  /// - Must be finite numbers (not NaN or Infinity)
  bool _isValidCoordinates(double latitude, double longitude) {
    // Check if finite (not NaN or Infinity)
    if (!latitude.isFinite || !longitude.isFinite) {
      return false;
    }

    // Check Nigeria bounds
    if (latitude < _latMin || latitude > _latMax) {
      return false;
    }

    if (longitude < _lngMin || longitude > _lngMax) {
      return false;
    }

    return true;
  }
}
