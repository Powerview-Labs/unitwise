import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dashboard_state.dart';
import 'burn_engine.dart';
import 'dependency_resolver.dart';
import 'alert_engine.dart';
import '../../../services/storage_service.dart';

/// Core dashboard business logic service
///
/// RESPONSIBILITY:
/// - Orchestrate all dashboard operations
/// - Manage state persistence (Firestore + local cache)
/// - Trigger burn recalculations
/// - Handle user actions (outage toggle, manual override)
/// - ⭐ NEW: Listen for Token History deletion triggers
///
/// SECURITY:
/// - All state mutations validated
/// - Firestore operations wrapped in try-catch
/// - Local cache as fallback
/// - Never trust client data
///
/// ✅ CRITICAL FIXES APPLIED:
/// 1. ⭐ FIXED: Starting units now detects NEW tokens (not just first init)
/// 2. Outage days: Calculated from elapsed time, not blind increment
/// 3. Caching: Fully enabled with corruption handling
/// 4. Token History deletion recalculation support
class DashboardService {
  final FirebaseFirestore _firestore;
  final StorageService _storage;
  final BurnEngine _burnEngine;
  final DependencyResolver _dependencyResolver;
  final AlertEngine _alertEngine;

  static const String _cacheKey = 'dashboard_state';
  static const String _collectionPath = 'users';
  static const String _dashboardDoc = 'dashboard_state';

  DashboardService({
    FirebaseFirestore? firestore,
    required StorageService storageService,
    BurnEngine? burnEngine,
    DependencyResolver? dependencyResolver,
    AlertEngine? alertEngine,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storageService,
        _burnEngine = burnEngine ?? BurnEngine(),
        _dependencyResolver = dependencyResolver ?? DependencyResolver(),
        _alertEngine = alertEngine ?? AlertEngine();

  /// Initialize dashboard state for a user
  ///
  /// ✅ CRITICAL FIX #3: Cache enabled with fallback
  /// Load order:
  /// 1. Try Firestore
  /// 2. Fallback to local cache (ENABLED)
  /// 3. Create empty state if nothing exists
  Future<DashboardState> initializeDashboard(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════');
        debugPrint('[DashboardService] 🚀 Initializing dashboard for user: $userId');
      }

      // Try to load from Firestore first
      final firestoreState = await _loadFromFirestore(userId);
      if (firestoreState != null) {
        if (kDebugMode) {
          debugPrint('[DashboardService] ✅ Loaded from Firestore');
        }
        // ✅ FIX: Cache it locally
        await _cacheLocally(firestoreState);
        return firestoreState;
      }

      // ✅ CRITICAL FIX #3: Try cache if Firestore fails (offline support)
      final cachedState = await _loadFromCache();
      if (cachedState != null) {
        if (kDebugMode) {
          debugPrint('[DashboardService] ✅ Loaded from cache (offline mode)');
        }
        return cachedState;
      }

      // Create new empty state
      if (kDebugMode) {
        debugPrint('[DashboardService] 🆕 Creating new empty state');
      }
      final emptyState = DashboardState.empty();
      await _saveState(userId, emptyState);

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════');
      }

      return emptyState;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error initializing: $e');
        debugPrint('═══════════════════════════════════════');
      }
      return DashboardState.empty();
    }
  }

  /// Recalculate dashboard state (burn engine trigger)
  ///
  /// ✅ CRITICAL FIX #1: Detects NEW tokens correctly
  ///
  /// This is called when:
  /// - App opens
  /// - App resumes
  /// - User manually refreshes
  /// - Token logged
  /// - Estimator updated
  /// - ⭐ NEW: Token deleted (via Token History)
  Future<DashboardState> recalculateState(
    String userId,
    DashboardState currentState,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════');
        debugPrint('[DashboardService] 🔄 Recalculating dashboard state...');
      }

      // Check if burn engine should run
      if (!_burnEngine.shouldRunBurnEngine(
        manualOverride: currentState.manualOverride,
        outageModeActive: currentState.outageModeActive,
      )) {
        if (kDebugMode) {
          debugPrint('[DashboardService] ⏸️  Burn engine skipped (override/outage active)');
          debugPrint('═══════════════════════════════════════');
        }
        return currentState;
      }

      // Get latest dependencies
      if (kDebugMode) {
        debugPrint('[DashboardService] 📊 Fetching dependencies...');
      }

      final dailyBurn = await _dependencyResolver.getDailyBurnRate();
      final tokenData = await _dependencyResolver.getLatestToken();
      final estimatorComplete = await _dependencyResolver.isEstimatorCompleted();

      if (kDebugMode) {
        debugPrint('[DashboardService]    Daily burn: ${dailyBurn?.toStringAsFixed(1) ?? 'null'}');
        debugPrint('[DashboardService]    Token: ${tokenData != null ? 'available' : 'missing'}');
        debugPrint('[DashboardService]    Estimator: ${estimatorComplete ? 'complete' : 'incomplete'}');
      }

      // Validate dependencies
      if (dailyBurn == null || tokenData == null) {
        if (kDebugMode) {
          debugPrint('[DashboardService] ⚠️  Missing dependencies - cannot calculate burn');
          debugPrint('═══════════════════════════════════════');
        }
        // Update flags but keep current values
        final updatedState = currentState.copyWith(
          hasEstimatorCompleted: estimatorComplete,
          hasTokenLogged: tokenData != null,
        );
        await _saveState(userId, updatedState);
        return updatedState;
      }

      // ✅ CRITICAL FIX #1: Detect if this is a NEW token
      // LOGIC: If token date is newer than last logged date, it's a new purchase
      final tokenDate = tokenData['purchase_date'] as DateTime;
      final isNewToken = currentState.lastTokenLog == null || 
                         tokenDate.isAfter(currentState.lastTokenLog!);

      // ✅ CRITICAL FIX #1B: NEW TOKENS ARE ADDITIVE, NOT REPLACEMENT
      // When you buy new electricity, it ADDS to your existing balance
      // Example: 100 units remaining + 200 units purchased = 300 total
      double startingUnits;
      
      if (currentState.manualOverride) {
        // Manual override always takes precedence
        startingUnits = currentState.manualUnits!;
      } else if (isNewToken) {
        // NEW TOKEN: Add to existing balance (ADDITIVE)
        final existingBalance = currentState.estimatedUnits;
        final newUnits = tokenData['units'] as double;
        startingUnits = existingBalance + newUnits;
        
        if (kDebugMode) {
          debugPrint('[DashboardService] 🔢 NEW TOKEN DETECTED - ADDING TO BALANCE');
          debugPrint('[DashboardService]    Existing balance: ${existingBalance.toStringAsFixed(1)} units');
          debugPrint('[DashboardService]    New units purchased: ${newUnits.toStringAsFixed(1)} units');
          debugPrint('[DashboardService]    Total balance: ${startingUnits.toStringAsFixed(1)} units');
          debugPrint('[DashboardService]    Token date: $tokenDate');
          debugPrint('[DashboardService]    Last logged: ${currentState.lastTokenLog}');
        }
      } else {
        // NO NEW TOKEN: Use rolling balance (burn engine continues from last state)
        startingUnits = currentState.estimatedUnits;
      }

      if (kDebugMode && !isNewToken) {
        debugPrint('[DashboardService] 🔢 Starting units: ${startingUnits.toStringAsFixed(1)}');
        debugPrint('[DashboardService]    Source: ${currentState.manualOverride ? "MANUAL OVERRIDE" : "CURRENT STATE (rolling balance)"}');
      }

      // Run burn engine
      if (kDebugMode) {
        debugPrint('[DashboardService] 🔥 Running burn engine...');
      }

      final burnResult = _burnEngine.calculateBurn(
        startingUnits: startingUnits,  // ✅ CORRECT!
        dailyBurnRate: dailyBurn,
        lastCalculatedAt: currentState.lastCalculatedAt,
        outageDays: currentState.outageDays,
      );

      if (kDebugMode) {
        debugPrint('[DashboardService] 📊 Burn result: ${burnResult.estimatedUnits.toStringAsFixed(1)} units');
      }

      // Generate alerts
      final alerts = _alertEngine.generateAlerts(
        estimatedUnits: burnResult.estimatedUnits,
        daysRemaining: burnResult.daysRemaining,
        dailyBurnRate: dailyBurn,
      );

      // Create new state
      final newState = currentState.copyWith(
        estimatedUnits: burnResult.estimatedUnits,
        dailyBurnRate: dailyBurn,
        daysRemaining: burnResult.daysRemaining,
        lastCalculatedAt: burnResult.calculatedAt,
        lastTokenLog: tokenDate,  // ✅ Update to latest token date
        alerts: alerts,
        hasTokenLogged: true,
        hasEstimatorCompleted: estimatorComplete,
      );

      // Save to Firestore and cache
      await _saveState(userId, newState);

      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ State recalculated and saved');
        debugPrint('═══════════════════════════════════════');
      }

      return newState;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error recalculating state: $e');
        debugPrint('═══════════════════════════════════════');
      }
      // Return current state on error
      return currentState;
    }
  }

  /// ⭐ NEW: Recalculate balance from all tokens
  /// Called when Token History deletes a token
  ///
  /// LOGIC:
  /// 1. Fetch all tokens from Firestore
  /// 2. Sum total units purchased
  /// 3. Calculate units consumed since last token
  /// 4. Update balance = total purchased - consumed
  Future<DashboardState> recalculateBalanceFromTokens(
    String userId,
    DashboardState currentState,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════');
        debugPrint('[DashboardService] 🔄 Recalculating balance from tokens...');
      }

      // 1. Fetch all tokens from Firestore (use 'tokens' collection for Token History)
      final tokensSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .orderBy('purchase_date')
          .get();

      if (tokensSnapshot.docs.isEmpty) {
        if (kDebugMode) {
          debugPrint('[DashboardService] ⚠️  No tokens found - resetting balance to 0');
        }
        
        final newState = currentState.copyWith(
          estimatedUnits: 0.0,
          lastTokenLog: null,
          hasTokenLogged: false,
        );
        
        await _saveState(userId, newState);
        return newState;
      }

      // 2. Calculate total units purchased
      double totalUnitsPurchased = 0.0;
      DateTime? lastTokenDate;

      for (final doc in tokensSnapshot.docs) {
        final data = doc.data();
        final units = (data['units_purchased'] ?? data['estimated_units']) as num;
        totalUnitsPurchased += units.toDouble();

        final purchaseDate = (data['purchase_date'] as Timestamp).toDate();
        if (lastTokenDate == null || purchaseDate.isAfter(lastTokenDate)) {
          lastTokenDate = purchaseDate;
        }
      }

      if (kDebugMode) {
        debugPrint('[DashboardService]    Total purchased: ${totalUnitsPurchased.toStringAsFixed(1)} units');
        debugPrint('[DashboardService]    Last token: $lastTokenDate');
      }

      // 3. Calculate units consumed since last token
      double unitsConsumed = 0.0;
      
      if (lastTokenDate != null && currentState.dailyBurnRate != null) {
        final daysSinceLastToken = DateTime.now().difference(lastTokenDate).inDays;
        unitsConsumed = currentState.dailyBurnRate! * daysSinceLastToken;
        
        if (kDebugMode) {
          debugPrint('[DashboardService]    Days since last token: $daysSinceLastToken');
          debugPrint('[DashboardService]    Units consumed: ${unitsConsumed.toStringAsFixed(1)}');
        }
      }

      // 4. Calculate current balance
      final currentBalance = (totalUnitsPurchased - unitsConsumed).clamp(0.0, double.infinity);

      if (kDebugMode) {
        debugPrint('[DashboardService]    New balance: ${currentBalance.toStringAsFixed(1)} units');
      }

      // 5. Update dashboard state
      final newState = currentState.copyWith(
        estimatedUnits: currentBalance,
        lastTokenLog: lastTokenDate,
        hasTokenLogged: true,
        lastCalculatedAt: DateTime.now(),
      );

      await _saveState(userId, newState);

      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ Balance recalculated from tokens');
        debugPrint('═══════════════════════════════════════');
      }

      return newState;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error recalculating from tokens: $e');
        debugPrint('═══════════════════════════════════════');
      }
      return currentState;
    }
  }

  /// Toggle outage mode
  ///
  /// ✅ CRITICAL FIX #2: Calculates outage days from elapsed time
  ///
  /// When ON: Start tracking outage_started_at
  /// When OFF: Calculate elapsed days and add to total
  Future<DashboardState> toggleOutageMode(
    String userId,
    DashboardState currentState,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('[DashboardService] 🌙 Toggling outage mode...');
      }

      final newOutageState = !currentState.outageModeActive;
      
      DateTime? newOutageStartedAt;
      int newOutageDays = currentState.outageDays;

      if (newOutageState) {
        // Turning ON - start tracking
        newOutageStartedAt = DateTime.now();
        if (kDebugMode) {
          debugPrint('[DashboardService] ✅ Outage started at: $newOutageStartedAt');
        }
      } else {
        // Turning OFF - calculate elapsed days
        if (currentState.outageStartedAt != null) {
          final elapsedDays = DateTime.now()
              .difference(currentState.outageStartedAt!)
              .inDays;
          
          // Add elapsed days to total (minimum 1 day even if < 24 hours)
          newOutageDays = currentState.outageDays + (elapsedDays > 0 ? elapsedDays : 1);
          
          if (kDebugMode) {
            debugPrint('[DashboardService] ✅ Outage ended');
            debugPrint('[DashboardService]    Elapsed: $elapsedDays days');
            debugPrint('[DashboardService]    Total outage days: $newOutageDays');
          }
        }
        newOutageStartedAt = null;
      }

      final newState = currentState.copyWith(
        outageModeActive: newOutageState,
        outageDays: newOutageDays,
        outageStartedAt: newOutageStartedAt,
      );

      await _saveState(userId, newState);

      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ Outage mode: ${newOutageState ? 'ON' : 'OFF'}');
      }

      return newState;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error toggling outage: $e');
      }
      return currentState;
    }
  }

  /// Apply manual unit override
  ///
  /// SECURITY: Validates manual input before applying
  Future<DashboardState> applyManualOverride(
    String userId,
    DashboardState currentState,
    double manualUnits,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('[DashboardService] ✏️  Applying manual override: ${manualUnits.toStringAsFixed(1)} units');
      }

      // SECURITY: Validate manual input
      if (manualUnits < 0 || manualUnits.isNaN || manualUnits.isInfinite) {
        throw ArgumentError('Invalid manual units: $manualUnits');
      }

      if (manualUnits > 10000) {
        throw ArgumentError('Manual units too high: $manualUnits');
      }

      final newState = currentState.copyWith(
        manualOverride: true,
        manualUnits: manualUnits,
        manualOverrideTimestamp: DateTime.now(),
        estimatedUnits: manualUnits, // Override current estimate
      );

      await _saveState(userId, newState);

      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ Manual override applied');
      }

      return newState;

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error applying manual override: $e');
      }
      rethrow;
    }
  }

  /// Disable manual override
  ///
  /// After disabling, triggers recalculation to resume auto-tracking
  Future<DashboardState> disableManualOverride(
    String userId,
    DashboardState currentState,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('[DashboardService] ↩️  Disabling manual override...');
      }

      final newState = currentState.copyWith(
        manualOverride: false,
        manualUnits: null,
        manualOverrideTimestamp: null,
      );

      await _saveState(userId, newState);

      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ Manual override disabled');
        debugPrint('[DashboardService] 🔄 Triggering recalculation...');
      }

      // Trigger recalculation now that override is off
      return await recalculateState(userId, newState);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error disabling override: $e');
      }
      return currentState;
    }
  }

  // ===== PRIVATE HELPERS =====

  /// Save state to Firestore AND cache locally
  /// ✅ CRITICAL FIX #3: Caching enabled
  Future<void> _saveState(String userId, DashboardState state) async {
    try {
      // Save to Firestore
      await _firestore
          .collection(_collectionPath)
          .doc(userId)
          .collection('dashboard')
          .doc(_dashboardDoc)
          .set(state.toFirestore(), SetOptions(merge: true));

      // ✅ FIX: Cache locally
      await _cacheLocally(state);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error saving state: $e');
      }
      rethrow;
    }
  }

  /// Load state from Firestore
  Future<DashboardState?> _loadFromFirestore(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionPath)
          .doc(userId)
          .collection('dashboard')
          .doc(_dashboardDoc)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return DashboardState.fromFirestore(doc.data()!);

    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardService] ❌ Error loading from Firestore: $e');
      }
      return null;
    }
  }

  /// ✅ CRITICAL FIX #3: Cache state locally (with corruption handling)
  Future<void> _cacheLocally(DashboardState state) async {
    try {
      final json = state.toJson();
      await _storage.saveDashboardState(json);
      
      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ Cached locally');
      }
    } catch (e) {
      // Non-critical: Cache failure shouldn't break the app
      if (kDebugMode) {
        debugPrint('[DashboardService] ⚠️  Cache write failed: $e');
      }
    }
  }

  /// ✅ CRITICAL FIX #3: Load from cache (with corruption fallback)
  Future<DashboardState?> _loadFromCache() async {
    try {
      final json = await _storage.loadDashboardState();
      if (json == null) return null;
      
      final state = DashboardState.fromJson(json);
      
      if (kDebugMode) {
        debugPrint('[DashboardService] ✅ Loaded from cache');
      }
      
      return state;
    } catch (e) {
      // Cache corrupted - delete and return null
      if (kDebugMode) {
        debugPrint('[DashboardService] ⚠️  Cache corrupted, clearing: $e');
      }
      await _storage.clearDashboardCache();
      return null;
    }
  }
}