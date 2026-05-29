import 'package:flutter/foundation.dart';
import '../models/budget_plan.dart';
import '../models/budget_input_mode.dart';
import '../models/power_saving_tip.dart';
import '../services/budget_calculation_service.dart';
import '../services/budget_planner_service.dart';
import '../services/rate_lookup_service.dart';
import '../services/tips_engine_service.dart';
import '../utils/budget_input_validator.dart';

/// State management for Budget Planner module
/// WHY: Centralized state with ChangeNotifier for reactive UI
/// SECURITY: All user inputs validated before state updates
class BudgetPlannerProvider extends ChangeNotifier {
  // ==================== SERVICES ====================
  
  final BudgetCalculationService _calculationService;
  final BudgetPlannerService _plannerService;
  final RateLookupService _rateLookupService;
  final TipsEngineService _tipsEngineService;

  BudgetPlannerProvider({
    BudgetCalculationService? calculationService,
    BudgetPlannerService? plannerService,
    RateLookupService? rateLookupService,
    TipsEngineService? tipsEngineService,
  })  : _calculationService = calculationService ?? BudgetCalculationService(),
        _plannerService = plannerService ?? BudgetPlannerService(),
        _rateLookupService = rateLookupService ?? RateLookupService(),
        _tipsEngineService = tipsEngineService ?? TipsEngineService();

  // ==================== STATE VARIABLES ====================

  // Input state
  BudgetInputMode _inputMode = BudgetInputMode.budgetAmount;
  double? _budgetAmount;
  double? _targetUnits;

  // Calculation results
  double? _calculatedUnits;
  double? _estimatedDays;
  
  // Dependencies (read-only from other modules)
  double? _currentBurnRate;
  double? _currentRate;
  String? _disco;
  String? _band;
  String? _userId;
  
  // Tips
  List<PowerSavingTip> _tips = [];
  
  // Saved plans
  List<BudgetPlan> _savedPlans = [];
  
  // UI state
  bool _isLoading = false;
  String? _error;
  bool _dependenciesMet = false;
  
  // Validation errors
  String? _budgetAmountError;
  String? _targetUnitsError;

  // ==================== GETTERS ====================

  BudgetInputMode get inputMode => _inputMode;
  double? get budgetAmount => _budgetAmount;
  double? get targetUnits => _targetUnits;
  double? get calculatedUnits => _calculatedUnits;
  double? get estimatedDays => _estimatedDays;
  double? get currentBurnRate => _currentBurnRate;
  double? get currentRate => _currentRate;
  String? get disco => _disco;
  String? get band => _band;
  List<PowerSavingTip> get tips => _tips;
  List<BudgetPlan> get savedPlans => _savedPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get dependenciesMet => _dependenciesMet;
  String? get budgetAmountError => _budgetAmountError;
  String? get targetUnitsError => _targetUnitsError;
  
  bool get canCalculate =>
      _dependenciesMet &&
      (_budgetAmount != null || _targetUnits != null) &&
      _budgetAmountError == null &&
      _targetUnitsError == null;

  // ==================== INITIALIZATION ====================

  /// Initialize provider with user data and dependencies
  /// WHY: Load user-specific context before UI renders
  Future<void> initialize({
    required String userId,
    required double burnRate,
    required String disco,
    required String band,
    double? cachedRate,
    DateTime? cacheTimestamp,
  }) async {
    _userId = userId;
    _currentBurnRate = burnRate;
    _disco = disco;
    _band = band;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check dependencies
      final dependencyCheck = await _plannerService.checkDependencies(
        userId: userId,
      );
      _dependenciesMet = dependencyCheck.allMet;

      if (!_dependenciesMet) {
        _error = dependencyCheck.errorMessage;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch current rate
      final rateResult = await _rateLookupService.getCurrentRate(
        userId: userId,
        disco: disco,
        band: band,
        cachedRate: cachedRate,
        cacheTimestamp: cacheTimestamp,
      );
      _currentRate = rateResult.rate;

      // Load saved plans
      await _loadSavedPlans();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      if (kDebugMode) {
        debugPrint('BudgetPlannerProvider initialization error: $e');
      }
    }
  }

  // ==================== INPUT MODE CONTROL ====================

  /// Switch between budget amount and target units input
  /// SECURITY: Clears inactive field to enforce mutual exclusivity
  void switchInputMode(BudgetInputMode newMode) {
    if (_inputMode == newMode) return;

    _inputMode = newMode;

    // Clear inactive field and its error
    if (newMode == BudgetInputMode.budgetAmount) {
      _targetUnits = null;
      _targetUnitsError = null;
    } else {
      _budgetAmount = null;
      _budgetAmountError = null;
    }

    // Clear results
    _calculatedUnits = null;
    _estimatedDays = null;
    _tips.clear();

    notifyListeners();
  }

  // ==================== INPUT SETTERS WITH VALIDATION ====================

  /// Set budget amount with validation
  /// SECURITY: Sanitizes and validates input before storing
  void setBudgetAmount(String input) {
    // SECURITY: Sanitize input
    final sanitized = BudgetInputValidator.sanitizeNumericInput(input);

    if (sanitized == null) {
      _budgetAmount = null;
      _budgetAmountError = input.isEmpty ? null : 'Invalid input';
      notifyListeners();
      return;
    }

    // Validate range
    final validation = BudgetInputValidator.validateBudgetAmount(sanitized);
    
    _budgetAmount = sanitized;
    _budgetAmountError = validation.errorMessage ?? validation.warningMessage;

    notifyListeners();
  }

  /// Set target units with validation
  /// SECURITY: Sanitizes and validates input before storing
  void setTargetUnits(String input) {
    // SECURITY: Sanitize input
    final sanitized = BudgetInputValidator.sanitizeNumericInput(input);

    if (sanitized == null) {
      _targetUnits = null;
      _targetUnitsError = input.isEmpty ? null : 'Invalid input';
      notifyListeners();
      return;
    }

    // Validate range
    final validation = BudgetInputValidator.validateTargetUnits(sanitized);
    
    _targetUnits = sanitized;
    _targetUnitsError = validation.errorMessage;

    notifyListeners();
  }

  // ==================== CALCULATION ====================

  /// Perform budget calculation and generate tips
  /// WHY: Main action triggered by "Calculate" button
  Future<void> calculate() async {
    if (!canCalculate) {
      _error = 'Cannot calculate: missing required data';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_inputMode == BudgetInputMode.budgetAmount && _budgetAmount != null) {
        // Calculate from budget amount
        final result = _calculationService.calculateFromBudget(
          budgetAmount: _budgetAmount!,
          ratePerUnit: _currentRate!,
          dailyBurnRate: _currentBurnRate!,
        );

        _calculatedUnits = result['calculatedUnits'];
        _estimatedDays = result['estimatedDays'];

      } else if (_inputMode == BudgetInputMode.targetUnits && _targetUnits != null) {
        // Calculate from target units
        final result = _calculationService.calculateFromUnits(
          targetUnits: _targetUnits!,
          ratePerUnit: _currentRate!,
          dailyBurnRate: _currentBurnRate!,
        );

        _calculatedUnits = _targetUnits; // Same as input in this mode
        _estimatedDays = result['estimatedDays'];
      }

      // Generate tips
      _generateTips();

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _error = 'Calculation failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('Calculation error: $e');
      }
    }
  }

  /// Generate power-saving tips based on results
  void _generateTips() {
    if (_estimatedDays == null || _currentBurnRate == null) return;

    _tips = _tipsEngineService.generateTips(
      estimatedDays: _estimatedDays!,
      burnRate: _currentBurnRate!,
      budgetAmount: _budgetAmount ?? 0,
      targetDays: 7.0, // Default target
      // TODO: Pass top appliances from Appliance Estimator if available
    );
  }

  // ==================== SAVE PLAN ====================

  /// Save current calculation as a plan
  /// WHY: User wants to keep this planning snapshot for reference
  Future<void> savePlan() async {
    if (_userId == null ||
        _calculatedUnits == null ||
        _estimatedDays == null ||
        _currentBurnRate == null ||
        _currentRate == null ||
        _disco == null ||
        _band == null) {
      _error = 'Cannot save plan: missing required data';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final plan = BudgetPlan(
        id: '', // Will be set by service
        budgetAmount: _budgetAmount,
        targetUnits: _targetUnits,
        calculatedUnits: _calculatedUnits!,
        estimatedDays: _estimatedDays!,
        burnRate: _currentBurnRate!,
        disco: _disco!,
        band: _band!,
        rateUsed: _currentRate!,
        tipsShown: _tips.map((t) => t.message).toList(),
        createdAt: DateTime.now(),
      );

      await _plannerService.savePlan(
        userId: _userId!,
        plan: plan,
      );

      // Reload saved plans
      await _loadSavedPlans();

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _error = 'Failed to save plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('Save plan error: $e');
      }
    }
  }

  // ==================== LOAD SAVED PLANS ====================

  Future<void> _loadSavedPlans() async {
    if (_userId == null) return;

    try {
      _savedPlans = await _plannerService.fetchSavedPlans(
        userId: _userId!,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading saved plans: $e');
      }
      // Don't set error - non-critical failure
    }
  }

  /// Refresh saved plans list
  Future<void> refreshSavedPlans() async {
    _isLoading = true;
    notifyListeners();

    await _loadSavedPlans();

    _isLoading = false;
    notifyListeners();
  }

  // ==================== DELETE PLAN ====================

  /// Delete a saved plan
  Future<void> deletePlan(String planId) async {
    if (_userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _plannerService.deletePlan(
        userId: _userId!,
        planId: planId,
      );

      // Remove from local list
      _savedPlans.removeWhere((p) => p.id == planId);

      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _error = 'Failed to delete plan: ${e.toString()}';
      _isLoading = false;
      notifyListeners();

      if (kDebugMode) {
        debugPrint('Delete plan error: $e');
      }
    }
  }

  // ==================== RESET ====================

  /// Reset all inputs and results
  void reset() {
    _budgetAmount = null;
    _targetUnits = null;
    _calculatedUnits = null;
    _estimatedDays = null;
    _tips.clear();
    _budgetAmountError = null;
    _targetUnitsError = null;
    _error = null;
    notifyListeners();
  }
}