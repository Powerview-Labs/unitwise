/// storage_service.dart
///
/// SECURITY-CRITICAL: Secure local storage service
/// Uses flutter_secure_storage for sensitive data (tokens, passwords)
/// Uses shared_preferences for non-sensitive data (settings, preferences)
///
/// ✅ CRITICAL FIX #3: Added dashboard cache methods with corruption handling
///
/// Key Security Features:
/// - AES encryption for tokens (handled by flutter_secure_storage)
/// - No plaintext credentials stored
/// - Secure key management via platform keychains
/// - Clear separation of sensitive vs non-sensitive data
/// - Secure deletion on logout
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Singleton pattern for global access
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Storage instances
  late FlutterSecureStorage _secureStorage;
  late SharedPreferences _preferences;
  bool _initialized = false;

  /// Storage keys (constants to avoid typos)
  /// SECURITY: Keep key names obfuscated to prevent reverse engineering
  static const String _keyAuthToken = 'auth_tkn'; // Firebase ID token
  static const String _keyRefreshToken = 'rfsh_tkn'; // Firebase refresh token
  static const String _keyUserId = 'usr_id'; // Firebase UID
  static const String _keyRememberMe = 'rmmbr_me'; // Remember me preference
  static const String _keyLastLogin = 'lst_lgn'; // Last login timestamp
  static const String _keyBiometricsEnabled = 'bio_enbl'; // Biometric auth preference
  static const String _keyDashboardCache = 'dash_cache_v1'; // Dashboard state cache

  /// Initialize storage systems
  /// SECURITY: Called once on app startup before any storage operations
  Future<void> initialize() async {
    if (_initialized) return; // Prevent duplicate initialization

    // SECURITY: Configure secure storage with platform-specific options
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true, // Use encrypted preferences on Android
        resetOnError: true, // Reset if corrupted to prevent crashes
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device, // iOS Keychain protection level
      ),
    );

    // Initialize SharedPreferences for non-sensitive data
    _preferences = await SharedPreferences.getInstance();

    _initialized = true;
  }

  /// Ensure storage is initialized before any operation
  /// SECURITY: Prevents accidental use of uninitialized storage
  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception('StorageService not initialized. Call initialize() first.');
    }
  }

  // ==================== SECURE STORAGE (SENSITIVE DATA) ====================
  // SECURITY: All methods below use encrypted storage via flutter_secure_storage

  /// Save Firebase auth token (ID token)
  /// SECURITY: Token is encrypted at rest using platform keychain
  /// @param token - Firebase ID token (JWT)
  Future<void> saveAuthToken(String token) async {
    _ensureInitialized();
    // SECURITY: Token is automatically encrypted by flutter_secure_storage
    await _secureStorage.write(key: _keyAuthToken, value: token);
  }

  /// Retrieve Firebase auth token
  /// SECURITY: Token is automatically decrypted from keychain
  /// @returns Firebase ID token or null if not found
  Future<String?> getAuthToken() async {
    _ensureInitialized();
    return await _secureStorage.read(key: _keyAuthToken);
  }

  /// Save Firebase refresh token
  /// SECURITY: Refresh token used to get new ID tokens without re-authentication
  /// @param token - Firebase refresh token
  Future<void> saveRefreshToken(String token) async {
    _ensureInitialized();
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }

  /// Retrieve Firebase refresh token
  /// @returns Firebase refresh token or null if not found
  Future<String?> getRefreshToken() async {
    _ensureInitialized();
    return await _secureStorage.read(key: _keyRefreshToken);
  }

  /// Save user ID (Firebase UID)
  /// SECURITY: While UID is not secret, we store it securely for consistency
  /// @param uid - Firebase user UID
  Future<void> saveUserId(String uid) async {
    _ensureInitialized();
    await _secureStorage.write(key: _keyUserId, value: uid);
  }

  /// Retrieve user ID (Firebase UID)
  /// @returns Firebase UID or null if not found
  Future<String?> getUserId() async {
    _ensureInitialized();
    return await _secureStorage.read(key: _keyUserId);
  }

  // ==================== SHARED PREFERENCES (NON-SENSITIVE DATA) ====================
  // SECURITY: These methods use SharedPreferences for non-sensitive data only

  /// Save "Remember Me" preference
  /// SECURITY: This is a boolean flag, not sensitive data
  /// @param remember - true if user wants to stay logged in
  Future<void> saveRememberMe(bool remember) async {
    _ensureInitialized();
    await _preferences.setBool(_keyRememberMe, remember);
  }

  /// Get "Remember Me" preference
  /// @returns true if user enabled remember me, false otherwise
  bool getRememberMe() {
    _ensureInitialized();
    return _preferences.getBool(_keyRememberMe) ?? false;
  }

  /// Save last login timestamp
  /// SECURITY: Used for session timeout validation
  /// @param timestamp - DateTime of last login
  Future<void> saveLastLogin(DateTime timestamp) async {
    _ensureInitialized();
    await _preferences.setString(_keyLastLogin, timestamp.toIso8601String());
  }

  /// Get last login timestamp
  /// @returns DateTime of last login or null if never logged in
  DateTime? getLastLogin() {
    _ensureInitialized();
    final timeString = _preferences.getString(_keyLastLogin);
    if (timeString == null) return null;

    try {
      return DateTime.parse(timeString);
    } catch (e) {
      // SECURITY: If timestamp is corrupted, return null rather than crashing
      return null;
    }
  }

  /// Check if user session is still valid
  /// SECURITY: Validates session based on last login time and remember me setting
  /// @param sessionTimeoutMinutes - Session timeout in minutes (default 30)
  /// @returns true if session is valid, false if expired
  Future<bool> isSessionValid({int sessionTimeoutMinutes = 30}) async {
    _ensureInitialized();

    // Check if auth token exists
    final token = await getAuthToken();
    if (token == null) return false;

    // If "Remember Me" is enabled, session never expires
    final rememberMe = getRememberMe();
    if (rememberMe) return true;

    // Check if session has expired based on last login time
    final lastLogin = getLastLogin();
    if (lastLogin == null) return false;

    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    // SECURITY: Session expires after specified timeout
    return difference.inMinutes < sessionTimeoutMinutes;
  }

  /// Update last activity timestamp
  /// SECURITY: Call this on every authenticated API request to extend session
  Future<void> updateLastActivity() async {
    await saveLastLogin(DateTime.now());
  }

  // ==================== ✅ CRITICAL FIX #3: DASHBOARD CACHE ====================

  /// Save dashboard state to cache
  /// Uses secure storage with corruption handling
  /// @param state - Dashboard state as JSON map
  Future<void> saveDashboardState(Map<String, dynamic> state) async {
    _ensureInitialized();
    try {
      final jsonString = jsonEncode(state);
      await _secureStorage.write(key: _keyDashboardCache, value: jsonString);
      
      if (kDebugMode) {
        debugPrint('[StorageService] ✅ Dashboard state cached');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StorageService] ❌ Cache write failed: $e');
      }
      // Non-critical error - don't throw
    }
  }

  /// Load dashboard state from cache
  /// Returns null if cache doesn't exist or is corrupted
  /// @returns Dashboard state as JSON map or null
  Future<Map<String, dynamic>?> loadDashboardState() async {
    _ensureInitialized();
    try {
      final jsonString = await _secureStorage.read(key: _keyDashboardCache);
      if (jsonString == null) {
        if (kDebugMode) {
          debugPrint('[StorageService] ℹ️  No cached dashboard state');
        }
        return null;
      }
      
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (kDebugMode) {
        debugPrint('[StorageService] ✅ Dashboard state loaded from cache');
      }
      
      return decoded;
    } catch (e) {
      // Cache corrupted - delete it and return null
      if (kDebugMode) {
        debugPrint('[StorageService] ⚠️  Corrupt cache detected, clearing: $e');
      }
      await clearDashboardCache();
      return null;
    }
  }

  /// Clear dashboard cache
  /// Used when cache is corrupted or user logs out
  Future<void> clearDashboardCache() async {
    _ensureInitialized();
    try {
      await _secureStorage.delete(key: _keyDashboardCache);
      if (kDebugMode) {
        debugPrint('[StorageService] ✅ Dashboard cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[StorageService] ⚠️  Failed to clear cache: $e');
      }
    }
  }

  // ==================== SECURITY: CLEAR DATA ====================

  /// Clear all authentication data
  /// SECURITY: Call this on logout to ensure no sensitive data remains
  /// This is critical for preventing session hijacking
  Future<void> clearAuthData() async {
    _ensureInitialized();

    // Clear all sensitive data from secure storage
    await _secureStorage.delete(key: _keyAuthToken);
    await _secureStorage.delete(key: _keyRefreshToken);
    await _secureStorage.delete(key: _keyUserId);

    // Clear non-sensitive data from preferences
    await _preferences.remove(_keyRememberMe);
    await _preferences.remove(_keyLastLogin);
    
    // Clear dashboard cache on logout
    await clearDashboardCache();
  }

  /// Clear ALL stored data (for account deletion or reset)
  /// SECURITY: Nuclear option - removes everything
  Future<void> clearAllData() async {
    _ensureInitialized();

    // Clear all secure storage
    await _secureStorage.deleteAll();

    // Clear all preferences
    await _preferences.clear();
  }

  /// Check if user is logged in
  /// @returns true if auth token and user ID exist
  Future<bool> isLoggedIn() async {
    _ensureInitialized();
    final token = await getAuthToken();
    final userId = await getUserId();
    return token != null && userId != null;
  }

  // ==================== DEBUGGING (Development Only) ====================

  /// Print storage status for debugging
  /// SECURITY WARNING: NEVER call this in production!
  /// This is for development/testing only
  Future<void> debugPrintStorageStatus() async {
    if (!_initialized) return;

    debugPrint('📦 STORAGE DEBUG INFO:');
    debugPrint('   Auth Token: ${await getAuthToken() != null ? '***EXISTS***' : 'NOT SET'}');
    debugPrint('   Refresh Token: ${await getRefreshToken() != null ? '***EXISTS***' : 'NOT SET'}');
    debugPrint('   User ID: ${await getUserId() ?? 'NOT SET'}');
    debugPrint('   Remember Me: ${getRememberMe()}');
    debugPrint('   Last Login: ${getLastLogin()?.toString() ?? 'NEVER'}');
    debugPrint('   Session Valid: ${await isSessionValid()}');
    debugPrint('   Dashboard Cache: ${await loadDashboardState() != null ? 'EXISTS' : 'EMPTY'}');
  }
}