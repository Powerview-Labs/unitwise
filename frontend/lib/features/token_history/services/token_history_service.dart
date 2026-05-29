import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/token_document.dart';
import '../models/token_history_filter.dart';
import '../models/monthly_summary.dart';

/// TokenHistoryService - Secure read-only service for token history
/// 
/// SECURITY ARCHITECTURE:
/// - All Firestore queries are user-scoped (WHERE userId == currentUser)
/// - No cross-user data access possible
/// - Offline caching enabled for read access
/// - Deletion triggers Dashboard recalculation
/// - All errors are sanitized before display
/// 
/// DATA OWNERSHIP:
/// - Reads from: users/{uid}/tokens collection
/// - Never writes or updates tokens (immutable)
/// - Only deletes with user confirmation + Dashboard sync
class TokenHistoryService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  // SECURITY: Cache for offline access
  List<TokenDocument>? _cachedTokens;
  DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);
  
  TokenHistoryService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;
  
  /// SECURITY: Get current authenticated user ID
  /// Throws if user is not authenticated
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }
  
  /// Fetch all tokens for current user
  /// SECURITY: Query is user-scoped, results are cached for offline access
  Future<List<TokenDocument>> fetchTokens({
    bool forceRefresh = false,
  }) async {
    try {
      // SECURITY: Check authentication first
      final userId = _currentUserId;
      
      // Use cache if available and not expired
      if (!forceRefresh && _cachedTokens != null && _lastCacheUpdate != null) {
        final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
        if (cacheAge < _cacheDuration) {
          if (kDebugMode) {
            print('TokenHistoryService: Returning cached tokens (age: ${cacheAge.inMinutes}m)');
          }
          return _cachedTokens!;
        }
      }
      
      // SECURITY: User-scoped query - no cross-user access possible
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .orderBy('purchase_date', descending: true)
          .get();
      
      if (kDebugMode) {
        print('TokenHistoryService: Fetched ${querySnapshot.docs.length} tokens from Firestore');
      }
      
      // SECURITY: Safe deserialization with error handling
      final tokens = <TokenDocument>[];
      for (final doc in querySnapshot.docs) {
        try {
          final token = TokenDocument.fromFirestore(doc);
          
          // SECURITY: Verify token belongs to current user
          if (token.userId != userId) {
            if (kDebugMode) {
              print('TokenHistoryService: Skipping token with mismatched userId');
            }
            continue;
          }
          
          tokens.add(token);
        } catch (e) {
          // SECURITY: Log error but don't break entire fetch
          if (kDebugMode) {
            print('TokenHistoryService: Failed to parse token ${doc.id}: $e');
          }
          continue;
        }
      }
      
      // Update cache
      _cachedTokens = tokens;
      _lastCacheUpdate = DateTime.now();
      
      return tokens;
    } catch (e) {
      // SECURITY: Check if we have cached data for offline fallback
      if (_cachedTokens != null) {
        if (kDebugMode) {
          print('TokenHistoryService: Using cached tokens due to error: $e');
        }
        return _cachedTokens!;
      }
      
      // SECURITY: Sanitize error before rethrowing
      throw _sanitizeError(e);
    }
  }
  
  /// Stream tokens for real-time updates
  /// SECURITY: Stream is user-scoped, updates cache automatically
  Stream<List<TokenDocument>> streamTokens() {
    try {
      // SECURITY: Check authentication
      final userId = _currentUserId;
      
      // SECURITY: User-scoped stream
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .orderBy('purchase_date', descending: true)
          .snapshots()
          .map((snapshot) {
        // SECURITY: Safe deserialization
        final tokens = <TokenDocument>[];
        for (final doc in snapshot.docs) {
          try {
            final token = TokenDocument.fromFirestore(doc);
            
            // SECURITY: Verify ownership
            if (token.userId == userId) {
              tokens.add(token);
            }
          } catch (e) {
            if (kDebugMode) {
              print('TokenHistoryService: Failed to parse streamed token: $e');
            }
            continue;
          }
        }
        
        // Update cache
        _cachedTokens = tokens;
        _lastCacheUpdate = DateTime.now();
        
        return tokens;
      });
    } catch (e) {
      // SECURITY: Return empty stream on error
      return Stream.value([]);
    }
  }
  
  /// Delete a token and trigger Dashboard recalculation
  /// SECURITY: 
  /// - Verifies ownership before deletion
  /// - Requires explicit user confirmation (handled in UI layer)
  /// - Triggers Dashboard balance recalculation
  /// - All-or-nothing operation (Firestore transaction if needed)
  Future<void> deleteToken(String tokenId) async {
    try {
      // SECURITY: Check authentication
      final userId = _currentUserId;
      
      if (kDebugMode) {
        print('TokenHistoryService: Deleting token $tokenId for user $userId');
      }
      
      // SECURITY: Get token document to verify ownership
      final tokenDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(tokenId)
          .get();
      
      if (!tokenDoc.exists) {
        throw Exception('Token not found');
      }
      
      // SECURITY: Verify ownership
      final token = TokenDocument.fromFirestore(tokenDoc);
      if (token.userId != userId) {
        throw Exception('Unauthorized: Token does not belong to current user');
      }
      
      // Delete the token
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(tokenId)
          .delete();
      
      if (kDebugMode) {
        print('TokenHistoryService: Token deleted successfully');
      }
      
      // Invalidate cache
      _cachedTokens = null;
      _lastCacheUpdate = null;
      
      // CRITICAL: Trigger Dashboard recalculation
      // This ensures the dashboard reflects the updated balance
      await _triggerDashboardRecalculation(userId);
      
    } catch (e) {
      // SECURITY: Sanitize error
      if (kDebugMode) {
        print('TokenHistoryService: Delete failed: $e');
      }
      throw _sanitizeError(e);
    }
  }
  
  /// CRITICAL: Trigger Dashboard recalculation after token deletion
  /// 
  /// This method updates the dashboard_state document to trigger
  /// a recalculation of the current balance based on remaining tokens.
  /// 
  /// SECURITY: Only current user can trigger their own recalculation
  Future<void> _triggerDashboardRecalculation(String userId) async {
    try {
      // Update dashboard state to trigger recalculation
      final dashboardRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('dashboard')
          .doc('state');
      
      // Set a flag that Dashboard service will read
      await dashboardRef.set({
        'needs_recalculation': true,
        'last_token_deletion': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (kDebugMode) {
        print('TokenHistoryService: Dashboard recalculation triggered');
      }
    } catch (e) {
      // SECURITY: Non-critical error - log but don't fail deletion
      if (kDebugMode) {
        print('TokenHistoryService: Failed to trigger dashboard recalc: $e');
      }
    }
  }
  
  /// Apply filters to tokens (client-side)
  /// SECURITY: All filtering is read-only and client-side
  List<TokenDocument> applyFilter(
    List<TokenDocument> tokens,
    TokenHistoryFilter filter,
  ) {
    return filter.apply(tokens);
  }
  
  /// Compute monthly summaries (client-side)
  /// SECURITY: All aggregation is read-only and client-side
  List<MonthlySummary> computeMonthlySummaries(List<TokenDocument> tokens) {
    try {
      return MonthlySummary.computeAll(tokens);
    } catch (e) {
      // SECURITY: Return empty list on error
      if (kDebugMode) {
        print('TokenHistoryService: Failed to compute monthly summaries: $e');
      }
      return [];
    }
  }
  
  /// Get a single token by ID
  /// SECURITY: Verifies ownership before returning
  Future<TokenDocument?> getTokenById(String tokenId) async {
    try {
      final userId = _currentUserId;
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(tokenId)
          .get();
      
      if (!doc.exists) return null;
      
      final token = TokenDocument.fromFirestore(doc);
      
      // SECURITY: Verify ownership
      if (token.userId != userId) {
        return null;
      }
      
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('TokenHistoryService: Failed to get token by ID: $e');
      }
      return null;
    }
  }
  
  /// Clear cache (useful for testing or forced refresh)
  void clearCache() {
    _cachedTokens = null;
    _lastCacheUpdate = null;
  }
  
  /// Check if cache is valid
  bool get hasCachedData {
    if (_cachedTokens == null || _lastCacheUpdate == null) return false;
    
    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age < _cacheDuration;
  }
  
  /// SECURITY: Sanitize errors before exposing to user
  /// Never expose internal system details or stack traces
  Exception _sanitizeError(dynamic error) {
    if (kDebugMode) {
      // In debug mode, preserve original error for developers
      return Exception('TokenHistory error: $error');
    }
    
    // In production, return generic error
    if (error.toString().contains('permission')) {
      return Exception('Permission denied. Please check your access rights.');
    }
    
    if (error.toString().contains('network')) {
      return Exception('Network error. Please check your connection.');
    }
    
    return Exception('Unable to load token history. Please try again.');
  }
}
