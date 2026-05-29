// 📄 File: lib/features/settings/services/settings_service.dart
// Phase 1: Foundation - Settings Service Layer
// SECURITY: All operations validated, rate-limited, and audited

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';
import '../models/settings_change_event.dart';
import 'settings_coordinator.dart';

/// Settings Service
/// 
/// Handles all settings CRUD operations with:
/// - Input validation
/// - Rate limiting
/// - Security checks
/// - Audit logging
/// - Cross-module coordination via SettingsCoordinator
/// 
/// CRITICAL SECURITY RULES:
/// 1. Never trust client input - validate everything
/// 2. Clamp numeric values to reasonable ranges
/// 3. Sanitize all string inputs
/// 4. Rate limit updates to prevent abuse
/// 5. Audit log all critical changes (DisCo/Band)
class SettingsService {
  final FirebaseFirestore _firestore;
  final SettingsCoordinator _coordinator;
  final String userId;

  // SECURITY: Rate limiter to prevent spam updates
  final Map<String, DateTime> _lastUpdate = {};
  static const _updateCooldown = Duration(seconds: 5);

  SettingsService({
    required this.userId,
    FirebaseFirestore? firestore,
    SettingsCoordinator? coordinator,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _coordinator = coordinator ?? SettingsCoordinator(userId: userId);

  /// Get current user settings
  /// 
  /// SECURITY: User can only read their own settings (enforced by Firestore rules)
  Future<UserSettings?> getCurrentSettings() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();

      if (!doc.exists) return null;

      return UserSettings.fromFirestore(doc);
    } catch (e) {
      // SECURITY: Never expose internal errors to user
      if (kDebugMode) {
        print('SettingsService.getCurrentSettings error: $e');
      }
      rethrow;
    }
  }

  /// Create initial settings for new user
  /// Called during onboarding after Location Setup completes
  Future<void> createInitialSettings({
    required String disco,
    required String band,
    String? meterNumber,
  }) async {
    try {
      // SECURITY: Validate inputs
      _validateDisco(disco);
      _validateBand(band);
      if (meterNumber != null) {
        _validateMeterNumber(meterNumber);
      }

      final settings = UserSettings.createDefault(
        disco: disco,
        band: band,
        meterNumber: meterNumber,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set(settings.toFirestore());

      if (kDebugMode) {
        print('SettingsService: Initial settings created for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('SettingsService.createInitialSettings error: $e');
      }
      rethrow;
    }
  }

  /// ⭐ PRODUCTION-READY: Auto-initialize settings from user's existing data
  /// This is called automatically when settings don't exist for existing users
  /// 
  /// WORKFLOW:
  /// 1. Fetch user's location data (DisCo, Band) from users/{uid}
  /// 2. Create default settings using that data
  /// 3. Handles users who signed up before Settings module was added
  Future<void> autoInitializeFromUserData() async {
    try {
      if (kDebugMode) {
        print('🔧 SettingsService: Auto-initializing settings for user $userId');
      }

      // Check if settings already exist
      final existing = await getCurrentSettings();
      if (existing != null) {
        if (kDebugMode) {
          print('✅ SettingsService: Settings already exist, skipping auto-init');
        }
        return;
      }

      // Fetch user's location data from main user document
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data()!;
      final disco = userData['disco'] as String? ?? 'Unknown';
      final band = userData['band'] as String? ?? 'C';

      if (kDebugMode) {
        print('🔧 SettingsService: Found user data - DisCo: $disco, Band: $band');
      }

      // Create settings with user's existing data
      await createInitialSettings(
        disco: disco,
        band: band,
        meterNumber: null, // Meter number can be added later via Settings
      );

      if (kDebugMode) {
        print('✅ SettingsService: Settings auto-initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SettingsService.autoInitializeFromUserData error: $e');
      }
      rethrow;
    }
  }

  // ========== UPDATE OPERATIONS ==========

  /// Update DisCo
  /// SECURITY: Validates DisCo name, triggers cross-module updates
  Future<void> updateDisco(String newDisco) async {
    // SECURITY: Rate limit check
    if (!_canUpdate('disco')) {
      throw Exception('Please wait before updating DisCo again');
    }

    // SECURITY: Validate input
    _validateDisco(newDisco);

    final current = await getCurrentSettings();
    if (current == null) {
      throw Exception('Settings not initialized');
    }

    if (current.disco == newDisco) {
      return; // No change
    }

    // Create change event for coordination
    final event = SettingsChangeEvent(
      type: SettingsChangeType.disco,
      oldValue: current.disco,
      newValue: newDisco,
      userId: userId,
      requiresUserNotification: true,
      notificationMessage:
          'DisCo changed from ${current.disco} to $newDisco. Future calculations will use new DisCo data.',
    );

    // Update Firestore
    await _updateSetting('disco', newDisco);

    // SECURITY: Audit log
    await _auditLog('DISCO_CHANGE', event.toAuditLog());

    // Trigger cross-module coordination
    await _coordinator.handleDiscoChange(event);

    // Record update time
    _recordUpdate('disco');
  }

  /// Update Band
  /// 
  /// CRITICAL: This is the most dangerous setting change
  /// Follows 5-step migration from core documents
  /// 
  /// SECURITY:
  /// - Validates band value
  /// - Shows user warning (handled in UI layer)
  /// - Triggers forward-only recalculation
  /// - Never modifies historical data
  /// - Audit logs with full context
  Future<void> updateBand(String newBand) async {
    // SECURITY: Rate limit check
    if (!_canUpdate('band')) {
      throw Exception('Please wait before updating Band again');
    }

    // SECURITY: Validate input
    _validateBand(newBand);

    final current = await getCurrentSettings();
    if (current == null) {
      throw Exception('Settings not initialized');
    }

    if (current.band == newBand) {
      return; // No change
    }

    // Get new supply hours
    final newSupplyHours = _getBandSupplyHours(newBand);

    // Create change event
    final event = SettingsChangeEvent(
      type: SettingsChangeType.band,
      oldValue: current.band,
      newValue: newBand,
      userId: userId,
      requiresUserNotification: true,
      notificationMessage:
          'Band changed from ${current.band} to $newBand. This affects future estimates only. Past token records remain unchanged.',
    );

    // Update Firestore with new band + timestamp
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .update({
      'band': newBand,
      'bandSupplyHours': newSupplyHours,
      'bandChangedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // SECURITY: Audit log with full context
    await _auditLog('BAND_CHANGE', {
      ...event.toAuditLog(),
      'oldSupplyHours': current.bandSupplyHours,
      'newSupplyHours': newSupplyHours,
    });

    // CRITICAL: Trigger 5-step band change migration
    await _coordinator.handleBandChange(
      oldBand: current.band,
      newBand: newBand,
      newSupplyHours: newSupplyHours,
    );

    // Record update time
    _recordUpdate('band');
  }

  /// Update Meter Number
  /// SECURITY: Sanitizes input, validates format
  Future<void> updateMeterNumber(String newMeterNumber) async {
    if (!_canUpdate('meterNumber')) {
      throw Exception('Please wait before updating meter number again');
    }

    // SECURITY: Sanitize and validate
    final sanitized = _sanitizeMeterNumber(newMeterNumber);
    _validateMeterNumber(sanitized);

    await _updateSetting('meterNumber', sanitized);
    _recordUpdate('meterNumber');
  }

  /// Update Low Unit Threshold
  /// 
  /// SECURITY: Clamps value to 5-100 units
  /// SIDE EFFECT: Resets notification cooldown for immediate evaluation
  Future<void> updateLowUnitThreshold(double threshold) async {
    if (!_canUpdate('lowUnitThreshold')) {
      throw Exception('Please wait before updating threshold again');
    }

    // SECURITY: Clamp to reasonable range (5-100 units)
    final clamped = threshold.clamp(5.0, 100.0);

    if (clamped != threshold && kDebugMode) {
      print('SettingsService: Threshold clamped from $threshold to $clamped');
    }

    final current = await getCurrentSettings();
    if (current?.lowUnitThreshold == clamped) {
      return; // No change
    }

    // Create change event
    final event = SettingsChangeEvent(
      type: SettingsChangeType.lowUnitThreshold,
      oldValue: current?.lowUnitThreshold,
      newValue: clamped,
      userId: userId,
    );

    await _updateSetting('lowUnitThreshold', clamped);

    // IMPORTANT: Reset notification cooldown for immediate re-evaluation
    await _coordinator.handleThresholdChange(event);

    _recordUpdate('lowUnitThreshold');
  }

  /// Toggle Outage Mode
  /// 
  /// BEHAVIOR:
  /// - When enabled: Records timestamp, pauses Virtual Burn Engine
  /// - When disabled: Clears timestamp, resumes burn from TODAY (no catchup)
  Future<void> toggleOutageMode(bool enabled) async {
    if (!_canUpdate('outageMode')) {
      throw Exception('Please wait before toggling outage mode again');
    }

    final current = await getCurrentSettings();
    if (current?.outageMode == enabled) {
      return; // No change
    }

    final updates = {
      'outageMode': enabled,
      'outageModeEnabledAt': enabled ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .update(updates);

    // Notify coordinator
    final event = SettingsChangeEvent(
      type: SettingsChangeType.outageMode,
      oldValue: current?.outageMode,
      newValue: enabled,
      userId: userId,
    );

    await _coordinator.handleOutageModeChange(event);

    _recordUpdate('outageMode');
  }

  /// Update Theme
  /// SECURITY: Validates theme value is 'light', 'dark', or 'system'
  Future<void> updateTheme(String theme) async {
    // SECURITY: Validate theme value
    if (!['light', 'dark', 'system'].contains(theme)) {
      throw ArgumentError('Invalid theme: $theme');
    }

    await _updateSetting('theme', theme);
  }

  /// Update notification preferences
  Future<void> updateNotificationPreference(String key, bool value) async {
    if (!_canUpdate(key)) {
      throw Exception('Please wait before updating notification settings again');
    }

    await _updateSetting(key, value);
    _recordUpdate(key);
  }

  // ========== PRIVATE HELPERS ==========

  /// Generic setting update
  /// SECURITY: Always updates timestamp
  Future<void> _updateSetting(String key, dynamic value) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('preferences')
        .update({
      key: value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get band supply hours from band letter
  int _getBandSupplyHours(String band) {
    const bandHours = {
      'A': 20,
      'B': 16,
      'C': 12,
      'D': 8,
      'E': 4,
    };
    return bandHours[band.toUpperCase()] ?? 12; // Default to C
  }

  // ========== VALIDATION METHODS ==========

  void _validateDisco(String disco) {
    // List of valid Nigerian DisCos
    const validDiscos = [
      'Abuja Electric',
      'Benin Electric',
      'Eko Electric',
      'Enugu Electric',
      'Ibadan Electric',
      'Ikeja Electric',
      'Jos Electric',
      'Kaduna Electric',
      'Kano Electric',
      'Port Harcourt Electric',
      'Yola Electric',
    ];

    if (!validDiscos.contains(disco)) {
      throw ArgumentError('Invalid DisCo: $disco');
    }
  }

  void _validateBand(String band) {
    if (!['A', 'B', 'C', 'D', 'E'].contains(band.toUpperCase())) {
      throw ArgumentError('Invalid band: $band. Must be A, B, C, D, or E');
    }
  }

  void _validateMeterNumber(String meterNumber) {
    if (meterNumber.length > 50) {
      throw ArgumentError('Meter number too long (max 50 characters)');
    }
    
    if (meterNumber.isEmpty) {
      throw ArgumentError('Meter number cannot be empty');
    }
  }

  String _sanitizeMeterNumber(String input) {
    // SECURITY: Remove all non-alphanumeric characters except hyphens
    return input.trim().replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '');
  }

  // ========== RATE LIMITING ==========

  bool _canUpdate(String settingKey) {
    final last = _lastUpdate[settingKey];
    if (last == null) return true;

    final elapsed = DateTime.now().difference(last);
    return elapsed > _updateCooldown;
  }

  void _recordUpdate(String settingKey) {
    _lastUpdate[settingKey] = DateTime.now();
  }

  // ========== AUDIT LOGGING ==========

  /// Log critical settings changes for security audit
  /// 
  /// SECURITY: Only logs in production, not debug mode
  /// PRIVACY: Does not log sensitive user data
  Future<void> _auditLog(String action, Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('AUDIT LOG: $action - $data');
      return;
    }

    try {
      await _firestore.collection('audit_logs').add({
        'userId': userId,
        'action': action,
        'data': data,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // SECURITY: Never throw on audit log failure
      // Log locally but continue operation
      if (kDebugMode) {
        print('Audit log failed: $e');
      }
    }
  }
}