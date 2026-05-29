/// validators.dart
///
/// Security-first input validators for UnitWise
/// All validators follow OWASP Input Validation guidelines
///
/// BUG FIX APPLIED:
///   ✅ BUG 3 — validatePhone() updated to accept Nigerian local format.
///              Previously required E.164 (+234...) causing "phone number must
///              be in E.164 format" error on the signup screen.
///              Now accepts: 08012345678, 09012345678, 07012345678 (local)
///              AND still accepts: +2348012345678 (E.164 — unchanged)
///              Normalization to E.164 for API calls happens in AuthService
///              via PhoneUtils.toE164() — NOT in this validator.
///
/// ALL OTHER VALIDATORS: Preserved exactly from original file.
///
/// SECURITY PRINCIPLES:
/// 1. Never trust client input
/// 2. Whitelist validation (allow only known-good)
/// 3. Enforce strict type, format, and length constraints
/// 4. Sanitize all inputs before processing

library;

class Validators {
  Validators._();

  /// Validates full name
  /// SECURITY: Only allows letters, spaces, hyphens, and apostrophes
  /// Prevents: Numbers, special characters, SQL injection attempts
  /// Min: 2 characters, Max: 50 characters
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }

    final trimmed = value.trim();

    // SECURITY: Enforce minimum length
    if (trimmed.length < 2) {
      return 'Name must be at least 2 characters';
    }

    // SECURITY: Enforce maximum length (prevent buffer overflow attacks)
    if (trimmed.length > 50) {
      return 'Name must not exceed 50 characters';
    }

    // SECURITY: Whitelist validation - only allow letters, spaces, hyphens, apostrophes
    // This prevents: numbers, special characters, SQL injection, XSS attempts
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    // SECURITY: Ensure name doesn't consist only of spaces/special chars
    if (trimmed.replaceAll(RegExp(r"[\s\-']"), '').isEmpty) {
      return 'Please enter a valid name';
    }

    return null;
  }

  /// Validates email address
  /// SECURITY: RFC 5322 compliant email validation
  /// Prevents: Invalid emails, SQL injection, XSS attacks
  /// Max: 254 characters (RFC limit)
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional in signup
    }

    final trimmed = value.trim();

    // SECURITY: Enforce RFC 5322 maximum email length
    if (trimmed.length > 254) {
      return 'Email address is too long';
    }

    // SECURITY: Whitelist validation with strict RFC-compliant regex
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    // SECURITY: Additional checks for common attack patterns
    if (trimmed.contains('..') || trimmed.startsWith('.') || trimmed.endsWith('.')) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// ✅ BUG 3 FIX — Validates Nigerian phone numbers in LOCAL or E.164 format.
  ///
  /// BEFORE (caused Bug 3): Only accepted +234... format, rejecting local input.
  /// AFTER: Accepts Nigerian local format (08012345678) AND E.164 (+2348012345678).
  ///
  /// Users type: 08012345678, 09012345678, 07012345678
  /// Validator accepts it — no error shown.
  /// AuthService then normalizes to E.164 internally before sending to backend.
  ///
  /// SECURITY: Whitelist validation — only known Nigerian prefix patterns.
  /// SECURITY: Exact length enforced — 11 digits local, 14 chars E.164.
  /// SECURITY: Nigerian mobile prefix validation (07x, 08x, 09x only).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final trimmed = value.trim();

    // SECURITY: Remove formatting characters before validation
    final cleaned = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // SECURITY: Whitelist — only digits and + allowed
    if (!RegExp(r'^[\d+]+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits';
    }

    // ✅ BUG 3 FIX: Accept Nigerian LOCAL format (0XXXXXXXXXX — 11 digits)
    // Covers all valid Nigerian mobile prefixes: 070, 080, 081, 090, 091 etc.
    final localRegex = RegExp(r'^0[789][01]\d{8}$');
    if (localRegex.hasMatch(cleaned)) {
      return null; // ✅ Valid local format — no error
    }

    // Accept E.164 Nigerian format (+234XXXXXXXXXX — 14 chars)
    final e164Regex = RegExp(r'^\+234[789][01]\d{8}$');
    if (e164Regex.hasMatch(cleaned)) {
      return null; // ✅ Valid E.164 format — no error
    }

    // Accept E.164 without plus (234XXXXXXXXXX — 13 chars)
    final e164NoPlusRegex = RegExp(r'^234[789][01]\d{8}$');
    if (e164NoPlusRegex.hasMatch(cleaned)) {
      return null; // ✅ Valid — no error
    }

    // SECURITY: Provide a clear, user-friendly error for Nigerian users
    return 'Enter a valid Nigerian phone number (e.g. 08012345678)';
  }

  /// Validates Nigerian phone numbers (alternative method name for consistency)
  static String? validatePhoneNumber(String? value) {
    return validatePhone(value);
  }

  /// Validates password strength
  /// SECURITY: Enforces OWASP password requirements
  /// CRITICAL: Minimum 8 characters (OWASP standard)
  /// Requirements:
  /// - At least 8 characters (OWASP minimum)
  /// - At least one uppercase letter
  /// - At least one lowercase letter
  /// - At least one number
  /// - At least one special character (optional but recommended)
  static String? validatePassword(String? value, {bool requireStrong = false}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // SECURITY: Enforce minimum length of 8 characters (OWASP recommendation)
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // SECURITY: Enforce maximum length (prevent DoS attacks via bcrypt)
    if (value.length > 128) {
      return 'Password must not exceed 128 characters';
    }

    // SECURITY: Check for uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // SECURITY: Check for lowercase letter
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // SECURITY: Check for number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // SECURITY: For strong passwords, require special character
    if (requireStrong && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }

    // SECURITY: Prevent common weak passwords
    final commonPasswords = [
      'password', 'password123', '12345678', 'qwerty123',
      'abc123456', 'password1', '123456789', 'qwerty12'
    ];

    if (commonPasswords.contains(value.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }

    return null;
  }

  /// Validates password confirmation match
  /// SECURITY: Ensures passwords match exactly (prevents typos)
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    // SECURITY: Compare passwords (case-sensitive)
    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates OTP code
  /// SECURITY: Strict 6-digit numeric validation
  /// Prevents: Non-numeric input, wrong length, injection attempts
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP code is required';
    }

    final trimmed = value.trim();

    // SECURITY: Whitelist validation - only allow exactly 6 digits
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'OTP must be exactly 6 digits';
    }

    return null;
  }

  /// Validates meter number
  /// SECURITY: Format validation for Nigerian meter numbers
  /// Prevents: Invalid formats, SQL injection
  static String? validateMeterNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Meter number is required';
    }

    final trimmed = value.trim();

    // SECURITY: Enforce length constraints
    if (trimmed.length < 10 || trimmed.length > 13) {
      return 'Meter number must be between 10-13 characters';
    }

    // SECURITY: Whitelist validation - only alphanumeric
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(trimmed)) {
      return 'Meter number can only contain letters and numbers';
    }

    return null;
  }

  /// Validates token purchase amount
  /// SECURITY: Numeric validation with reasonable limits
  /// Prevents: Negative numbers, excessive amounts, injection
  static String? validateTokenAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }

    final trimmed = value.trim();

    // SECURITY: Whitelist validation - only digits and optional decimal point
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmed)) {
      return 'Please enter a valid amount';
    }

    final amount = double.tryParse(trimmed);

    // SECURITY: Validate range (prevent negative or excessive amounts)
    if (amount == null || amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 1000000) {
      return 'Amount cannot exceed ₦1,000,000';
    }

    return null;
  }

  /// Sanitizes user input for display
  /// SECURITY: Prevents XSS attacks by escaping HTML entities
  static String sanitizeForDisplay(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Validates generic text input with length constraints
  /// SECURITY: General-purpose validation with XSS prevention
  static String? validateTextInput(
    String? value, {
    required String fieldName,
    int minLength = 1,
    int maxLength = 255,
    bool required = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      if (required) {
        return '$fieldName is required';
      }
      return null;
    }

    final trimmed = value.trim();

    // SECURITY: Enforce length constraints
    if (trimmed.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    if (trimmed.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }

    return null;
  }
}