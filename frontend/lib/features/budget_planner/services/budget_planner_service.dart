import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/budget_plan.dart';
import '../utils/budget_constants.dart';
import '../utils/budget_input_validator.dart';

/// Main service for Budget Planner module
/// WHY: Orchestrates all CRUD operations for budget plans
/// SECURITY: All Firestore operations are user-scoped
class BudgetPlannerService {
  final FirebaseFirestore _firestore;

  BudgetPlannerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ==================== DEPENDENCY CHECKING ====================

  /// Check if all required dependencies are met
  /// WHY: Budget Planner requires Appliance Estimator completion
  /// 
  /// Returns: DependencyCheckResult with missing dependencies list
  Future<DependencyCheckResult> checkDependencies({
    required String userId,
  }) async {
    try {
      // Fetch user profile
      final profileDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!profileDoc.exists) {
        if (kDebugMode) {
          debugPrint('User profile not found');
        }
        return DependencyCheckResult(
          allMet: false,
          missingDependencies: ['User Profile'],
        );
      }

      final data = profileDoc.data()!;

      // Check Appliance Estimator completion
      final applianceSetupComplete = 
          data['appliance_setup_completed'] ?? false;
      final burnRate = data['daily_burn_estimate'] as double?;

      // ═══════════════════════════════════════════════════════════
      // CRITICAL FIX: Handle nested disco object
      // ═══════════════════════════════════════════════════════════
      String? disco;
      String? band;
      
      final discoData = data['disco'];
      if (discoData is Map<String, dynamic>) {
        // Nested object format: {name: "Ikeja Electric", band: "A", ...}
        disco = discoData['name'] as String?;
        band = discoData['band'] as String?;
        
        if (kDebugMode) {
          debugPrint('🔍 [BudgetPlannerService] Extracted from nested disco:');
          debugPrint('   - name: $disco');
          debugPrint('   - band: $band');
        }
      } else if (discoData is String) {
        // String format (legacy or manual)
        disco = discoData;
        band = data['band'] as String?;
        
        if (kDebugMode) {
          debugPrint('🔍 [BudgetPlannerService] Using string disco: $disco');
          debugPrint('   - band from separate field: $band');
        }
      }

      // Check Location Setup
      // IMPORTANT: Infer locationSet from disco existence, not from a separate field
      // WHY: Location Setup may set 'disco' without setting 'location_set' flag
      final locationSet = (disco != null && disco.isNotEmpty && 
                          band != null && band.isNotEmpty);
      
      if (kDebugMode) {
        debugPrint('🔍 [BudgetPlannerService] Location check:');
        debugPrint('   - disco: $disco');
        debugPrint('   - band: $band');
        debugPrint('   - locationSet: $locationSet');
      }

      return BudgetInputValidator.checkDependencies(
        applianceSetupComplete: applianceSetupComplete,
        locationSet: locationSet,
        burnRate: burnRate,
        disco: disco,
        band: band,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking dependencies: $e');
      }
      
      // SECURITY: Fail closed - assume dependencies not met
      return DependencyCheckResult(
        allMet: false,
        missingDependencies: ['Unable to verify setup'],
      );
    }
  }

  // ==================== CREATE & SAVE PLAN ====================

  /// Save a budget plan to Firestore
  /// Path: /users/{uid}/budget_plans/{planId}
  /// 
  /// SECURITY: User can only write to their own plans collection
  /// WHY: Plans are user-owned snapshots for reference
  Future<String> savePlan({
    required String userId,
    required BudgetPlan plan,
  }) async {
    try {
      // Generate document reference (auto-ID)
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(BudgetConstants.budgetPlansCollection)
          .doc();

      // Create plan with generated ID
      final planWithId = plan.copyWith(id: docRef.id);

      // Save to Firestore
      await docRef.set(planWithId.toMap());

      if (kDebugMode) {
        debugPrint('Saved budget plan: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error saving plan: $e');
      }
      throw BudgetPlannerException('Failed to save plan: ${e.toString()}');
    }
  }

  // ==================== FETCH PLANS ====================

  /// Fetch all saved plans for user
  /// 
  /// SECURITY: User can only read their own plans
  /// Returns: List of plans sorted by creation date (newest first)
  Future<List<BudgetPlan>> fetchSavedPlans({
    required String userId,
    int? limit,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection(BudgetConstants.budgetPlansCollection)
          .orderBy('created_at', descending: true);

      // Apply limit if specified
      if (limit != null) {
        query = query.limit(limit);
      } else {
        // Default limit to prevent performance issues
        query = query.limit(BudgetConstants.maxSavedPlansToDisplay);
      }

      final snapshot = await query.get();

      final plans = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BudgetPlan.fromMap(data, doc.id);
      }).toList();

      if (kDebugMode) {
        debugPrint('Fetched ${plans.length} saved plans');
      }

      return plans;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching plans: $e');
      }
      // SECURITY: Return empty list instead of throwing
      // WHY: Non-critical failure, allow UI to continue
      return [];
    }
  }

  /// Fetch a single plan by ID
  /// 
  /// SECURITY: User can only read their own plans
  Future<BudgetPlan?> fetchPlanById({
    required String userId,
    required String planId,
  }) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(BudgetConstants.budgetPlansCollection)
          .doc(planId);

      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        if (kDebugMode) {
          debugPrint('Plan not found: $planId');
        }
        return null;
      }

      return BudgetPlan.fromMap(snapshot.data()!, snapshot.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching plan: $e');
      }
      return null;
    }
  }

  // ==================== DELETE PLAN ====================

  /// Delete a saved plan
  /// 
  /// SECURITY: User can only delete their own plans (enforced by rules)
  Future<void> deletePlan({
    required String userId,
    required String planId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection(BudgetConstants.budgetPlansCollection)
          .doc(planId)
          .delete();

      if (kDebugMode) {
        debugPrint('Deleted plan: $planId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting plan: $e');
      }
      throw BudgetPlannerException('Failed to delete plan: ${e.toString()}');
    }
  }

  // ==================== STREAM PLANS (OPTIONAL) ====================

  /// Stream saved plans for real-time updates
  /// WHY: Useful if plans can be modified from multiple devices
  /// 
  /// SECURITY: User-scoped stream
  Stream<List<BudgetPlan>> streamSavedPlans({
    required String userId,
    int? limit,
  }) {
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection(BudgetConstants.budgetPlansCollection)
        .orderBy('created_at', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    } else {
      query = query.limit(BudgetConstants.maxSavedPlansToDisplay);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BudgetPlan.fromMap(data, doc.id);
      }).toList();
    });
  }

  // ==================== HELPER METHODS ====================

  /// Get count of saved plans (for UI badges)
  Future<int> getSavedPlansCount({required String userId}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(BudgetConstants.budgetPlansCollection)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting plans count: $e');
      }
      return 0;
    }
  }

  /// Check if user has any saved plans
  Future<bool> hasSavedPlans({required String userId}) async {
    final count = await getSavedPlansCount(userId: userId);
    return count > 0;
  }
}

// ==================== EXCEPTION CLASS ====================

/// Exception thrown by BudgetPlannerService
class BudgetPlannerException implements Exception {
  final String message;
  BudgetPlannerException(this.message);

  @override
  String toString() => 'BudgetPlannerException: $message';
}