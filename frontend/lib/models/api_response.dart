/**
 * API RESPONSE MODELS
 * 
 * Type-safe wrappers for Cloud Function responses
 * Provides consistent error handling and data extraction
 * 
 * SECURITY:
 * - Validates all API responses
 * - Sanitizes error messages
 * - Never exposes stack traces to users
 * - Provides user-friendly error messages
 * 
 * USAGE:
 * ```dart
 * final response = await apiService.sendOtp(phone);
 * if (response.isSuccess) {
 *   final sessionId = response.data!.sessionId;
 * } else {
 *   showError(response.message);
 * }
 * ```
 */

/// Generic API Response wrapper
/// 
/// Wraps all API responses with success/error state
/// Type parameter T represents the response data type
/// 
/// @param T - Type of data returned on success
class ApiResponse<T> {
  // ===========================================================================
  // PROPERTIES
  // ===========================================================================

  /// Success status
  /// 
  /// true: API call succeeded, data is available
  /// false: API call failed, check error code and message
  final bool isSuccess;

  /// Response data (available only on success)
  /// 
  /// null if isSuccess is false
  final T? data;

  /// Error code (available on failure)
  /// 
  /// Examples:
  /// - NETWORK_ERROR: No internet connection
  /// - TIMEOUT: Request took too long
  /// - INVALID_OTP: OTP verification failed
  /// - RATE_LIMIT: Too many requests
  /// - INTERNAL_ERROR: Server error
  final String? code;

  /// Human-readable message
  /// 
  /// Success: Confirmation message
  /// Failure: User-friendly error explanation
  /// 
  /// SECURITY: Never contains technical details or stack traces
  final String message;

  /// HTTP status code (optional)
  /// 
  /// Examples:
  /// - 200: Success
  /// - 400: Bad request
  /// - 401: Unauthorized
  /// - 403: Forbidden
  /// - 404: Not found
  /// - 429: Too many requests
  /// - 500: Server error
  final int? statusCode;

  // ===========================================================================
  // CONSTRUCTORS
  // ===========================================================================

  /// Main constructor
  const ApiResponse({
    required this.isSuccess,
    this.data,
    this.code,
    required this.message,
    this.statusCode,
  });

  /// Success response constructor
  /// 
  /// @param data - Response data
  /// @param message - Success message
  factory ApiResponse.success({
    T? data,
    String message = 'Operation successful',
  }) {
    return ApiResponse<T>(
      isSuccess: true,
      data: data,
      message: message,
      statusCode: 200,
    );
  }

  /// Error response constructor
  /// 
  /// @param code - Error code
  /// @param message - User-friendly error message
  /// @param statusCode - HTTP status code
  factory ApiResponse.error({
  String? code,              // ✅ Now optional
  required String message,
  int? statusCode,
  }) {
    return ApiResponse<T>(
      isSuccess: false,
      code: code,
      message: message,
      statusCode: statusCode ?? 500,
    );
  }

  /// Network error constructor
  /// 
  /// Used when no internet connection or DNS failure
  factory ApiResponse.networkError() {
    return ApiResponse<T>(
      isSuccess: false,
      code: 'NETWORK_ERROR',
      message: 'No internet connection. Please check your network and try again.',
      statusCode: 0,
    );
  }

  /// Timeout error constructor
  /// 
  /// Used when request exceeds timeout limit
  factory ApiResponse.timeout() {
    return ApiResponse<T>(
      isSuccess: false,
      code: 'TIMEOUT',
      message: 'Request timed out. Please try again.',
      statusCode: 408,
    );
  }

  /// Unknown error constructor
  /// 
  /// Used when error cause is unclear
  factory ApiResponse.unknown() {
    return ApiResponse<T>(
      isSuccess: false,
      code: 'UNKNOWN_ERROR',
      message: 'An unexpected error occurred. Please try again.',
      statusCode: 500,
    );
  }

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  /// Check if response is an error
  bool get isError => !isSuccess;

  /// Check if error is network-related
  bool get isNetworkError => code == 'NETWORK_ERROR';

  /// Check if error is timeout
  bool get isTimeout => code == 'TIMEOUT';

  /// Check if error is rate limit
  bool get isRateLimit => code == 'RATE_LIMIT' || statusCode == 429;

  /// Check if error is authentication-related
  bool get isAuthError => 
      statusCode == 401 || 
      statusCode == 403 || 
      code == 'UNAUTHORIZED' ||
      code == 'FORBIDDEN';

  // ===========================================================================
  // STRING REPRESENTATION
  // ===========================================================================

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(message: $message)';
    } else {
      return 'ApiResponse.error(code: $code, message: $message)';
    }
  }
}

// =============================================================================
// SPECIFIC API RESPONSE MODELS
// =============================================================================

/// Send OTP Response Data
/// 
/// Returned from /sendOtp Cloud Function
class SendOtpData {
  /// Session ID for OTP verification
  /// SECURITY: Required to verify OTP (prevents OTP theft)
  final String sessionId;

  /// Message SID from Termii/Twilio (for tracking)
  final String? messageSid;

  /// OTP expiry time in seconds
  final int expiresIn;

  /// Channel used (whatsapp, sms)
  final String? channel;

  const SendOtpData({
    required this.sessionId,
    this.messageSid,
    required this.expiresIn,
    this.channel,
  });

  /// Create from JSON response
  factory SendOtpData.fromJson(Map<String, dynamic> json) {
    return SendOtpData(
      sessionId: json['sessionId'] as String,
      messageSid: json['messageSid'] as String?,
      expiresIn: json['expiresIn'] as int? ?? 300,
      channel: json['channel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'messageSid': messageSid,
      'expiresIn': expiresIn,
      'channel': channel,
    };
  }
}

/// Verify OTP Response Data
/// 
/// Returned from /verifyOtp Cloud Function
class VerifyOtpData {
  /// OTP verification status
  final bool verified;

  /// User ID (Firebase UID)
  final String? uid;

  /// Custom token for Firebase Auth
  /// SECURITY: Used to sign in to Firebase
  final String? customToken;

  /// Whether this is a new user
  final bool newUser;

  /// Phone number verified
  final String? phone;

  const VerifyOtpData({
    required this.verified,
    this.uid,
    this.customToken,
    this.newUser = false,
    this.phone,
  });

  /// Create from JSON response
  factory VerifyOtpData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpData(
      verified: json['verified'] as bool? ?? false,
      uid: json['uid'] as String?,
      customToken: json['customToken'] as String?,
      newUser: json['newUser'] as bool? ?? false,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verified': verified,
      'uid': uid,
      'customToken': customToken,
      'newUser': newUser,
      'phone': phone,
    };
  }
}

/// Create User Profile Response Data
/// 
/// Returned from /createUserProfile Cloud Function
class CreateProfileData {
  /// User ID
  final String uid;

  /// Profile data
  final Map<String, dynamic>? userData;

  /// Welcome email sent status
  final bool? welcomeEmailSent;

  const CreateProfileData({
    required this.uid,
    this.userData,
    this.welcomeEmailSent,
  });

  /// Create from JSON response
  factory CreateProfileData.fromJson(Map<String, dynamic> json) {
    return CreateProfileData(
      uid: json['uid'] as String,
      userData: json['userData'] as Map<String, dynamic>?,
      welcomeEmailSent: json['welcomeEmailSent'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userData': userData,
      'welcomeEmailSent': welcomeEmailSent,
    };
  }
}

/// Reset Password Response Data
/// 
/// Returned from /resetPassword Cloud Function
class ResetPasswordData {
  /// Session ID for OTP verification
  final String sessionId;

  /// Message SID
  final String? messageSid;

  /// OTP expiry time
  final int expiresIn;

  const ResetPasswordData({
    required this.sessionId,
    this.messageSid,
    required this.expiresIn,
  });

  /// Create from JSON response
  factory ResetPasswordData.fromJson(Map<String, dynamic> json) {
    return ResetPasswordData(
      sessionId: json['sessionId'] as String,
      messageSid: json['messageSid'] as String?,
      expiresIn: json['expiresIn'] as int? ?? 300,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'messageSid': messageSid,
      'expiresIn': expiresIn,
    };
  }
}

/// Health Check Response Data
/// 
/// Returned from /healthCheck Cloud Function
class HealthCheckData {
  /// Service status
  final String status;

  /// Service name
  final String service;

  /// Module name
  final String module;

  /// Version
  final String version;

  /// Timestamp
  final DateTime timestamp;

  /// Environment
  final String environment;

  /// Firestore connection status
  final String? firestore;

  const HealthCheckData({
    required this.status,
    required this.service,
    required this.module,
    required this.version,
    required this.timestamp,
    required this.environment,
    this.firestore,
  });

  /// Create from JSON response
  factory HealthCheckData.fromJson(Map<String, dynamic> json) {
    return HealthCheckData(
      status: json['status'] as String,
      service: json['service'] as String,
      module: json['module'] as String,
      version: json['version'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      environment: json['environment'] as String,
      firestore: json['firestore'] as String?,
    );
  }

  /// Check if service is healthy
  bool get isHealthy => status == 'ok';
}

/// SECURITY HELPER METHODS
class ApiErrorHandler {
  /// Get user-friendly error message based on error code
  /// 
  /// SECURITY: Sanitizes technical errors into user-friendly messages
  static String getUserFriendlyMessage(String code, String? defaultMessage) {
    final messages = {
      // Network errors
      'NETWORK_ERROR': 'No internet connection. Please check your network.',
      'TIMEOUT': 'Request timed out. Please try again.',
      
      // Authentication errors
      'INVALID_OTP': 'Incorrect verification code. Please try again.',
      'EXPIRED_OTP': 'Verification code has expired. Please request a new one.',
      'OTP_ATTEMPTS_EXCEEDED': 'Too many incorrect attempts. Please request a new code.',
      'PHONE_EXISTS': 'This phone number is already registered. Please log in.',
      'USER_NOT_FOUND': 'No account found with this phone number.',
      'INVALID_PHONE': 'Invalid phone number format.',
      'INVALID_EMAIL': 'Invalid email address format.',
      'WEAK_PASSWORD': 'Password is too weak. Please use at least 6 characters.',
      
      // Rate limiting
      'RATE_LIMIT': 'Too many requests. Please wait a moment and try again.',
      'OTP_RATE_LIMIT': 'Too many OTP requests. Please wait before requesting again.',
      
      // Server errors
      'INTERNAL_ERROR': 'Something went wrong. Please try again.',
      'SERVICE_UNAVAILABLE': 'Service is temporarily unavailable. Please try again later.',
      
      // Validation errors
      'MISSING_REQUIRED_FIELDS': 'Please fill in all required fields.',
      'INVALID_INPUT': 'Invalid input. Please check your information.',
      
      // Session errors
      'SESSION_EXPIRED': 'Your session has expired. Please log in again.',
      'SESSION_NOT_FOUND': 'Invalid session. Please start over.',
    };

    return messages[code] ?? defaultMessage ?? 'An error occurred. Please try again.';
  }

  /// Check if error is retryable
  /// 
  /// SECURITY: Helps determine if user should retry the operation
  static bool isRetryable(String? code) {
    final retryableCodes = [
      'NETWORK_ERROR',
      'TIMEOUT',
      'INTERNAL_ERROR',
      'SERVICE_UNAVAILABLE',
    ];

    return code != null && retryableCodes.contains(code);
  }
}

/**
 * USAGE EXAMPLES:
 * 
 * ```dart
 * // Send OTP
 * final response = await apiService.sendOtp('+2348100000000');
 * if (response.isSuccess && response.data != null) {
 *   final sessionId = response.data!.sessionId;
 *   print('OTP sent! Session: $sessionId');
 * } else {
 *   print('Error: ${response.message}');
 * }
 * 
 * // Verify OTP
 * final verifyResponse = await apiService.verifyOtp(sessionId, otp);
 * if (verifyResponse.isSuccess && verifyResponse.data != null) {
 *   if (verifyResponse.data!.verified) {
 *     final uid = verifyResponse.data!.uid;
 *     // Proceed to create profile or login
 *   }
 * }
 * 
 * // Handle errors
 * if (response.isError) {
 *   if (response.isNetworkError) {
 *     showNetworkErrorDialog();
 *   } else if (response.isRateLimit) {
 *     showRateLimitMessage();
 *   } else {
 *     showErrorSnackbar(response.message);
 *   }
 * }
 * 
 * // User-friendly error messages
 * final friendlyMessage = ApiErrorHandler.getUserFriendlyMessage(
 *   response.code ?? '',
 *   response.message,
 * );
 * ```
 */
