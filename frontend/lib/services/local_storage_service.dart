import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/appliance_estimator_model.dart';
import '../config/app_config.dart';

/// Handles encrypted local storage for estimator drafts
/// 
/// SECURITY:
/// - Uses flutter_secure_storage for encryption
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences (AES)
/// 
/// Draft lifecycle:
/// 1. Auto-save while editing (every 2 seconds)
/// 2. Persist across app restarts
/// 3. Expire after 7 days
/// 4. Clear after successful Firestore save
class LocalStorageService {
  final FlutterSecureStorage _secureStorage;
  
  LocalStorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? 
          const FlutterSecureStorage(
            aOptions: AndroidOptions(
              encryptedSharedPreferences: true,
            ),
          );
  
  // ========================================================================
  // DRAFT OPERATIONS
  // ========================================================================
  
  /// Save estimator draft (encrypted)
  /// 
  /// Returns true if save successful, false otherwise
  Future<bool> saveDraft(ApplianceEstimatorModel estimator) async {
    try {
      // Mark as draft
      final draftModel = estimator.copyWith(isDraft: true);
      
      // Serialize to JSON
      final json = draftModel.toJson();
      final jsonString = jsonEncode(json);
      
      // Write encrypted
      await _secureStorage.write(
        key: AppConfig.localStorageKey,
        value: jsonString,
      );
      
      if (AppConfig.isTestMode) {
        debugPrint('✅ Draft saved locally (encrypted)');
        debugPrint('   Appliances: ${estimator.applianceCount}');
        debugPrint('   Daily burn: ${estimator.dailyBurnEstimate.toStringAsFixed(2)} units');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error saving draft: $e');
      return false;
    }
  }
  
  /// Load estimator draft (decrypt)
  /// 
  /// Returns null if:
  /// - No draft exists
  /// - Draft is expired (>7 days old)
  /// - Decryption fails
  Future<ApplianceEstimatorModel?> loadDraft() async {
    try {
      // Read encrypted value
      final jsonString = await _secureStorage.read(
        key: AppConfig.localStorageKey,
      );
      
      if (jsonString == null) {
        if (AppConfig.isTestMode) {
          debugPrint('ℹ️ No draft found in local storage');
        }
        return null;
      }
      
      // Deserialize
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final estimator = ApplianceEstimatorModel.fromJson(json);
      
      // Check expiration
      final age = DateTime.now().difference(estimator.lastUpdated).inDays;
      if (age > AppConfig.draftCacheDays) {
        if (AppConfig.isTestMode) {
          debugPrint('⚠️ Draft expired ($age days old), deleting...');
        }
        await deleteDraft();
        return null;
      }
      
      if (AppConfig.isTestMode) {
        debugPrint('✅ Draft loaded from local storage');
        debugPrint('   Age: $age days');
        debugPrint('   Appliances: ${estimator.applianceCount}');
      }
      
      return estimator;
    } catch (e) {
      debugPrint('❌ Error loading draft: $e');
      // If decryption fails, delete corrupted draft
      await deleteDraft();
      return null;
    }
  }
  
  /// Delete draft from storage
  /// 
  /// Returns true if deletion successful, false otherwise
  Future<bool> deleteDraft() async {
    try {
      await _secureStorage.delete(key: AppConfig.localStorageKey);
      
      if (AppConfig.isTestMode) {
        debugPrint('✅ Draft deleted from local storage');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting draft: $e');
      return false;
    }
  }
  
  /// Check if draft exists
  /// 
  /// Returns true if a draft is available, false otherwise
  Future<bool> hasDraft() async {
    try {
      final jsonString = await _secureStorage.read(
        key: AppConfig.localStorageKey,
      );
      return jsonString != null;
    } catch (e) {
      return false;
    }
  }
  
  // ========================================================================
  // METADATA OPERATIONS
  // ========================================================================
  
  /// Get draft age in days
  /// 
  /// Returns null if no draft exists
  Future<int?> getDraftAge() async {
    try {
      final estimator = await loadDraft();
      if (estimator == null) return null;
      
      return DateTime.now().difference(estimator.lastUpdated).inDays;
    } catch (e) {
      return null;
    }
  }
  
  /// Clear all estimator data from storage
  /// 
  /// WARNING: This is a destructive operation
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      
      if (AppConfig.isTestMode) {
        debugPrint('⚠️ All local storage cleared');
      }
    } catch (e) {
      debugPrint('❌ Error clearing storage: $e');
    }
  }
}
