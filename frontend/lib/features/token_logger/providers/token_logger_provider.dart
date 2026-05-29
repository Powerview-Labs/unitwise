// lib/features/token_logger/providers/token_logger_provider.dart

import 'package:flutter/foundation.dart';
import '../models/token_log.dart';
import '../services/token_logger_gating_service.dart';
import '../services/token_calculation_service.dart';
import '../services/rate_lookup_service.dart';
import '../services/token_logger_firestore_service.dart';

/// Token Logger Provider
/// 
/// PURPOSE: Manages state for token logging flow
/// PATTERN: Provider with ChangeNotifier
/// 
/// RESPONSIBILITIES:
///   - Manage form state (amount, date, token code)
///   - Trigger calculations
///   - Handle save operation
///   - Notify Dashboard on success
class TokenLoggerProvider with ChangeNotifier {
  final TokenLoggerGatingService _gatingService;
  final TokenCalculationService _calculationService;
  final TokenLoggerFirestoreService _firestoreService;

  TokenLoggerProvider({
    TokenLoggerGatingService? gatingService,
    TokenLoggerFirestoreService? firestoreService,
  })  : _gatingService = gatingService ?? TokenLoggerGatingService(),
        _calculationService = TokenCalculationService(),
        _firestoreService = firestoreService ?? TokenLoggerFirestoreService();

  // Form state
  double _amountPaid = 0.0;
  DateTime _purchaseDate = DateTime.now();
  String _tokenCode = '';
  
  // Calculated values
  double? _unitsPurchased;
  double? _estimatedBurn;
  double? _estimatedRemaining;
  String? _elapsedBurnExplanation;

  // Location data (from user profile)
  String? _disco;
  String? _band;
  double? _unitRate;
  
  // Daily burn rate (from Appliance Estimator)
  double? _dailyBurnRate;

  // UI state
  bool _isLoading = false;
  bool _isCalculating = false;
  String? _errorMessage;
  bool _showConfirmation = false;

  // Getters
  double get amountPaid => _amountPaid;
  DateTime get purchaseDate => _purchaseDate;
  String get tokenCode => _tokenCode;
  double? get unitsPurchased => _unitsPurchased;
  double? get estimatedBurn => _estimatedBurn;
  double? get estimatedRemaining => _estimatedRemaining;
  String? get elapsedBurnExplanation => _elapsedBurnExplanation;
  String? get disco => _disco;
  String? get band => _band;
  double? get unitRate => _unitRate;
  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  String? get errorMessage => _errorMessage;
  bool get showConfirmation => _showConfirmation;
  bool get canCalculate => _amountPaid > 0 && _disco != null && _band != null;

  /// Initialize provider with user data
  /// 
  /// CALLED BY: Token Entry Screen on mount
  /// FETCHES: DisCo, Band, and daily burn rate
  Future<void> initialize(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch location data (DisCo + Band)
      final locationData = await _gatingService.getLocationData(userId);
      if (locationData == null) {
        throw Exception('Location data not found. Please complete location setup.');
      }

      _disco = locationData.disco;
      _band = locationData.band;

      // Fetch daily burn rate
      _dailyBurnRate = await _gatingService.getDailyBurnRate(userId);
      if (_dailyBurnRate == null) {
        throw Exception('Daily burn rate not found. Please complete appliance estimator.');
      }

      // Get unit rate
      _unitRate = RateLookupService.getRate(_disco!, _band!);
      if (_unitRate == null) {
        // Fallback to default rate
        _unitRate = RateLookupService.getFallbackRate();
        print('⚠️ [TOKEN LOGGER] Using fallback rate: ₦$_unitRate/kWh');
      }

      print('✅ [TOKEN LOGGER] Initialized: DisCo=$_disco, Band=$_band, Rate=₦$_unitRate/kWh, Burn=$_dailyBurnRate units/day');

    } catch (e) {
      _errorMessage = e.toString();
      print('❌ [TOKEN LOGGER ERROR] Initialization failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update amount paid
  /// 
  /// VALIDATION: Positive number, sane range
  /// TRIGGERS: Automatic recalculation if all fields valid
  void setAmountPaid(double amount) {
    _amountPaid = amount;
    _errorMessage = null;
    
    // Auto-calculate if ready
    if (canCalculate) {
      _calculateUnits();
    } else {
      // Clear previous calculations
      _unitsPurchased = null;
      _estimatedBurn = null;
      _estimatedRemaining = null;
      _elapsedBurnExplanation = null;
    }
    
    notifyListeners();
  }

  /// Update purchase date
  /// 
  /// VALIDATION: Not future, not too old
  /// TRIGGERS: Automatic recalculation
  void setPurchaseDate(DateTime date) {
    _purchaseDate = date;
    _errorMessage = null;
    
    // Auto-calculate if ready
    if (canCalculate) {
      _calculateUnits();
    }
    
    notifyListeners();
  }

  /// Update token code (optional)
  /// 
  /// SECURITY: Sanitize input (trim whitespace)
  void setTokenCode(String code) {
    _tokenCode = code.trim();
    notifyListeners();
  }

  /// Calculate units and estimated remaining
  /// 
  /// FORMULA:
  ///   1. units_purchased = amount / rate
  ///   2. elapsed_burn = daily_burn × days_elapsed
  ///   3. estimated_remaining = units - elapsed_burn
  void _calculateUnits() {
    if (!canCalculate || _unitRate == null || _dailyBurnRate == null) {
      return;
    }

    _isCalculating = true;
    notifyListeners();

    try {
      // STEP 1: Calculate units purchased
      _unitsPurchased = TokenCalculationService.calculateUnitsPurchased(
        amountPaid: _amountPaid,
        unitRate: _unitRate!,
      );

      // STEP 2: Calculate elapsed burn (if past purchase)
      _estimatedBurn = TokenCalculationService.calculateElapsedBurn(
        purchaseDate: _purchaseDate,
        dailyBurnRate: _dailyBurnRate!,
      );

      // STEP 3: Calculate estimated remaining
      _estimatedRemaining = TokenCalculationService.calculateEstimatedRemaining(
        unitsPurchased: _unitsPurchased!,
        estimatedBurn: _estimatedBurn!,
      );

      // STEP 4: Generate explanation
      if (_estimatedBurn! > 0) {
        _elapsedBurnExplanation = TokenCalculationService.getElapsedBurnExplanation(
          purchaseDate: _purchaseDate,
          dailyBurnRate: _dailyBurnRate!,
        );
      } else {
        _elapsedBurnExplanation = null;
      }

      print('✅ [TOKEN LOGGER] Calculated: '
            'Units=$_unitsPurchased, Burn=$_estimatedBurn, Remaining=$_estimatedRemaining');

    } catch (e) {
      _errorMessage = 'Calculation failed: ${e.toString()}';
      print('❌ [TOKEN LOGGER ERROR] Calculation failed: $e');
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  /// Show confirmation dialog
  void requestConfirmation() {
    if (_unitsPurchased == null) {
      _errorMessage = 'Please enter amount and date first.';
      notifyListeners();
      return;
    }

    _showConfirmation = true;
    notifyListeners();
  }

  /// Cancel confirmation
  void cancelConfirmation() {
    _showConfirmation = false;
    notifyListeners();
  }

  /// Save token log to Firestore
  /// 
  /// ATOMICITY: Single transaction
  /// ON SUCCESS: Notify Dashboard to recalculate balance
  /// ON ERROR: Show user-friendly error message
  Future<bool> saveTokenLog(String userId) async {
    if (_unitsPurchased == null || 
        _disco == null || 
        _band == null || 
        _unitRate == null) {
      _errorMessage = 'Missing required data. Please try again.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create TokenLog model
      final tokenLog = TokenLog(
        id: '', // Will be set by Firestore
        amountPaid: _amountPaid,
        purchaseDate: _purchaseDate,
        tokenCode: _tokenCode.isEmpty ? null : _tokenCode,
        disco: _disco!,
        band: _band!,
        unitRate: _unitRate!,
        unitsPurchased: _unitsPurchased!,
        estimatedUnitsRemainingAtLog: _estimatedRemaining ?? 0.0,
        estimationMethod: 'appliance_based',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      final logId = await _firestoreService.saveTokenLog(
        userId: userId,
        tokenLog: tokenLog,
      );

      print('✅ [TOKEN LOGGER] Saved successfully: $logId');

      // Reset form
      _resetForm();

      return true;

    } catch (e) {
      _errorMessage = 'Failed to save token log. Please try again.';
      print('❌ [TOKEN LOGGER ERROR] Save failed: $e');
      return false;
    } finally {
      _isLoading = false;
      _showConfirmation = false;
      notifyListeners();
    }
  }

  /// Reset form to initial state
  void _resetForm() {
    _amountPaid = 0.0;
    _purchaseDate = DateTime.now();
    _tokenCode = '';
    _unitsPurchased = null;
    _estimatedBurn = null;
    _estimatedRemaining = null;
    _elapsedBurnExplanation = null;
    _showConfirmation = false;
    notifyListeners();
  }

  /// Manual reset (called by user)
  void reset() {
    _resetForm();
  }

  /// Get formatted amount for display
  String get formattedAmount => TokenCalculationService.formatAmount(_amountPaid);

  /// Get formatted units for display
  String get formattedUnits => 
      _unitsPurchased != null 
          ? TokenCalculationService.formatUnits(_unitsPurchased!) 
          : '0.0 units';

  /// Get formatted date for display
  String get formattedDate => TokenCalculationService.formatDate(_purchaseDate);

  /// Get low remaining warning (if applicable)
  String? get lowRemainingWarning =>
      _estimatedRemaining != null
          ? TokenCalculationService.getLowRemainingWarning(_estimatedRemaining!)
          : null;

  /// Validate form before allowing save
  bool get canSave => 
      _unitsPurchased != null && 
      _amountPaid >= 100 && 
      _amountPaid <= 100000 &&
      TokenCalculationService.isValidPurchaseDate(_purchaseDate);
}
