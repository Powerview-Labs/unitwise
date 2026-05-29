import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/dashboard_state.dart';
import '../services/dashboard_service.dart';

/// Dashboard state provider
///
/// RESPONSIBILITY:
/// - Manage dashboard state in memory
/// - Notify listeners on state changes
/// - Provide UI-friendly methods for actions
/// - Handle loading and error states
/// - Listen for token logs and auto-refresh
/// - ⭐ NEW: Listen for Token History deletion triggers
///
/// SECURITY:
/// - All state changes go through this provider
/// - No direct state manipulation from UI
/// - Error states properly managed
///
/// ✅ BUG #1 FIX: Better error messages for manual override
/// ⭐ NEW: Token Logger integration
/// ⭐ NEW: Token History deletion integration
class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService;
  final String _userId;

  DashboardState _state = DashboardState.empty();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Token log listener
  StreamSubscription<QuerySnapshot>? _tokenLogSubscription;
  
  // ⭐ NEW: Token History deletion listener
  StreamSubscription<DocumentSnapshot>? _recalcTriggerSubscription;

  DashboardProvider({
    required DashboardService dashboardService,
    required String userId,
  })  : _dashboardService = dashboardService,
        _userId = userId {
    // Start listening for token logs
    _startTokenLogListener();
    
    // ⭐ NEW: Start listening for Token History deletion triggers
    _startRecalculationTriggerListener();
  }

  // ===== GETTERS =====

  /// Current dashboard state
  DashboardState get state => _state;

  /// Loading indicator
  bool get isLoading => _isLoading;

  /// Error message (null if no error)
  String? get errorMessage => _errorMessage;

  /// User readiness state (convenience getter)
  UserReadinessState get userState => _state.userState;

  /// Unit color state (convenience getter)
  UnitColorState get unitColorState => _state.unitColorState;

  /// Can show forecasts (convenience getter)
  bool get canShowForecasts => _state.canShowForecasts;

  // ===== PUBLIC METHODS =====

  /// Initialize dashboard
  /// Called when screen first loads
  Future<void> initialize() async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] 🚀 Initializing...');
      }

      _state = await _dashboardService.initializeDashboard(_userId);

      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✅ Initialized: ${_state.userState}');
      }

    } catch (e) {
      _setError('Failed to load dashboard');
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Init error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh dashboard (trigger burn recalculation)
  /// Called when:
  /// - App resumes
  /// - User pulls to refresh
  /// - User manually taps refresh button
  /// - New token is logged
  Future<void> refresh() async {
    // Don't show loading spinner for refresh (use existing state)
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] 🔄 Refreshing...');
      }

      _state = await _dashboardService.recalculateState(_userId, _state);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✅ Refreshed: ${_state.estimatedUnits.toStringAsFixed(1)} units');
      }

    } catch (e) {
      _setError('Failed to refresh dashboard');
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Refresh error: $e');
      }
    }
  }

  /// ⭐ NEW: Recalculate balance from tokens
  /// Called when Token History deletes a token
  Future<void> recalculateBalanceFromTokens() async {
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] 🔄 Recalculating from tokens...');
      }

      _state = await _dashboardService.recalculateBalanceFromTokens(_userId, _state);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✅ Balance recalculated: ${_state.estimatedUnits.toStringAsFixed(1)} units');
      }

    } catch (e) {
      _setError('Failed to recalculate balance');
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Recalculation error: $e');
      }
    }
  }

  /// Toggle outage mode
  /// User action: Taps "No light right now?" switch
  Future<void> toggleOutage() async {
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] 🌙 Toggling outage...');
      }

      _state = await _dashboardService.toggleOutageMode(_userId, _state);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✅ Outage mode: ${_state.outageModeActive}');
      }

    } catch (e) {
      _setError('Failed to toggle outage mode');
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Toggle outage error: $e');
      }
    }
  }

  /// Apply manual unit override
  /// User action: Enters manual unit value
  ///
  /// SECURITY: Validation happens in service layer
  ///
  /// ✅ BUG #1 FIX: Better error messages - show specific validation errors
  Future<void> applyManualOverride(double units) async {
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✏️  Applying manual override: ${units.toStringAsFixed(1)}');
      }

      _state = await _dashboardService.applyManualOverride(_userId, _state, units);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✅ Manual override applied');
      }

    } catch (e) {
      // ✅ FIX: Show specific error message instead of generic one
      if (e is ArgumentError) {
        final errorMsg = e.message?.toString() ?? 'Invalid value';
        _setError(errorMsg);
        if (kDebugMode) {
          debugPrint('[DashboardProvider] ❌ Validation error: $errorMsg');
        }
      } else {
        _setError('Failed to apply override. Please try again.');
        if (kDebugMode) {
          debugPrint('[DashboardProvider] ❌ Manual override error: $e');
        }
      }
      rethrow; // Let UI handle validation errors
    }
  }

  /// Disable manual override
  /// User action: Taps "Disable" button
  Future<void> disableManualOverride() async {
    _clearError();

    try {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ↩️  Disabling manual override...');
      }

      _state = await _dashboardService.disableManualOverride(_userId, _state);
      notifyListeners();

      if (kDebugMode) {
        debugPrint('[DashboardProvider] ✅ Manual override disabled');
      }

    } catch (e) {
      _setError('Failed to disable override');
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Disable override error: $e');
      }
    }
  }

  /// Force recalculation (for testing or manual triggers)
  Future<void> forceRecalculate() async {
    await refresh();
  }

  // ===== PRIVATE HELPERS =====

  /// Start listening for token log changes
  void _startTokenLogListener() {
    try {
      _tokenLogSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('token_logs')
          .orderBy('created_at', descending: true)
          .limit(1)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.docs.isNotEmpty) {
                if (kDebugMode) {
                  debugPrint('[DashboardProvider] 🎯 New token log detected, refreshing...');
                }
                // New token logged, refresh dashboard
                refresh();
              }
            },
            onError: (error) {
              if (kDebugMode) {
                debugPrint('[DashboardProvider] ❌ Token log listener error: $error');
              }
            },
          );
      
      if (kDebugMode) {
        debugPrint('[DashboardProvider] 👂 Token log listener started');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Failed to start token log listener: $e');
      }
    }
  }

  /// ⭐ NEW: Start listening for Token History deletion triggers
  /// When Token History deletes a token, it sets a flag in dashboard/state
  /// We listen for that flag and trigger recalculation
  void _startRecalculationTriggerListener() {
    try {
      _recalcTriggerSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('dashboard')
          .doc('state')
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                final data = snapshot.data();
                if (data?['needs_recalculation'] == true) {
                  if (kDebugMode) {
                    debugPrint('[DashboardProvider] 🔄 Recalculation trigger detected');
                  }
                  
                  // Trigger recalculation
                  recalculateBalanceFromTokens();
                  
                  // Clear the flag
                  snapshot.reference.update({
                    'needs_recalculation': false,
                    'last_recalculation': FieldValue.serverTimestamp(),
                  }).catchError((error) {
                    if (kDebugMode) {
                      debugPrint('[DashboardProvider] ⚠️  Failed to clear recalc flag: $error');
                    }
                  });
                }
              }
            },
            onError: (error) {
              if (kDebugMode) {
                debugPrint('[DashboardProvider] ❌ Recalc trigger listener error: $error');
              }
            },
          );
      
      if (kDebugMode) {
        debugPrint('[DashboardProvider] 👂 Recalculation trigger listener started');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DashboardProvider] ❌ Failed to start recalc trigger listener: $e');
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('[DashboardProvider] 🗑️  Disposing...');
    }
    
    // Cancel token log listener
    _tokenLogSubscription?.cancel();
    
    // ⭐ NEW: Cancel recalculation trigger listener
    _recalcTriggerSubscription?.cancel();
    
    super.dispose();
  }
}