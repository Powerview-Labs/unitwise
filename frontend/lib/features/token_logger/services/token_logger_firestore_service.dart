// lib/features/token_logger/services/token_logger_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/token_log.dart';

/// Token Logger Firestore Service
/// 
/// PURPOSE: Handle all Firestore operations for token logs
/// 
/// SECURITY PRINCIPLES:
///   1. Append-only: Logs can be created, never updated/deleted
///   2. User-scoped: Users can only access their own logs
///   3. Server timestamps: Use Firestore server time for consistency
/// 
/// DATA INTEGRITY:
///   - All writes validated before submission
///   - Offline persistence enabled
///   - Atomic operations where possible
/// 
/// ✅ FIXES:
///   - Proper Timestamp conversion for purchase_date
///   - Server timestamp for created_at
///   - No more type casting errors
///   - ✅ UNIFIED: Now uses 'tokens' collection (shared with Token History)
class TokenLoggerFirestoreService {
  final FirebaseFirestore _firestore;

  TokenLoggerFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Save a new token log
  /// 
  /// SECURITY: Validates all inputs before writing
  /// ATOMICITY: Single transaction, either succeeds or fails completely
  /// OFFLINE: Will queue and sync when connection restored
  /// 
  /// ✅ FIX: Properly converts DateTime to Timestamp for Firestore rules
  /// ✅ UNIFIED: Writes to 'tokens' collection (shared with Token History)
  /// 
  /// RETURNS: ID of created log, or throws on error
  Future<String> saveTokenLog({
    required String userId,
    required TokenLog tokenLog,
  }) async {
    try {
      // SECURITY: Validate user ID
      if (userId.isEmpty) {
        throw Exception('Invalid user ID');
      }

      // SECURITY: Validate token log data
      _validateTokenLog(tokenLog);

      // Create document reference
      // ✅ UNIFIED COLLECTION: Using 'tokens' instead of 'token_logs'
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')  // ✅ Changed from 'token_logs'
          .doc();

      // ✅ FIX: Prepare data with proper Firestore types
      // This ensures purchase_date is a Timestamp (not DateTime string)
      // and created_at uses server timestamp
      final data = {
        'userId': userId,  // ✅ Added for Firestore rules validation
        'amount_paid': tokenLog.amountPaid,
        'purchase_date': Timestamp.fromDate(tokenLog.purchaseDate),  // ✅ Proper Timestamp conversion
        'token_code': tokenLog.tokenCode,  // Can be null
        'disco': tokenLog.disco,
        'band': tokenLog.band,
        'unit_rate': tokenLog.unitRate,
        'rate_used': tokenLog.unitRate,  // ✅ Alias for Token History compatibility
        'units_purchased': tokenLog.unitsPurchased,
        'estimated_units_remaining_at_log': tokenLog.estimatedUnitsRemainingAtLog,
        'estimation_method': tokenLog.estimationMethod,
        'created_at': FieldValue.serverTimestamp(),  // ✅ Server timestamp for consistency
      };

      // ATOMICITY: Write in single operation
      await docRef.set(data);

      if (kDebugMode) {
        print('✅ [TOKEN LOGGER] Saved log to TOKENS collection: ${docRef.id}');
        print('   Amount: ₦${tokenLog.amountPaid}');
        print('   Units: ${tokenLog.unitsPurchased}');
        print('   Date: ${tokenLog.purchaseDate}');
      }

      return docRef.id;

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [TOKEN LOGGER ERROR] Failed to save log: $e');
        print('   Stack trace: $stackTrace');
      }
      throw Exception('Failed to save token log. Please try again.');
    }
  }

  /// Get all token logs for a user
  /// 
  /// SORTING: Most recent first
  /// PAGINATION: Can add limit if needed for performance
  /// ✅ UNIFIED: Reads from 'tokens' collection
  Future<List<TokenLog>> getTokenLogs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')  // ✅ Changed from 'token_logs'
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TokenLog.fromFirestore(doc))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('❌ [TOKEN LOGGER ERROR] Failed to fetch logs: $e');
      }
      return []; // Return empty list on error
    }
  }

  /// Get latest token log for a user
  /// 
  /// PURPOSE: Dashboard uses this to determine starting balance
  /// ✅ UNIFIED: Reads from 'tokens' collection
  Future<TokenLog?> getLatestTokenLog(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')  // ✅ Changed from 'token_logs'
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('ℹ️ [TOKEN LOGGER] No token logs found for user');
        }
        return null;
      }

      final log = TokenLog.fromFirestore(snapshot.docs.first);
      
      if (kDebugMode) {
        print('✅ [TOKEN LOGGER] Latest log from TOKENS collection: ${log.id}');
        print('   Units: ${log.unitsPurchased}');
        print('   Date: ${log.purchaseDate}');
      }

      return log;

    } catch (e) {
      if (kDebugMode) {
        print('❌ [TOKEN LOGGER ERROR] Failed to fetch latest log: $e');
      }
      return null;
    }
  }

  /// Stream token logs for real-time updates
  /// 
  /// PURPOSE: Dashboard can listen for new logs and auto-update
  /// PERFORMANCE: Limited to last 50 logs to avoid excessive data transfer
  /// ✅ UNIFIED: Reads from 'tokens' collection
  Stream<List<TokenLog>> streamTokenLogs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tokens')  // ✅ Changed from 'token_logs'
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TokenLog.fromFirestore(doc))
              .toList();
        });
  }

  /// Get token logs within a date range
  /// 
  /// PURPOSE: Budget planner can analyze spending patterns
  /// ✅ UNIFIED: Reads from 'tokens' collection
  Future<List<TokenLog>> getTokenLogsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')  // ✅ Changed from 'token_logs'
          .where('purchase_date', 
                 isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('purchase_date', 
                 isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('purchase_date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TokenLog.fromFirestore(doc))
          .toList();

    } catch (e) {
      if (kDebugMode) {
        print('❌ [TOKEN LOGGER ERROR] Failed to fetch logs by date: $e');
      }
      return [];
    }
  }

  /// Get total units purchased within a date range
  /// 
  /// PURPOSE: Analytics and budget tracking
  Future<double> getTotalUnitsPurchased({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final logs = await getTokenLogsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    return logs.fold<double>(
      0.0, 
      (sum, log) => sum + log.unitsPurchased,
    );
  }

  /// Get total amount spent within a date range
  /// 
  /// PURPOSE: Budget tracking and financial analytics
  Future<double> getTotalAmountSpent({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final logs = await getTokenLogsByDateRange(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
    );

    return logs.fold<double>(
      0.0, 
      (sum, log) => sum + log.amountPaid,
    );
  }

  /// Validate token log before saving
  /// 
  /// SECURITY: Comprehensive input validation
  /// THROWS: Exception if validation fails
  void _validateTokenLog(TokenLog log) {
    // Validate amount (₦100 - ₦100,000)
    if (log.amountPaid < 100 || log.amountPaid > 100000) {
      throw Exception('Invalid amount: ₦${log.amountPaid}. Must be between ₦100 and ₦100,000.');
    }

    // Validate purchase date (not future, not too old)
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));
    if (log.purchaseDate.isAfter(now)) {
      throw Exception('Purchase date cannot be in the future.');
    }
    if (log.purchaseDate.isBefore(oneYearAgo)) {
      throw Exception('Purchase date cannot be more than 1 year old.');
    }

    // Validate DisCo
    if (log.disco.trim().isEmpty) {
      throw Exception('DisCo name is required.');
    }
    if (log.disco.length > 100) {
      throw Exception('DisCo name too long (max 100 characters).');
    }

    // Validate Band (A-E)
    final bandUpper = log.band.toUpperCase();
    if (!['A', 'B', 'C', 'D', 'E'].contains(bandUpper)) {
      throw Exception('Invalid band: ${log.band}. Must be A, B, C, D, or E.');
    }

    // Validate unit rate (₦4 - ₦250)
    if (log.unitRate < 4.0 || log.unitRate > 250.0) {
      throw Exception('Invalid unit rate: ₦${log.unitRate}/kWh. Must be between ₦4 and ₦250.');
    }

    // Validate units purchased (must be positive)
    if (log.unitsPurchased <= 0) {
      throw Exception('Invalid units purchased: ${log.unitsPurchased}. Must be positive.');
    }

    // Validate estimated remaining (can be 0 but not negative)
    if (log.estimatedUnitsRemainingAtLog < 0) {
      throw Exception('Invalid estimated remaining: ${log.estimatedUnitsRemainingAtLog}. Cannot be negative.');
    }

    // Validate estimation method
    if (log.estimationMethod != 'appliance_based') {
      throw Exception('Invalid estimation method: ${log.estimationMethod}.');
    }

    if (kDebugMode) {
      print('✅ [TOKEN LOGGER] Validation passed');
    }
  }

  /// Check if user has any token logs
  /// 
  /// PURPOSE: First-time user experience
  /// ✅ UNIFIED: Reads from 'tokens' collection
  Future<bool> hasAnyLogs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')  // ✅ Changed from 'token_logs'
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;

    } catch (e) {
      if (kDebugMode) {
        print('❌ [TOKEN LOGGER ERROR] Failed to check logs: $e');
      }
      return false;
    }
  }

  /// Get count of token logs
  /// 
  /// PURPOSE: Display to user (e.g., "You have 12 token logs")
  /// ✅ UNIFIED: Reads from 'tokens' collection
  Future<int> getLogCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')  // ✅ Changed from 'token_logs'
          .count()
          .get();

      return snapshot.count ?? 0;

    } catch (e) {
      if (kDebugMode) {
        print('❌ [TOKEN LOGGER ERROR] Failed to count logs: $e');
      }
      return 0;
    }
  }
}