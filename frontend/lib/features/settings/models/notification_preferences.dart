// 📄 File: lib/features/settings/models/notification_preferences.dart
// Phase 4: Notification Preferences Engine

/// Notification Preferences Model
/// 
/// Manages user notification settings with smart cooldown logic
/// to prevent spam while ensuring critical alerts always fire.
/// 
/// PRINCIPLES (from core documents):
/// - Passive: Never blocks UI
/// - Non-blocking: Always fails silently
/// - User-controlled: Respects preferences
/// - No spam: Enforces cooldowns
class NotificationPreferences {
  // ========== CRITICAL EVENTS (Cannot be silenced) ==========
  /// These events ALWAYS trigger notifications regardless of user preferences
  static const List<String> criticalEvents = [
    'ESTIMATOR_MISSING',
    'TOKEN_LOGGER_LOCKED',
    'DATA_CORRUPTION',
  ];

  // ========== USER-CONFIGURABLE ALERTS ==========
  final bool lowUnitsEnabled;
  final bool budgetExpiringEnabled;
  final bool bandChangeRemindersEnabled;

  // ========== BEHAVIORAL REMINDERS (Optional) ==========
  final bool outageModeRemindersEnabled;
  final bool estimatorUpdateRemindersEnabled;

  // ========== COOLDOWN TRACKING ==========
  /// Map of event type -> last notification timestamp
  /// Used to prevent spam by enforcing minimum time between notifications
  final Map<String, DateTime> lastNotificationSent;

  NotificationPreferences({
    this.lowUnitsEnabled = true,
    this.budgetExpiringEnabled = true,
    this.bandChangeRemindersEnabled = true,
    this.outageModeRemindersEnabled = true,
    this.estimatorUpdateRemindersEnabled = true,
    Map<String, DateTime>? lastNotificationSent,
  }) : lastNotificationSent = lastNotificationSent ?? {};

  // ========== COOLDOWN LOGIC ==========

  /// Check if a notification can be sent for a given event type
  /// 
  /// SECURITY: Never throws, always returns bool
  /// LOGIC: Critical events bypass all checks
  bool canSendNotification(String eventType) {
    // Critical events always send
    if (criticalEvents.contains(eventType)) return true;

    // Check user preference
    if (!_isEventEnabled(eventType)) return false;

    // Check cooldown
    final cooldown = _getCooldownDuration(eventType);
    final lastSent = lastNotificationSent[eventType];

    if (lastSent != null) {
      final elapsed = DateTime.now().difference(lastSent);
      if (elapsed < cooldown) return false; // Still in cooldown
    }

    return true;
  }

  /// Record that a notification was sent
  /// Updates cooldown tracker
  void recordNotificationSent(String eventType) {
    lastNotificationSent[eventType] = DateTime.now();
  }

  /// Reset cooldown for a specific event type
  /// Used when threshold changes or user explicitly requests notification
  void resetCooldown(String eventType) {
    lastNotificationSent.remove(eventType);
  }

  // ========== PRIVATE HELPERS ==========

  /// Check if event type is enabled by user preferences
  bool _isEventEnabled(String eventType) {
    switch (eventType) {
      case 'LOW_UNITS':
        return lowUnitsEnabled;
      case 'BUDGET_EXPIRING':
        return budgetExpiringEnabled;
      case 'BAND_CHANGE_REMINDER':
        return bandChangeRemindersEnabled;
      case 'NO_LIGHT_REMINDER':
        return outageModeRemindersEnabled;
      case 'ESTIMATOR_UPDATE_REMINDER':
        return estimatorUpdateRemindersEnabled;
      default:
        return false; // Unknown events disabled by default
    }
  }

  /// Get cooldown duration for event type
  /// 
  /// Based on notification cooldown table from core documents:
  /// - LOW_UNITS: 24h
  /// - NO_LIGHT_REMINDER: 12h
  /// - ESTIMATOR_MISSING: Once per session (24h)
  Duration _getCooldownDuration(String eventType) {
    const cooldowns = {
      'LOW_UNITS': Duration(hours: 24),
      'CRITICAL': Duration(hours: 24),
      'NO_LIGHT_REMINDER': Duration(hours: 12),
      'ESTIMATOR_MISSING': Duration(days: 1),
      'ESTIMATOR_UPDATE_REMINDER': Duration(days: 7),
      'BUDGET_EXPIRING': Duration(hours: 24),
      'BAND_CHANGE_REMINDER': Duration(days: 1),
    };

    return cooldowns[eventType] ?? const Duration(hours: 24); // Default 24h
  }

  // ========== FIRESTORE CONVERSION ==========

  Map<String, dynamic> toFirestore() {
    return {
      'lowUnitsEnabled': lowUnitsEnabled,
      'budgetExpiringEnabled': budgetExpiringEnabled,
      'bandChangeRemindersEnabled': bandChangeRemindersEnabled,
      'outageModeRemindersEnabled': outageModeRemindersEnabled,
      'estimatorUpdateRemindersEnabled': estimatorUpdateRemindersEnabled,
      'lastNotificationSent': lastNotificationSent.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  factory NotificationPreferences.fromFirestore(Map<String, dynamic> data) {
    final lastSentData = data['lastNotificationSent'] as Map<String, dynamic>?;
    final lastSentMap = <String, DateTime>{};

    if (lastSentData != null) {
      lastSentData.forEach((key, value) {
        if (value is String) {
          lastSentMap[key] = DateTime.parse(value);
        }
      });
    }

    return NotificationPreferences(
      lowUnitsEnabled: data['lowUnitsEnabled'] as bool? ?? true,
      budgetExpiringEnabled: data['budgetExpiringEnabled'] as bool? ?? true,
      bandChangeRemindersEnabled:
          data['bandChangeRemindersEnabled'] as bool? ?? true,
      outageModeRemindersEnabled:
          data['outageModeRemindersEnabled'] as bool? ?? true,
      estimatorUpdateRemindersEnabled:
          data['estimatorUpdateRemindersEnabled'] as bool? ?? true,
      lastNotificationSent: lastSentMap,
    );
  }

  NotificationPreferences copyWith({
    bool? lowUnitsEnabled,
    bool? budgetExpiringEnabled,
    bool? bandChangeRemindersEnabled,
    bool? outageModeRemindersEnabled,
    bool? estimatorUpdateRemindersEnabled,
    Map<String, DateTime>? lastNotificationSent,
  }) {
    return NotificationPreferences(
      lowUnitsEnabled: lowUnitsEnabled ?? this.lowUnitsEnabled,
      budgetExpiringEnabled:
          budgetExpiringEnabled ?? this.budgetExpiringEnabled,
      bandChangeRemindersEnabled:
          bandChangeRemindersEnabled ?? this.bandChangeRemindersEnabled,
      outageModeRemindersEnabled:
          outageModeRemindersEnabled ?? this.outageModeRemindersEnabled,
      estimatorUpdateRemindersEnabled: estimatorUpdateRemindersEnabled ??
          this.estimatorUpdateRemindersEnabled,
      lastNotificationSent: lastNotificationSent ?? this.lastNotificationSent,
    );
  }
}
