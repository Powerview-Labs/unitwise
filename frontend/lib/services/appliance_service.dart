import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appliance_model.dart';
import '../models/appliance_estimator_model.dart';
import '../utils/appliance_calculator.dart';
import '../config/app_config.dart';
import 'local_storage_service.dart';
import 'band_lookup_service.dart';

/// Core business logic for Appliance Estimator
/// 
/// This service orchestrates:
/// - Band adjustment (via BandLookupService)
/// - Calculation (via ApplianceCalculator)
/// - Local storage (via LocalStorageService)
/// - Firestore persistence
/// 
/// Dependencies are injected for testability
class ApplianceService {
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorage;
  final BandLookupService _bandLookup;
  
  ApplianceService({
    FirebaseFirestore? firestore,
    LocalStorageService? localStorage,
    BandLookupService? bandLookup,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _localStorage = localStorage ?? LocalStorageService(),
        _bandLookup = bandLookup ?? FirestoreBandLookupService();
  
  // ========================================================================
  // BAND ADJUSTMENT
  // ========================================================================
  
  /// Apply band adjustment to all appliances
  /// 
  /// Formula: adjusted_hours = min(user_hours, band_supply_hours)
  /// 
  /// This is SILENT - no errors, no warnings
  /// Band data comes from Module 2 via BandLookupService abstraction
  Future<List<Appliance>> applyBandAdjustment({
    required List<Appliance> appliances,
    required String userId,
  }) async {
    // Get band hours from Module 2
    final bandResult = await _bandLookup.getBandSupplyHours(userId);
    final bandSupplyHours = bandResult.hours;
    
    if (AppConfig.isTestMode && bandResult.isAssumption) {
      debugPrint('ℹ️ Using assumed band hours: $bandSupplyHours');
    }
    
    // Apply adjustment to each appliance
    return appliances.map((appliance) {
      final adjustedHours = ApplianceCalculator.calculateAdjustedHours(
        userHours: appliance.hoursPerDay,
        bandSupplyHours: bandSupplyHours,
      );
      
      return appliance.copyWith(adjustedHours: adjustedHours);
    }).toList();
  }
  
  // ========================================================================
  // CALCULATION & ESTIMATION
  // ========================================================================
  
  /// Calculate complete estimator model
  /// 
  /// This is the PRIMARY CALCULATION METHOD.
  /// 
  /// Steps:
  /// 1. Apply band adjustment
  /// 2. Calculate total daily burn
  /// 3. Check if any appliance was band-adjusted
  /// 4. Generate power saver tips
  /// 5. Return complete model
  Future<ApplianceEstimatorModel> calculateEstimator({
    required List<Appliance> appliances,
    required String userId,
    required bool isCompleted,
  }) async {
    // Step 1: Apply band adjustment
    final bandResult = await _bandLookup.getBandSupplyHours(userId);
    final adjustedAppliances = await applyBandAdjustment(
      appliances: appliances,
      userId: userId,
    );
    
    // Step 2: Calculate total daily burn
    final dailyBurn = ApplianceCalculator.calculateTotalDailyBurn(adjustedAppliances);
    
    // Step 3: Check if any appliance was band-adjusted
    final bandAdjusted = ApplianceCalculator.anyBandAdjusted(adjustedAppliances);
    
    // Step 4: Generate power saver tips
    final tips = ApplianceCalculator.generatePowerSaverTips(
      appliances: adjustedAppliances,
      unitRate: bandResult.unitRate,
    );
    
    if (AppConfig.isTestMode) {
      debugPrint('📊 Estimator calculated:');
      debugPrint('   Appliances: ${adjustedAppliances.length}');
      debugPrint('   Daily burn: ${dailyBurn.toStringAsFixed(2)} units/day');
      debugPrint('   Band adjusted: $bandAdjusted');
      debugPrint('   Tips generated: ${tips.length}');
    }
    
    // Step 5: Return complete model
    return ApplianceEstimatorModel(
      appliances: adjustedAppliances,
      dailyBurnEstimate: dailyBurn,
      bandAdjusted: bandAdjusted,
      applianceSetupCompleted: isCompleted,
      lastUpdated: DateTime.now(),
      tips: tips,
      isDraft: !isCompleted,
      bandDataIsAssumption: bandResult.isAssumption,
    );
  }
  
  // ========================================================================
  // FIRESTORE PERSISTENCE
  // ========================================================================
  
  /// Save estimator to Firestore
  /// 
  /// Path: users/{uid}/appliance_estimator/current
  /// 
  /// Security: Firestore rules enforce uid ownership
  Future<bool> saveToFirestore({
    required ApplianceEstimatorModel estimator,
    required String userId,
  }) async {
    try {
      final docPath = AppConfig.getEstimatorPath(userId);
      final json = estimator.toJson();
      
      await _firestore.doc(docPath).set(json, SetOptions(merge: true));
      
      if (AppConfig.isTestMode) {
        debugPrint('✅ Estimator saved to Firestore');
        debugPrint('   Path: $docPath');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error saving to Firestore: $e');
      return false;
    }
  }
  
  /// Load estimator from Firestore
  /// 
  /// Returns null if no saved estimator exists
  Future<ApplianceEstimatorModel?> loadFromFirestore(String userId) async {
    try {
      final docPath = AppConfig.getEstimatorPath(userId);
      final doc = await _firestore.doc(docPath).get();
      
      if (!doc.exists) {
        if (AppConfig.isTestMode) {
          debugPrint('ℹ️ No saved estimator in Firestore');
        }
        return null;
      }
      
      final estimator = ApplianceEstimatorModel.fromJson(doc.data()!);
      
      if (AppConfig.isTestMode) {
        debugPrint('✅ Estimator loaded from Firestore');
      }
      
      return estimator;
    } catch (e) {
      debugPrint('❌ Error loading from Firestore: $e');
      return null;
    }
  }
  
  // ========================================================================
  // DRAFT OPERATIONS
  // ========================================================================
  
  /// Save draft locally (encrypted)
  /// 
  /// This is called during auto-save (every 2 seconds)
  Future<bool> saveDraft(ApplianceEstimatorModel estimator) async {
    return await _localStorage.saveDraft(estimator);
  }
  
  /// Load draft from local storage
  /// 
  /// Returns null if no draft exists or draft is expired
  Future<ApplianceEstimatorModel?> loadDraft() async {
    return await _localStorage.loadDraft();
  }
  
  /// Check if draft exists
  Future<bool> hasDraft() async {
    return await _localStorage.hasDraft();
  }
  
  // ========================================================================
  // COMPLETE SAVE FLOW
  // ========================================================================
  
  /// Complete save flow: Calculate → Save Local → Save Firestore → Clear Draft
  /// 
  /// This is the PRIMARY SAVE METHOD called from UI.
  /// 
  /// Steps:
  /// 1. Calculate estimator with completion flag = true
  /// 2. Save to Firestore
  /// 3. Clear local draft (no longer needed)
  /// 4. Return saved estimator
  /// 
  /// Throws exception if Firestore save fails
  Future<ApplianceEstimatorModel> saveComplete({
    required List<Appliance> appliances,
    required String userId,
  }) async {
    // Step 1: Calculate with completion flag = true
    final estimator = await calculateEstimator(
      appliances: appliances,
      userId: userId,
      isCompleted: true,
    );
    
    // Step 2: Save to Firestore
    final firestoreSaved = await saveToFirestore(
      estimator: estimator,
      userId: userId,
    );
    
    if (!firestoreSaved) {
      throw Exception('Failed to save estimator to Firestore');
    }
    
    // Step 3: Clear local draft (save successful)
    await _localStorage.deleteDraft();
    
    if (AppConfig.isTestMode) {
      debugPrint('✅ Complete save successful');
      debugPrint('   appliance_setup_completed = true');
      debugPrint('   Token Logger now UNLOCKED');
    }
    
    return estimator;
  }
  
  /// Save draft flow: Calculate → Save Local Only
  /// 
  /// Used during auto-save while editing
  Future<ApplianceEstimatorModel> saveDraftOnly({
    required List<Appliance> appliances,
    required String userId,
  }) async {
    // Calculate with completion flag = false (draft)
    final estimator = await calculateEstimator(
      appliances: appliances,
      userId: userId,
      isCompleted: false,
    );
    
    // Save locally only
    await saveDraft(estimator);
    
    if (AppConfig.isTestMode) {
      debugPrint('💾 Draft auto-saved');
    }
    
    return estimator;
  }

  // ========================================================================
  // LOAD ESTIMATOR (NEW METHOD - FIXES NAVIGATION)
  // ========================================================================
  
  /// Load estimator for current user
  /// 
  /// This method is called by ApplianceEstimatorController.initialize()
  /// 
  /// Priority:
  /// 1. Load from local draft (offline-first)
  /// 2. Return null if no data exists (new user)
  /// 
  /// Returns null for new users - the UI will show empty state
  /// with "Add Your First Appliance" button
  Future<ApplianceEstimatorModel?> loadEstimator() async {
    try {
      // Load from draft (offline-first approach)
      final draft = await loadDraft();
      if (draft != null) {
        if (AppConfig.isTestMode) {
          debugPrint('📂 Loaded estimator from local draft');
        }
        return draft;
      }

      // No draft found - this is normal for new users
      if (AppConfig.isTestMode) {
        debugPrint('ℹ️ No saved estimator found (new user)');
      }
      return null;

    } catch (e) {
      // Gracefully handle any errors
      if (AppConfig.isTestMode) {
        debugPrint('⚠️ Error loading estimator: $e');
      }
      return null;
    }
  }
}