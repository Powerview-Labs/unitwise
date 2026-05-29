/// phone_utils.dart
///
/// Nigerian Phone Number Normalization Utility
///
/// SECURITY: Converts Nigerian local format to E.164 before any API call.
/// Users type: 09079361365
/// Backend receives: +2349079361365
///
/// This utility is the SINGLE source of truth for phone formatting in UnitWise.
/// All screens and services must use PhoneUtils.toE164() before API calls.

class PhoneUtils {
  // SECURITY: Nigeria-specific — app only supports Nigerian numbers
  static const String _nigeriaCountryCode = '+234';

  /// Normalizes a Nigerian phone number to E.164 format.
  ///
  /// Accepts ALL of these input formats:
  ///   08012345678      → +2348012345678  (local, leading 0)
  ///   8012345678       → +2348012345678  (10 digits, no leading 0)
  ///   +2348012345678   → +2348012345678  (already E.164 — returned as-is)
  ///   2348012345678    → +2348012345678  (E.164 without plus sign)
  ///
  /// Returns null if the number cannot be recognized as a valid Nigerian number.
  /// NEVER throws — always returns null on invalid input.
  static String? toE164(String rawPhone) {
    if (rawPhone.isEmpty) return null;

    // Remove all whitespace and dashes
    final phone = rawPhone.trim().replaceAll(RegExp(r'[\s\-]'), '');

    // Already correct E.164 format (+234 + 10 digits = 14 chars)
    if (phone.startsWith('+234') && phone.length == 14) {
      return phone;
    }

    // E.164 without plus sign (234XXXXXXXXXX = 13 chars)
    if (phone.startsWith('234') && phone.length == 13) {
      return '+$phone';
    }

    // Local Nigerian format: starts with 0, 11 digits total (0XXXXXXXXXX)
    if (phone.startsWith('0') && phone.length == 11) {
      return '$_nigeriaCountryCode${phone.substring(1)}';
    }

    // 10 digits without leading 0 (XXXXXXXXXX)
    if (!phone.startsWith('+') && !phone.startsWith('0') && phone.length == 10) {
      return '$_nigeriaCountryCode$phone';
    }

    // Unrecognized format
    return null;
  }

  /// Returns true if the phone can be normalized to a valid Nigerian E.164 number.
  static bool isValidNigerianPhone(String rawPhone) {
    return toE164(rawPhone) != null;
  }

  /// Converts E.164 back to local display format for UI.
  ///
  /// +2348012345678 → 08012345678
  ///
  /// IMPORTANT: Use this for DISPLAY ONLY — never pass this to APIs.
  static String toDisplayFormat(String phone) {
    if (phone.startsWith('+234') && phone.length == 14) {
      return '0${phone.substring(4)}';
    }
    return phone; // Return as-is if not recognizable
  }

  /// Masks a phone number for safe logging.
  ///
  /// +2349079361365 → +234*******365
  ///
  /// SECURITY: Use this in all log statements — never log raw phone numbers.
  static String maskForLog(String phone) {
    if (phone.length < 6) return '***';
    final visible = phone.substring(phone.length - 3);
    final masked = '*' * (phone.length - 3);
    return '${phone.substring(0, 4)}$masked$visible';
  }
}
