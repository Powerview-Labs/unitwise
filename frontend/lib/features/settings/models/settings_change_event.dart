// 📄 File: lib/features/settings/models/settings_change_event.dart
// Phase 1: Foundation - Change Event Model for Cross-Module Coordination

/// Settings Change Event
/// 
/// Represents a settings modification that may trigger recalculations
/// in dependent modules (Estimator, Dashboard, Budget Planner, etc.)
/// 
/// Used by SettingsCoordinator to orchestrate cross-module updates
/// following the Dependency Map from System Logic documents.
class SettingsChangeEvent {
  /// Type of setting that changed
  final SettingsChangeType type;

  /// Old value (for comparison and rollback if needed)
  final dynamic oldValue;

  /// New value
  final dynamic newValue;

  /// Timestamp of change
  final DateTime timestamp;

  /// User who made the change (for audit logging)
  final String userId;

  /// Whether this change requires immediate UI notification
  final bool requiresUserNotification;

  /// Custom message for user notification (optional)
  final String? notificationMessage;

  SettingsChangeEvent({
    required this.type,
    required this.oldValue,
    required this.newValue,
    required this.userId,
    DateTime? timestamp,
    this.requiresUserNotification = false,
    this.notificationMessage,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Check if this is a high-impact change
  /// High-impact changes trigger extensive recalculations
  bool get isHighImpact {
    return type == SettingsChangeType.disco ||
        type == SettingsChangeType.band;
  }

  /// Check if this is a band change specifically
  bool get isBandChange {
    return type == SettingsChangeType.band;
  }

  /// Get list of modules affected by this change
  /// Based on Settings Dependency Map from core documents
  List<AffectedModule> get affectedModules {
    switch (type) {
      case SettingsChangeType.disco:
      case SettingsChangeType.band:
        // High impact: affects almost everything
        return [
          AffectedModule.locationModule,
          AffectedModule.applianceEstimator,
          AffectedModule.dashboard,
          AffectedModule.budgetPlanner,
          AffectedModule.notifications,
          // Token Logger: Future logs only, NOT past logs
        ];

      case SettingsChangeType.lowUnitThreshold:
        return [
          AffectedModule.dashboard,
          AffectedModule.notifications,
        ];

      case SettingsChangeType.outageMode:
        return [
          AffectedModule.dashboard,
          AffectedModule.virtualBurnEngine,
          AffectedModule.notifications,
        ];

      case SettingsChangeType.meterNumber:
        return [
          AffectedModule.tokenLogger, // Metadata only
        ];

      case SettingsChangeType.theme:
      case SettingsChangeType.language:
        return [
          AffectedModule.uiOnly, // No logic impact
        ];

      case SettingsChangeType.notificationsEnabled:
      case SettingsChangeType.behavioralReminders:
        return [
          AffectedModule.notifications,
        ];
    }
  }

  /// Convert to audit log format
  Map<String, dynamic> toAuditLog() {
    return {
      'type': type.toString(),
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'isHighImpact': isHighImpact,
      'affectedModules': affectedModules.map((m) => m.toString()).toList(),
    };
  }

  @override
  String toString() {
    return 'SettingsChangeEvent(type: $type, old: $oldValue, new: $newValue, timestamp: $timestamp)';
  }
}

/// Types of settings changes
enum SettingsChangeType {
  disco,
  band,
  meterNumber,
  lowUnitThreshold,
  outageMode,
  theme,
  language,
  notificationsEnabled,
  behavioralReminders,
}

/// Modules that can be affected by settings changes
/// Based on Settings Dependency Map
enum AffectedModule {
  locationModule,
  applianceEstimator,
  dashboard,
  budgetPlanner,
  tokenLogger,
  notifications,
  virtualBurnEngine,
  uiOnly, // Visual changes only, no logic
}
