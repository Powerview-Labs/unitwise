import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstraction layer for reading from other modules
/// 
/// CRITICAL: This service ONLY reads, NEVER writes
/// 
/// ✅ FIXED: getLatestToken() now reads from Firestore
/// ✅ FIXED: getDailyBurnRate() now reads from user document
/// ✅ UNIFIED: Uses 'tokens' collection (shared with Token History)
class DependencyResolver {
  DependencyResolver();

  /// Get daily burn rate from Appliance Estimator
  /// 
  /// ✅ FIXED: Now reads from users/{uid}.daily_burn_estimate
  Future<double?> getDailyBurnRate() async {
    try {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] 📊 Reading daily burn rate from estimator...');
      }
      
      // Get current user
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ No user logged in');
        }
        return null;
      }
      
      // Read from Firestore users/{uid} document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ User document not found');
        }
        return null;
      }
      
      final data = userDoc.data();
      if (data == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ User document data is null');
        }
        return null;
      }
      
      // Read the daily_burn_estimate field
      final burnRate = data['daily_burn_estimate'] as num?;
      
      if (burnRate == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ℹ️  No daily burn estimate found');
        }
        return null;
      }
      
      // Convert to double and validate
      final burnRateDouble = burnRate.toDouble();
      
      // SECURITY: Validate before returning
      if (burnRateDouble < 0 || burnRateDouble.isNaN || burnRateDouble.isInfinite) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ Invalid burn rate: $burnRateDouble');
        }
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ✅ Burn rate: ${burnRateDouble.toStringAsFixed(1)} units/day');
      }
      
      return burnRateDouble;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ❌ Error reading burn rate: $e');
      }
      return null;
    }
  }

  /// Check if appliance estimator setup is completed
  /// 
  /// ✅ Already implemented correctly
  Future<bool> isEstimatorCompleted() async {
    try {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] 🔍 Checking estimator completion status...');
      }
      
      // Get current user
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ No user logged in');
        }
        return false;
      }
      
      // Read from Firestore users/{uid} document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ User document not found');
        }
        return false;
      }
      
      final data = userDoc.data();
      if (data == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ User document data is null');
        }
        return false;
      }
      
      // Read the appliance_setup_completed flag
      final completed = data['appliance_setup_completed'] as bool? ?? false;
      
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ${completed ? '✅' : '❌'} Estimator completed: $completed');
        if (completed) {
          final completedAt = data['appliance_completed_at'] as String?;
          debugPrint('[DependencyResolver] 📅 Completed at: $completedAt');
        }
      }
      
      return completed;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ❌ Error checking estimator: $e');
      }
      return false;
    }
  }

  /// Get latest token data from Token Logger
  /// 
  /// ✅ FIXED: Now reads from Firestore users/{uid}/tokens collection
  /// ✅ UNIFIED: Shares same collection with Token History
  /// 
  /// Returns: Map with 'units', 'purchase_date', 'estimated_remaining' or null
  Future<Map<String, dynamic>?> getLatestToken() async {
    try {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] 🎫 Reading latest token from logger...');
      }
      
      // Get current user
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      
      if (user == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ No user logged in');
        }
        return null;
      }
      
      // Query latest token log (ordered by created_at descending, limit 1)
      // ✅ UNIFIED COLLECTION: Using 'tokens' (shared with Token History)
      final tokenSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();
      
      if (tokenSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ℹ️  No token logged yet');
        }
        return null;
      }
      
      final tokenDoc = tokenSnapshot.docs.first;
      final tokenData = tokenDoc.data();
      
      // Extract and validate fields
      final unitsPurchased = tokenData['units_purchased'] as num?;
      final purchaseDateTimestamp = tokenData['purchase_date'] as Timestamp?;
      final estimatedRemaining = tokenData['estimated_units_remaining_at_log'] as num?;
      
      if (unitsPurchased == null || purchaseDateTimestamp == null) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ Invalid token data: missing required fields');
        }
        return null;
      }
      
      final units = unitsPurchased.toDouble();
      final purchaseDate = purchaseDateTimestamp.toDate();
      final remaining = estimatedRemaining?.toDouble() ?? units;
      
      // SECURITY: Validate units are positive
      if (units <= 0) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ Invalid units: $units');
        }
        return null;
      }
      
      // Validate date is not in the future
      if (purchaseDate.isAfter(DateTime.now())) {
        if (kDebugMode) {
          debugPrint('[DependencyResolver] ❌ Token date is in the future: $purchaseDate');
        }
        return null;
      }
      
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ✅ Token: ${units.toStringAsFixed(1)} units, '
                   'remaining: ${remaining.toStringAsFixed(1)}, '
                   'date: ${purchaseDate.toIso8601String()}');
      }
      
      return {
        'units': units,
        'purchase_date': purchaseDate,
        'estimated_remaining': remaining,
        'token_id': tokenDoc.id,
      };
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ❌ Error reading token: $e');
      }
      return null;
    }
  }

  /// Get user's band supply hours from Location Module
  Future<int?> getBandSupplyHours() async {
    try {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] 🔌 Reading band supply hours from location module...');
      }
      
      return null;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ❌ Error reading band hours: $e');
      }
      return null;
    }
  }

  /// Get user's band classification (A-E)
  Future<String?> getBandClassification() async {
    try {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] 🔌 Reading band classification...');
      }
      
      return null;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DependencyResolver] ❌ Error reading band classification: $e');
      }
      return null;
    }
  }

  /// Validate all dependencies are available
  Future<Map<String, bool>> validateDependencies() async {
    final burnRate = await getDailyBurnRate();
    final estimatorComplete = await isEstimatorCompleted();
    final token = await getLatestToken();
    final bandHours = await getBandSupplyHours();
    
    return {
      'has_burn_rate': burnRate != null,
      'estimator_complete': estimatorComplete,
      'has_token': token != null,
      'has_band_hours': bandHours != null,
    };
  }
}