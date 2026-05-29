// 📄 File: lib/features/settings/providers/settings_provider.dart
// Phase 1: Foundation - Settings State Management
// Uses Provider for reactive state management

import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../models/notification_preferences.dart';
import '../services/settings_service.dart';

/// Settings Provider
/// 
/// Manages settings state and provides reactive updates to UI.
/// Uses ChangeNotifier for simple Provider pattern.
/// 
/// FEATURES:
/// - Real-time settings sync from Firestore
/// - Loading states for async operations
/// - Error handling with user-friendly messages
/// - Optimistic UI updates with rollback on failure
class SettingsProvider with ChangeNotifier {
  final SettingsService _settingsService;

  UserSettings? _settings;
  NotificationPreferences? _notificationPreferences;

  bool _isLoading = false;
  String? _errorMessage;

  SettingsProvider({
    required SettingsService settingsService,
  }) : _settingsService = settingsService;

  // ========== GETTERS ==========

  UserSettings? get settings => _settings;
  NotificationPreferences? get notificationPreferences =>
      _notificationPreferences;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasSettings => _settings != null;
  bool get hasError => _errorMessage != null;

  // ========== INITIALIZATION ==========

  /// Load settings from Firestore
  /// Called when user opens Settings screen
  /// 
  /// ⭐ PRODUCTION-READY: Automatically creates settings if they don't exist
  /// This handles both new users and existing users who signed up before Settings module
  Future<void> loadSettings() async {
    _setLoading(true);
    _clearError();

    try {
      // Try to load existing settings
      _settings = await _settingsService.getCurrentSettings();
      
      // TODO: Load notification preferences from Firestore
      // For now, use defaults
      _notificationPreferences = NotificationPreferences();

      if (kDebugMode) {
        print('✅ Settings loaded successfully');
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Settings load failed: $e');
      }

      // Check if error is "not found" (settings don't exist)
      if (e.toString().contains('permission-denied') || 
          e.toString().contains('not-found') ||
          _settings == null) {
        
        if (kDebugMode) {
          print('🔧 Settings not found, attempting auto-initialization...');
        }

        // Attempt to auto-create settings from user's location data
        final initialized = await _autoInitializeSettings();
        
        if (initialized) {
          if (kDebugMode) {
            print('✅ Settings auto-initialized successfully');
          }
          // Try loading again
          try {
            _settings = await _settingsService.getCurrentSettings();
            _notificationPreferences = NotificationPreferences();
            notifyListeners();
            return; // Success!
          } catch (e2) {
            if (kDebugMode) {
              print('❌ Failed to load after initialization: $e2');
            }
          }
        }
      }

      // If all else fails, show error
      _setError('Failed to load settings. Please try again.');
      if (kDebugMode) {
        print('❌ SettingsProvider.loadSettings error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// ⭐ PRODUCTION-READY: Auto-initialize settings from user's location data
  /// This is called automatically when settings don't exist
  Future<bool> _autoInitializeSettings() async {
    try {
      if (kDebugMode) {
        print('🔧 Auto-initializing settings...');
      }

      // Use the service's auto-initialization method
      await _settingsService.autoInitializeFromUserData();
      
      if (kDebugMode) {
        print('✅ Settings auto-initialized via service');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Auto-initialization failed: $e');
      }
      return false;
    }
  }

  // ========== UPDATE METHODS ==========

  /// Update DisCo
  /// Uses optimistic update with rollback on failure
  Future<void> updateDisco(String newDisco) async {
    if (_settings == null) return;

    final oldSettings = _settings!;
    
    // Optimistic update
    _settings = _settings!.copyWith(
      disco: newDisco,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _settingsService.updateDisco(newDisco);
    } catch (e) {
      // Rollback on failure
      _settings = oldSettings;
      _setError('Failed to update DisCo. ${e.toString()}');
      notifyListeners();
    }
  }

  /// Update Band
  /// 
  /// CRITICAL: Shows warning before proceeding (handled in UI)
  /// This method assumes user has already confirmed the change
  Future<void> updateBand(String newBand) async {
    if (_settings == null) return;

    final oldSettings = _settings!;
    final newSupplyHours = _getBandSupplyHours(newBand);

    // Optimistic update
    _settings = _settings!.copyWith(
      band: newBand,
      bandSupplyHours: newSupplyHours,
      bandChangedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _settingsService.updateBand(newBand);
      
      // Show success message
      _setError(null);
    } catch (e) {
      // Rollback on failure
      _settings = oldSettings;
      _setError('Failed to update Band. ${e.toString()}');
      notifyListeners();
    }
  }

  /// Update Meter Number
  Future<void> updateMeterNumber(String newMeterNumber) async {
    if (_settings == null) return;

    final oldSettings = _settings!;

    _settings = _settings!.copyWith(
      meterNumber: newMeterNumber,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _settingsService.updateMeterNumber(newMeterNumber);
    } catch (e) {
      _settings = oldSettings;
      _setError('Failed to update meter number. ${e.toString()}');
      notifyListeners();
    }
  }

  /// Update Low Unit Threshold
  Future<void> updateLowUnitThreshold(double threshold) async {
    if (_settings == null) return;

    final oldSettings = _settings!;

    _settings = _settings!.copyWith(
      lowUnitThreshold: threshold,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _settingsService.updateLowUnitThreshold(threshold);
    } catch (e) {
      _settings = oldSettings;
      _setError('Failed to update threshold. ${e.toString()}');
      notifyListeners();
    }
  }

  /// Toggle Outage Mode
  Future<void> toggleOutageMode(bool enabled) async {
    if (_settings == null) return;

    final oldSettings = _settings!;

    _settings = _settings!.copyWith(
      outageMode: enabled,
      outageModeEnabledAt: enabled ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _settingsService.toggleOutageMode(enabled);
    } catch (e) {
      _settings = oldSettings;
      _setError('Failed to toggle outage mode. ${e.toString()}');
      notifyListeners();
    }
  }

  /// Update Theme
  Future<void> updateTheme(String theme) async {
    if (_settings == null) return;

    final oldSettings = _settings!;

    _settings = _settings!.copyWith(
      theme: theme,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      await _settingsService.updateTheme(theme);
    } catch (e) {
      _settings = oldSettings;
      _setError('Failed to update theme. ${e.toString()}');
      notifyListeners();
    }
  }

  /// Toggle notification preference
  Future<void> toggleNotification(String key, bool value) async {
    if (_settings == null) return;

    try {
      await _settingsService.updateNotificationPreference(key, value);
      
      // Update local state based on key
      switch (key) {
        case 'lowUnitAlertsEnabled':
          _settings = _settings!.copyWith(
            lowUnitAlertsEnabled: value,
            updatedAt: DateTime.now(),
          );
          break;
        case 'criticalAlertsEnabled':
          _settings = _settings!.copyWith(
            criticalAlertsEnabled: value,
            updatedAt: DateTime.now(),
          );
          break;
        case 'notificationsEnabled':
          _settings = _settings!.copyWith(
            notificationsEnabled: value,
            updatedAt: DateTime.now(),
          );
          break;
        case 'behavioralRemindersEnabled':
          _settings = _settings!.copyWith(
            behavioralRemindersEnabled: value,
            updatedAt: DateTime.now(),
          );
          break;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update notification preference. ${e.toString()}');
    }
  }

  // ========== HELPER METHODS ==========

  int _getBandSupplyHours(String band) {
    const bandHours = {
      'A': 20,
      'B': 16,
      'C': 12,
      'D': 8,
      'E': 4,
    };
    return bandHours[band.toUpperCase()] ?? 12;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    if (error != null) {
      notifyListeners();
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}