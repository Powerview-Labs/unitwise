/**
 * Appliance Estimator Controller - FIXED
 * 
 * FIXES APPLIED:
 * 3. ✅ Added restoreAppliance method for undo functionality
 */

import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../models/appliance_model.dart';
import '../../models/appliance_estimator_model.dart';
import '../../models/appliance_estimator_state.dart';
import '../../models/power_saver_tip_model.dart';
import '../../services/appliance_service.dart';
import '../../services/analytics_service.dart';
import '../../services/service_extensions.dart';
import '../../utils/appliance_calculator.dart';
import '../../constants/estimator/estimator_constants.dart';
import '../../constants/estimator/estimator_strings.dart';
import '../../utils/estimator/estimator_extensions.dart';
import '../../config/app_config.dart';

class ApplianceEstimatorController extends ChangeNotifier {
  final ApplianceService _applianceService;
  final AnalyticsService _analyticsService;

  ApplianceEstimatorState _state = ApplianceEstimatorState.initial();
  DateTime? _lastSaved;
  Timer? _autoSaveTimer;
  bool _isDisposed = false;

  ApplianceEstimatorController({
    required ApplianceService applianceService,
    required AnalyticsService analyticsService,
  })  : _applianceService = applianceService,
        _analyticsService = analyticsService;

  Future<void> initialize() async {
    if (_isDisposed) return;

    try {
      _updateState(_state.copyWith(isLoading: true, error: null));

      final estimatorModel = await _applianceService.loadEstimator();

      if (_isDisposed) return;

      if (estimatorModel != null) {
        _updateState(_state.copyWith(
          appliances: estimatorModel.appliances,
          totalDailyBurn: estimatorModel.dailyBurnEstimate,
          tips: estimatorModel.tips,
          isLoading: false,
        ));
      } else {
        _updateState(_state.copyWith(
          appliances: [],
          totalDailyBurn: 0.0,
          tips: [],
          isLoading: false,
        ));
      }

      _lastSaved = DateTime.now();

      _trackEvent('estimator_initialized', {
        'appliance_count': _state.appliances.length,
      });
    } catch (e) {
      if (_isDisposed) return;

      final errorMessage = AppConfig.isTestMode
          ? 'Failed to load: $e'
          : EstimatorStrings.errorLoadFailed;

      _updateState(_state.copyWith(
        isLoading: false,
        error: errorMessage,
      ));

      if (kDebugMode) {
        debugPrint('❌ Estimator init error: $e');
      }
    }
  }

  List<Appliance> get appliances => _state.appliances;
  double get totalDailyBurn => _state.totalDailyBurn;
  List<PowerSaverTip> get tips => _state.tips;
  bool get isLoading => _state.isLoading;
  String? get error => _state.error;
  bool get hasError => _state.error != null;
  bool get isEmpty => _state.appliances.isEmpty;
  bool get hasHighConsumption => _state.appliances.any((a) => a.hasHighDailyUnits);
  bool get canAddAppliance => !_state.appliances.isAtMaxCapacity;

  bool get hasUnsavedChanges {
    if (_lastSaved == null) return _state.appliances.isNotEmpty;
    return _lastSaved!.isOlderThanDebounce();
  }

  Future<void> addAppliance(Appliance appliance) async {
    if (_isDisposed) return;

    try {
      final validationError = _validateAppliance(appliance);
      if (validationError != null) {
        _updateState(_state.copyWith(error: validationError));
        return;
      }

      if (!canAddAppliance) {
        _updateState(_state.copyWith(error: EstimatorStrings.errorMaxAppliances));
        return;
      }

      final updatedAppliances = List<Appliance>.from(_state.appliances)
        ..add(appliance);

      await _updateAppliancesAndRecalculate(updatedAppliances);

      _trackEvent('appliance_added', {
        'name': appliance.name,
        'wattage': appliance.wattage,
        'daily_units': appliance.dailyUnits,
      });
    } catch (e) {
      _handleError('add appliance', e);
    }
  }

  Future<void> updateAppliance(Appliance updatedAppliance) async {
    if (_isDisposed) return;

    try {
      final validationError = _validateAppliance(updatedAppliance);
      if (validationError != null) {
        _updateState(_state.copyWith(error: validationError));
        return;
      }

      final updatedAppliances = _state.appliances.map((a) {
        return a.id == updatedAppliance.id ? updatedAppliance : a;
      }).toList();

      await _updateAppliancesAndRecalculate(updatedAppliances);

      _trackEvent('appliance_updated', {
        'id': updatedAppliance.id,
      });
    } catch (e) {
      _handleError('update appliance', e);
    }
  }

  Future<void> deleteAppliance(String applianceId) async {
    if (_isDisposed) return;

    try {
      final updatedAppliances = _state.appliances
          .where((a) => a.id != applianceId)
          .toList();

      await _updateAppliancesAndRecalculate(updatedAppliances);

      _trackEvent('appliance_deleted', {'id': applianceId});
    } catch (e) {
      _handleError('delete appliance', e);
    }
  }

  // ✅ FIX #3: Add restoreAppliance method for undo functionality
  /// Restore a deleted appliance (for undo functionality)
  /// Used when user clicks UNDO on delete snackbar
  void restoreAppliance(Appliance appliance) {
    if (_isDisposed) return;

    try {
      // Add appliance back to list
      final updatedAppliances = List<Appliance>.from(_state.appliances)
        ..add(appliance);

      // Keep list sorted by name for consistency
      updatedAppliances.sort((a, b) => a.name.compareTo(b.name));

      // Recalculate and update state
      _updateAppliancesAndRecalculate(updatedAppliances);

      _trackEvent('appliance_restored', {
        'name': appliance.name,
        'id': appliance.id,
      });

      if (kDebugMode) {
        debugPrint('✅ Restored appliance: ${appliance.name}');
      }
    } catch (e) {
      _handleError('restore appliance', e);
    }
  }

  Future<void> clearAll() async {
    if (_isDisposed) return;

    try {
      await _updateAppliancesAndRecalculate([]);
      _trackEvent('appliances_cleared', {});
    } catch (e) {
      _handleError('clear appliances', e);
    }
  }

  Future<void> loadDefaults() async {
    if (_isDisposed) return;

    try {
      _updateState(_state.copyWith(isLoading: true, error: null));

      final defaults = await _applianceService.getDefaultAppliances();

      if (_isDisposed) return;

      await _updateAppliancesAndRecalculate(defaults);

      _trackEvent('defaults_loaded', {
        'count': defaults.length,
      });
    } catch (e) {
      _handleError('load defaults', e);
    }
  }

  Future<void> _updateAppliancesAndRecalculate(
    List<Appliance> appliances,
  ) async {
    if (_isDisposed) return;

    final totalBurn = ApplianceCalculator.calculateTotalDailyBurn(appliances);

    // FIXED: Use named parameters for generatePowerSaverTips
    final tips = ApplianceCalculator.generatePowerSaverTips(
      appliances: appliances,
      unitRate: 0.0, // TODO: Get actual rate from user profile in Phase 3
    );

    _updateState(_state.copyWith(
      appliances: appliances,
      totalDailyBurn: totalBurn,
      tips: tips,
      isLoading: false,
      error: null,
    ));

    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(EstimatorConstants.autoSaveDebounce, () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    if (_isDisposed) return;

    try {
      final estimatorModel = ApplianceEstimatorModel(
        appliances: _state.appliances,
        dailyBurnEstimate: _state.totalDailyBurn,
        bandAdjusted: false,
        applianceSetupCompleted: _state.appliances.isNotEmpty,
        lastUpdated: DateTime.now(),
        tips: _state.tips,
        isDraft: true,
      );

      await _applianceService.saveDraft(estimatorModel);

      _lastSaved = DateTime.now();

      if (kDebugMode) {
        debugPrint('✅ Auto-saved estimator (${_state.appliances.length} appliances)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Auto-save failed: $e');
      }
    }
  }

  Future<bool> saveEstimator() async {
    if (_isDisposed) return false;

    try {
      _updateState(_state.copyWith(isLoading: true, error: null));

      final estimatorModel = ApplianceEstimatorModel(
        appliances: _state.appliances,
        dailyBurnEstimate: _state.totalDailyBurn,
        bandAdjusted: false,
        applianceSetupCompleted: _state.appliances.isNotEmpty,
        lastUpdated: DateTime.now(),
        tips: _state.tips,
        isDraft: false,
      );

      await _applianceService.saveEstimator(estimatorModel);

      _lastSaved = DateTime.now();

      _updateState(_state.copyWith(isLoading: false));

      _trackEvent('estimator_saved', {
        'appliance_count': _state.appliances.length,
        'total_burn': _state.totalDailyBurn,
      });

      return true;
    } catch (e) {
      _handleError('save estimator', e);
      return false;
    }
  }

  String? _validateAppliance(Appliance appliance) {
    if (appliance.name.trim().isEmpty) {
      return EstimatorStrings.validationNameRequired;
    }

    if (appliance.name.length > EstimatorConstants.maxNameLength) {
      return EstimatorStrings.validationNameTooLong;
    }

    if (!appliance.name.isValidApplianceName()) {
      return EstimatorStrings.validationNameInvalid;
    }

    if (!appliance.wattage.isValidWattage()) {
      if (appliance.wattage < EstimatorConstants.minWattage) {
        return EstimatorStrings.validationWattageTooLow;
      } else {
        return EstimatorStrings.validationWattageTooHigh;
      }
    }

    if (!appliance.hoursPerDay.isValidHours()) {
      if (appliance.hoursPerDay < EstimatorConstants.minHours) {
        return EstimatorStrings.validationHoursTooLow;
      } else {
        return EstimatorStrings.validationHoursTooHigh;
      }
    }

    if (!appliance.quantity.isValidQuantity()) {
      if (appliance.quantity < EstimatorConstants.minQuantity) {
        return EstimatorStrings.validationQuantityTooLow;
      } else {
        return EstimatorStrings.validationQuantityTooHigh;
      }
    }

    return null;
  }

  void _handleError(String operation, dynamic error) {
    if (_isDisposed) return;

    final errorMessage = AppConfig.isTestMode
        ? 'Failed to $operation: $error'
        : EstimatorStrings.errorGeneric;

    _updateState(_state.copyWith(
      isLoading: false,
      error: errorMessage,
    ));

    if (kDebugMode) {
      debugPrint('❌ Error during $operation: $error');
    }
  }

  void clearError() {
    if (_isDisposed) return;
    _updateState(_state.copyWith(error: null));
  }

  void _updateState(ApplianceEstimatorState newState) {
    if (_isDisposed) return;
    _state = newState;
    notifyListeners();
  }

  void _trackEvent(String event, Map<String, dynamic> properties) {
    _analyticsService.trackEvent(
      event: event,
      properties: properties,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
