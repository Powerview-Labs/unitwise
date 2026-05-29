/**
 * Phase 2 Service Extensions
 */

import 'package:flutter/foundation.dart';
import '../models/appliance_model.dart';
import '../models/appliance_estimator_model.dart';
import '../constants/default_appliances.dart';
import '../config/app_config.dart';
import 'appliance_service.dart';
import 'analytics_service.dart';

extension ApplianceServicePhase2 on ApplianceService {
  Future<ApplianceEstimatorModel?> loadEstimator() async {
    try {
      final draft = await loadDraft();
      if (draft != null) {
        if (kDebugMode) {
          debugPrint('✅ Loaded estimator draft: ${draft.appliances.length} appliances');
        }
        return draft;
      }
      if (kDebugMode) {
        debugPrint('ℹ️ No estimator draft found, starting fresh');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading estimator: $e');
      }
      return null;
    }
  }

  Future<List<Appliance>> getDefaultAppliances() async {
    try {
      final defaults = List<Appliance>.from(DefaultAppliances.list);
      if (kDebugMode) {
        debugPrint('✅ Loaded ${defaults.length} default appliances');
      }
      return defaults;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading defaults: $e');
      }
      return [];
    }
  }

  Future<void> saveEstimator(ApplianceEstimatorModel estimator) async {
    try {
      await saveDraft(estimator);
      if (kDebugMode) {
        debugPrint('✅ Estimator saved: ${estimator.appliances.length} appliances');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving estimator: $e');
      }
      rethrow;
    }
  }
}

extension AnalyticsServicePhase2 on AnalyticsService {
  Future<void> trackEvent({
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    if (!AppConfig.enableAnalytics) {
      return;
    }
    if (kDebugMode) {
      debugPrint('📊 Analytics: $event ${properties ?? ""}');
    }
  }
}
