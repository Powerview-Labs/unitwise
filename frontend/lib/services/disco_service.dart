/// ==============================================================================
/// ⚡ DISCO SERVICE - AREA TO DISCO/BAND LOOKUP (PHASE 4A UPDATED)
/// ==============================================================================
///
/// PURPOSE:
/// Wrapper service for the disco_lookup Cloud Function.
/// Updated to work with Phase 4A backend changes.
///
/// CHANGES FROM OLD VERSION:
/// - Uses 'searchTerm' parameter (not 'query')
/// - Handles new response format: { success, results: [{area, disco, band, hours, confidence}], count }
/// - Simplified response processing
///
/// ==============================================================================
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

class DiscoService {
  // ==========================================================================
  // CONFIGURATION
  // ==========================================================================

  /// Cloud Function URL for DisCo lookup
  static const String _functionUrl =
      'https://us-central1-unitwise-83a71.cloudfunctions.net/disco_lookup';

  /// Request timeout duration
  static const Duration _timeout = Duration(seconds: 10);

  /// Minimum confidence score to consider a match valid
  static const double _minConfidenceThreshold = 0.5;

  // ==========================================================================
  // PUBLIC METHODS
  // ==========================================================================

  /// Looks up DisCo and Band for a given area/location query
  ///
  /// **Parameters:**
  /// - `query`: Search text (e.g., "yaba", "garki 1", "ikeja")
  /// - `minConfidence`: Minimum confidence score (0.0-1.0), defaults to 0.5
  ///
  /// **Returns:**
  /// ```dart
  /// {
  ///   'success': true,
  ///   'query': 'yaba',
  ///   'matches': [
  ///     {
  ///       'area': 'Yaba',
  ///       'city': 'Yaba',
  ///       'state': 'Lagos State',
  ///       'disco': 'Eko Electricity Distribution Company',
  ///       'band': 'A',
  ///       'hours': 20,
  ///       'confidence': 1.0,
  ///       'notes': 'University Road area'
  ///     }
  ///   ],
  ///   'totalMatches': 1
  /// }
  /// ```
  Future<Map<String, dynamic>?> lookup({
    required String query,
    double minConfidence = _minConfidenceThreshold,
  }) async {
    try {
      // STEP 1: Validate query
      if (query.trim().isEmpty) {
        developer.log(
          'Empty query provided',
          name: 'DiscoService',
          level: 900,
        );
        return null;
      }

      if (query.trim().length < 3) {
        developer.log(
          'Query too short: $query',
          name: 'DiscoService',
          level: 900,
        );
        return null;
      }

      developer.log(
        'Looking up DisCo/Band for: "$query"',
        name: 'DiscoService',
      );

      // STEP 2: Prepare request with CORRECT parameter name
      final requestBody = {
        'searchTerm': query.trim(), // ✅ FIXED: Changed from 'query' to 'searchTerm'
      };

      developer.log(
        'Request body: ${jsonEncode(requestBody)}',
        name: 'DiscoService',
      );

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

      developer.log(
        'Response status: ${response.statusCode}',
        name: 'DiscoService',
      );
      developer.log(
        'Response body: ${response.body}',
        name: 'DiscoService',
      );

      // STEP 4: Handle response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['success'] == true) {
          // NEW FORMAT: { success: true, results: [...], count: N }
          final results = data['results'] as List?;

          if (results == null || results.isEmpty) {
            developer.log(
              'No results returned from backend',
              name: 'DiscoService',
              level: 900,
            );
            return {
              'success': true,
              'query': query,
              'matches': [],
              'totalMatches': 0,
            };
          }

          // Convert results to matches format (for backward compatibility)
          final matches = <Map<String, dynamic>>[];

          for (var result in results) {
            final resultMap = result as Map<String, dynamic>;
            
            // Extract fields from new format
            final area = resultMap['area'] as String? ?? '';
            final city = resultMap['city'] as String? ?? '';
            final state = resultMap['state'] as String? ?? '';
            final disco = resultMap['disco'] as String? ?? 'Unknown';
            final band = resultMap['band'] as String? ?? 'C';
            final hours = resultMap['hours'] as int? ?? 12;
            final confidence = (resultMap['confidence'] as num?)?.toDouble() ?? 1.0;
            final notes = resultMap['notes'] as String? ?? '';

            // Only include matches above confidence threshold
            if (confidence >= minConfidence) {
              matches.add({
                'area': area,
                'city': city,
                'state': state,
                'disco': disco,
                'band': band,
                'hours': hours,
                'similarity': confidence, // Use 'similarity' for backward compatibility
                'confidence': confidence,
                'notes': notes,
                'matchType': confidence == 1.0 ? 'exact' : 'fuzzy',
              });
            }
          }

          developer.log(
            'DisCo lookup success: ${matches.length} matches',
            name: 'DiscoService',
          );

          if (matches.isNotEmpty) {
            final bestMatch = matches.first;
            developer.log(
              'Best match: ${bestMatch['area']} → ${bestMatch['disco']} (Band ${bestMatch['band']}, ${bestMatch['hours']}hrs/day)',
              name: 'DiscoService',
            );
          }

          return {
            'success': true,
            'query': query,
            'matches': matches,
            'totalMatches': matches.length,
          };
        } else {
          // Handle error response
          final error = data['error'] ?? 'Unknown error';
          developer.log(
            'DisCo lookup failed: $error',
            name: 'DiscoService',
            level: 1000,
          );
          return null;
        }
      } else if (response.statusCode == 400) {
        // Bad request
        developer.log(
          'Bad request: ${response.body}',
          name: 'DiscoService',
          level: 1000,
        );
        return null;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        developer.log(
          'Rate limit exceeded',
          name: 'DiscoService',
          level: 900,
        );
        return null;
      } else {
        developer.log(
          'HTTP error ${response.statusCode}: ${response.body}',
          name: 'DiscoService',
          level: 1000,
        );
        return null;
      }
    } catch (e, stackTrace) {
      developer.log(
        'DisCo lookup error: $e',
        name: 'DiscoService',
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
      return null;
    }
  }

  // ==========================================================================
  // HELPER METHODS (Unchanged)
  // ==========================================================================

  /// Extracts the best match from lookup results
  Map<String, dynamic>? getBestMatch(Map<String, dynamic>? lookupResult) {
    if (lookupResult == null) return null;

    final matches = lookupResult['matches'] as List?;
    if (matches == null || matches.isEmpty) return null;

    return matches.first as Map<String, dynamic>;
  }

  /// Gets DisCo name from lookup result
  String? getDisco(Map<String, dynamic>? match) {
    return match?['disco'] as String?;
  }

  /// Gets Band from lookup result
  String? getBand(Map<String, dynamic>? match) {
    return match?['band'] as String?;
  }

  /// Gets confidence score from lookup result
  double? getConfidence(Map<String, dynamic>? match) {
    final confidence = match?['confidence'];
    if (confidence is num) return confidence.toDouble();
    
    // Fallback to similarity for backward compatibility
    final similarity = match?['similarity'];
    if (similarity is num) return similarity.toDouble();
    
    return null;
  }

  /// Gets area name from lookup result
  String? getArea(Map<String, dynamic>? match) {
    return match?['area'] as String?;
  }

  /// Gets state name from lookup result
  String? getState(Map<String, dynamic>? match) {
    return match?['state'] as String?;
  }

  /// Gets supply hours from lookup result
  int? getHours(Map<String, dynamic>? match) {
    return match?['hours'] as int?;
  }

  /// Checks if confidence score is high enough to trust
  bool isConfident(Map<String, dynamic>? match, {double threshold = 0.7}) {
    final confidence = getConfidence(match);
    if (confidence == null) return false;
    return confidence >= threshold;
  }

  /// Gets user-friendly error message for display
  String getUserFriendlyError(dynamic error) {
    if (error == null) {
      return 'Could not find your electricity provider. Please try entering your area manually.';
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your internet connection.';
    }

    if (errorString.contains('429') || errorString.contains('rate limit')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    if (errorString.contains('no matches') || errorString.contains('not found')) {
      return 'We couldn\'t find a match for your area. Please try a different search or select manually.';
    }

    return 'Something went wrong. Please try again or select your DisCo manually.';
  }

  /// Formats DisCo and Band for display
  ///
  /// Example: "Ikeja Electric (Band B - 16hrs/day)"
  String formatDiscoDisplay(Map<String, dynamic>? match) {
    final disco = getDisco(match);
    final band = getBand(match);
    final hours = getHours(match);

    if (disco == null) return 'Unknown';
    if (band == null) return disco;
    if (hours == null) return '$disco (Band $band)';

    return '$disco (Band $band - ${hours}hrs/day)';
  }
}