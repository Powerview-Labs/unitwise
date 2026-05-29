/**
 * Appliance Estimator Controller - COMPLETE WITH SMART TIPS
 *
 * ✅ FIXED VERSION - Smart, appliance-specific recommendations
 * ✅ INTEGRATED WITH USER SERVICE - Saves daily_burn_estimate to Firestore
 * ✅ BUG FIX: Validation added — all appliances must have hoursPerDay > 0
 *             AND quantity > 0 before saving. Friendly, plain-English error
 *             messages shown — no technical jargon.
 */

import 'package:flutter/foundation.dart';
import '../../models/appliance_model.dart';
import '../../models/appliance_estimator_state.dart';
import '../../models/power_saver_tip_model.dart';
import '../../data/starter_appliances_data.dart';
import '../../data/full_appliance_catalog.dart';
import '../../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApplianceEstimatorController extends ChangeNotifier {
  ApplianceEstimatorState _state = ApplianceEstimatorState.initial();
  bool _hasUnsavedChanges = false;

  final UserService _userService = UserService();

  ApplianceEstimatorController();

  // ══════════════════════════════════════════════════════════
  // GETTERS
  // ══════════════════════════════════════════════════════════

  ApplianceEstimatorState get state => _state;
  List<Appliance> get appliances => _state.appliances;
  List<PowerSaverTip> get tips => _state.tips;
  bool get isLoading => _state.isLoading;
  bool get isEmpty => _state.appliances.isEmpty;
  bool get isNotEmpty => _state.appliances.isNotEmpty;
  bool get hasError => _state.error != null;
  int get applianceCount => _state.appliances.length;

  double get totalDailyUnits => _state.totalDailyBurn;
  double get totalDailyBurn => _state.totalDailyBurn;
  String? get errorMessage => _state.error;
  String? get error => _state.error;

  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get canAddAppliance => _state.appliances.length < 50;

  List<Appliance> getActiveAppliances() {
    return _state.appliances.where((appliance) {
      return appliance.hoursPerDay > 0 || appliance.quantity > 0;
    }).toList();
  }

  int get activeApplianceCount => getActiveAppliances().length;
  bool get hasConfiguredAppliances => getActiveAppliances().isNotEmpty;

  // ══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════

  Future<void> initialize() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      _state = _state.copyWith(isLoading: false, error: null);
      _hasUnsavedChanges = false;
      notifyListeners();

      if (kDebugMode) print('[Controller] Initialized');
    } catch (e) {
      _setError('Something went wrong while loading. Please restart the screen.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // LOAD DEFAULTS
  // ══════════════════════════════════════════════════════════

  Future<void> loadDefaults() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      final starters = StarterAppliancesData.getStarterAppliances();
      final totalBurn = _calculateConsumption(starters);
      final newTips = _generateTips(starters);

      _state = _state.copyWith(
        appliances: starters,
        totalDailyBurn: totalBurn,
        tips: newTips,
        isLoading: false,
        error: null,
      );

      _hasUnsavedChanges = true;
      notifyListeners();

      if (kDebugMode) {
        print('[Controller] Loaded ${starters.length} starter appliances');
        print('[Controller] Active appliances: $activeApplianceCount');
      }
    } catch (e) {
      _setError('Could not load default appliances. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // CATALOG ACCESS
  // ══════════════════════════════════════════════════════════

  List<Appliance> getCatalog() => FullApplianceCatalog.getCatalog();
  List<Appliance> searchCatalog(String query) => FullApplianceCatalog.search(query);
  List<Appliance> getCatalogByCategory(String category) => FullApplianceCatalog.getByCategory(category);
  List<String> getCategories() => FullApplianceCatalog.getCategories();

  // ══════════════════════════════════════════════════════════
  // ADD APPLIANCE
  // ══════════════════════════════════════════════════════════

  void addAppliance(Appliance appliance) {
    try {
      final exists = _state.appliances.any((a) => a.id == appliance.id);
      if (exists) throw Exception('Appliance already added');

      final newAppliances = [..._state.appliances, appliance];
      newAppliances.sort((a, b) => a.name.compareTo(b.name));

      final totalBurn = _calculateConsumption(newAppliances);
      final newTips = _generateTips(newAppliances);

      _state = _state.copyWith(
        appliances: newAppliances,
        totalDailyBurn: totalBurn,
        tips: newTips,
      );

      _hasUnsavedChanges = true;
      notifyListeners();

      if (kDebugMode) print('[Controller] Added: ${appliance.name}');
    } catch (e) {
      _setError('Could not add this appliance. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // UPDATE APPLIANCE
  // ══════════════════════════════════════════════════════════

  void updateAppliance(Appliance updatedAppliance) {
    try {
      final index = _state.appliances.indexWhere((a) => a.id == updatedAppliance.id);
      if (index == -1) throw Exception('Appliance not found');

      final newAppliances = [..._state.appliances];
      newAppliances[index] = updatedAppliance;

      final totalBurn = _calculateConsumption(newAppliances);
      final newTips = _generateTips(newAppliances);

      _state = _state.copyWith(
        appliances: newAppliances,
        totalDailyBurn: totalBurn,
        tips: newTips,
      );

      _hasUnsavedChanges = true;
      notifyListeners();

      if (kDebugMode) print('[Controller] Updated: ${updatedAppliance.name}');
    } catch (e) {
      _setError('Could not update this appliance. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // DELETE APPLIANCE
  // ══════════════════════════════════════════════════════════

  void deleteAppliance(String applianceId) {
    try {
      final index = _state.appliances.indexWhere((a) => a.id == applianceId);
      if (index == -1) throw Exception('Appliance not found');

      final removed = _state.appliances[index];
      final newAppliances = [..._state.appliances];
      newAppliances.removeAt(index);

      final totalBurn = _calculateConsumption(newAppliances);
      final newTips = _generateTips(newAppliances);

      _state = _state.copyWith(
        appliances: newAppliances,
        totalDailyBurn: totalBurn,
        tips: newTips,
      );

      _hasUnsavedChanges = true;
      notifyListeners();

      if (kDebugMode) print('[Controller] Deleted: ${removed.name}');
    } catch (e) {
      _setError('Could not remove this appliance. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // RESTORE APPLIANCE
  // ══════════════════════════════════════════════════════════

  void restoreAppliance(Appliance appliance) {
    try {
      final newAppliances = [..._state.appliances, appliance];
      newAppliances.sort((a, b) => a.name.compareTo(b.name));

      final totalBurn = _calculateConsumption(newAppliances);
      final newTips = _generateTips(newAppliances);

      _state = _state.copyWith(
        appliances: newAppliances,
        totalDailyBurn: totalBurn,
        tips: newTips,
      );

      _hasUnsavedChanges = true;
      notifyListeners();
    } catch (e) {
      _setError('Could not restore this appliance. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════
  // CLEAR ALL
  // ══════════════════════════════════════════════════════════

  Future<void> clearAll() async {
    _state = ApplianceEstimatorState.initial();
    _hasUnsavedChanges = true;
    notifyListeners();

    if (kDebugMode) print('[Controller] Cleared all appliances');
  }

  // ══════════════════════════════════════════════════════════
  // ✅ VALIDATION — FRIENDLY MESSAGES
  // ══════════════════════════════════════════════════════════

  /// Checks all appliances are fully configured before saving.
  /// Returns null if everything is fine, or a plain-English message if not.
  String? validateBeforeSave() {
    if (_state.appliances.isEmpty) {
      return 'Add at least one appliance to get started.';
    }

    final incomplete = _state.appliances.where((a) {
      return a.hoursPerDay <= 0 || a.quantity <= 0;
    }).toList();

    if (incomplete.isNotEmpty) {
      if (incomplete.length == 1) {
        return 'Please set the hours and quantity for '
            '"${incomplete.first.name}" before saving.';
      } else {
        return '${incomplete.length} appliances still need hours and quantity '
            'filled in. Tap each one to complete it, or delete it if you don\'t need it.';
      }
    }

    return null;
  }

  // ══════════════════════════════════════════════════════════
  // SAVE
  // ══════════════════════════════════════════════════════════

  Future<bool> saveEstimator() async {
    return await saveAppliances();
  }

  Future<bool> saveAppliances() async {
    try {
      // ✅ Validate first — stop here with a friendly message if something is wrong
      final validationError = validateBeforeSave();
      if (validationError != null) {
        _setError(validationError);
        return false;
      }

      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final activeAppliances = getActiveAppliances();

      if (kDebugMode) {
        print('[Controller] ═══════════════════════════════════════');
        print('[Controller] SAVE OPERATION');
        print('[Controller] Total appliances: ${_state.appliances.length}');
        print('[Controller] Active appliances: ${activeAppliances.length}');
        print('[Controller] ═══════════════════════════════════════');
      }

      await Future.delayed(const Duration(milliseconds: 500));

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final saved = await _userService.saveDailyBurnEstimate(
          dailyBurnEstimate: _state.totalDailyBurn,
          applianceCount: activeAppliances.length,
        );

        if (!saved) throw Exception('Profile update failed');

        if (kDebugMode) print('[Controller] ✅ Daily burn estimate saved');
      }

      _state = _state.copyWith(isLoading: false, error: null);
      _hasUnsavedChanges = false;
      notifyListeners();

      if (kDebugMode) {
        print('[Controller] ✅ Saved ${activeAppliances.length} appliances');
        print('[Controller] ✅ Daily burn: ${_state.totalDailyBurn} units');
      }

      return true;
    } catch (e) {
      _setError(
        'Your appliances could not be saved. '
        'Please check your connection and try again.',
      );
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // ERROR HANDLING
  // ══════════════════════════════════════════════════════════

  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _state = _state.copyWith(isLoading: false, error: errorMsg);
    notifyListeners();

    if (kDebugMode) print('[Controller] ❌ Error: $errorMsg');
  }

  // ══════════════════════════════════════════════════════════
  // CALCULATIONS
  // ══════════════════════════════════════════════════════════

  double _calculateConsumption(List<Appliance> applianceList) {
    final activeApps = applianceList.where((a) {
      return a.hoursPerDay > 0 || a.quantity > 0;
    }).toList();

    return activeApps.fold(0.0, (sum, appliance) => sum + appliance.dailyUnits);
  }

  List<PowerSaverTip> _generateTips(List<Appliance> applianceList) {
    final newTips = <PowerSaverTip>[];

    final activeApps = applianceList.where((a) {
      return a.hoursPerDay > 0 || a.quantity > 0;
    }).toList();

    for (final appliance in activeApps) {
      if (appliance.isHighConsumption) {
        final tip = _createTipForAppliance(appliance);
        if (tip != null) newTips.add(tip);
      }
    }

    return newTips;
  }

  // ══════════════════════════════════════════════════════════
  // SMART TIP GENERATION
  // ══════════════════════════════════════════════════════════

  PowerSaverTip? _createTipForAppliance(Appliance appliance) {
    if (appliance.hoursPerDay <= 0 && appliance.quantity <= 0) return null;
    if (appliance.hoursPerDay <= 1) return null;

    final currentHours = appliance.hoursPerDay.round();
    final currentUnits = appliance.dailyUnits;

    int suggestedHours = currentHours;
    String recommendation = '';

    final name = appliance.name.toLowerCase();

    if (name.contains('ac') || name.contains('air con')) {
      recommendation = 'Set timer for 6-8 hours at night only. Use fan during the day.';
      suggestedHours = 8;
    } else if (name.contains('fridge') || name.contains('refrigerator')) {
      recommendation = 'Set temperature to 3-4°C. Avoid frequent door opening. Defrost regularly.';
      suggestedHours = currentHours;
    } else if (name.contains('freezer')) {
      recommendation = 'Set to -18°C. Keep 75% full for efficiency. Defrost when ice >1cm thick.';
      suggestedHours = currentHours;
    } else if (name.contains('tv') || name.contains('television')) {
      recommendation = 'Reduce brightness to 50%. Unplug when not in use to avoid standby power.';
      suggestedHours = (currentHours * 0.7).clamp(1, 24).round();
    } else if (name.contains('kettle')) {
      recommendation = 'Boil only needed water. Descale monthly for faster boiling.';
      suggestedHours = (currentHours * 0.5).clamp(0.5, 24).round();
    } else if (name.contains('iron')) {
      recommendation = 'Iron multiple items at once. Use residual heat for last items.';
      suggestedHours = (currentHours * 0.7).clamp(0.5, 24).round();
    } else if (name.contains('fan')) {
      recommendation = 'Use oscillation mode. Turn off when room is empty.';
      suggestedHours = (currentHours - 2).clamp(1, 24);
    } else if (name.contains('wash')) {
      recommendation = 'Wash full loads only. Use cold water when possible.';
      suggestedHours = (currentHours * 0.7).clamp(0.5, 24).round();
    } else if (name.contains('microwave') || name.contains('oven')) {
      recommendation = 'Use for reheating only. Cook multiple items together.';
      suggestedHours = (currentHours * 0.5).clamp(0.5, 24).round();
    } else if (name.contains('heater') || name.contains('water heater')) {
      recommendation = 'Set to 50°C-60°C. Turn off when not needed. Consider solar heating.';
      suggestedHours = (currentHours * 0.5).clamp(1, 24).round();
    } else if (name.contains('pump') || name.contains('water pump')) {
      recommendation = 'Use timer switch. Pump during off-peak hours (11pm-5am).';
      suggestedHours = (currentHours * 0.6).clamp(1, 24).round();
    } else if (name.contains('bulb') || name.contains('light')) {
      recommendation = 'Switch to LED bulbs. Use motion sensors where possible.';
      suggestedHours = (currentHours * 0.8).clamp(1, 24).round();
    } else if (name.contains('decoder') || name.contains('dstv') || name.contains('gotv')) {
      recommendation = 'Unplug when not watching. Avoid standby mode which still consumes power.';
      suggestedHours = (currentHours * 0.7).clamp(1, 24).round();
    } else if (currentHours >= 12) {
      recommendation = 'Consider reducing usage time or using during off-peak hours.';
      suggestedHours = (currentHours - 3).clamp(1, 24);
    } else {
      recommendation = 'Turn off when not in use. Unplug to avoid standby power consumption.';
      suggestedHours = (currentHours - 1).clamp(1, 24);
    }

    final reducedUnits = (appliance.wattage * appliance.quantity * suggestedHours) / 1000;
    final unitsSaved = currentUnits - reducedUnits;

    if (unitsSaved <= 0.3) return null;

    final nairaSavedPerMonth = unitsSaved * 30 * 100;

    return PowerSaverTip(
      applianceId: appliance.id,
      applianceName: appliance.name,
      currentHours: currentHours,
      suggestedHours: suggestedHours,
      unitsSavedPerDay: unitsSaved,
      nairaSavedPerMonth: nairaSavedPerMonth,
      recommendation: recommendation,
    );
  }

  // ══════════════════════════════════════════════════════════
  // DISPOSE
  // ══════════════════════════════════════════════════════════

  @override
  void dispose() {
    if (kDebugMode) print('[Controller] Disposing...');
    super.dispose();
  }
}