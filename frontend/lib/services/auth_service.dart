import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Auth Service - Firebase Phone Authentication
///
/// PRODUCTION-READY: Uses Firebase Phone Auth instead of Twilio
/// - Automatic SMS sending
/// - Built-in rate limiting
/// - Free tier: 10,000 verifications/month
///
/// BUG FIX: sendOtp now uses a Completer instead of a fixed 2-second delay.
/// The old approach threw "Failed to send OTP" on the first attempt because
/// Firebase's reCAPTCHA initialisation takes longer than 2 seconds cold.
/// The Completer waits until codeSent OR verificationFailed actually fires,
/// so the result is always correct on the very first tap.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int? _resendToken;

  /// Send OTP via Firebase Phone Auth
  ///
  /// Parameters:
  /// - phoneNumber: Nigerian local format (08012345678) or E.164 (+2348012345678)
  /// - name / email: unused by Firebase Phone Auth, kept for API compatibility
  ///
  /// Returns: Map with success status and verificationId / error message
  Future<Map<String, dynamic>> sendOtp(
    String phoneNumber, {
    String? name,
    String? email,
  }) async {
    try {
      if (kDebugMode) print('🔵 [AuthService] Sending OTP to $phoneNumber');

      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+234${phoneNumber.replaceFirst('0', '')}';

      if (kDebugMode) print('🔵 [AuthService] Formatted phone: $formattedPhone');

      // ✅ FIX: Completer resolves as soon as codeSent or verificationFailed
      // fires — no more guessing with a fixed delay.
      final completer = Completer<Map<String, dynamic>>();

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,

        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android silent sign-in — don't complete the flow here,
          // let the OTP screen drive navigation as normal.
          if (kDebugMode) print('✅ [AuthService] Auto-verification completed');
        },

        verificationFailed: (FirebaseAuthException e) {
          if (kDebugMode) print('❌ [AuthService] Verification failed: ${e.message}');
          if (!completer.isCompleted) {
            completer.complete({
              'success': false,
              'error': e.code,
              'message': _getFriendlyError(e.code),
            });
          }
        },

        codeSent: (String verificationId, int? resendToken) {
          if (kDebugMode) print('✅ [AuthService] OTP sent, verificationId: $verificationId');
          _resendToken = resendToken;
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'verificationId': verificationId,
              'sessionId': verificationId,
              'message': 'OTP sent successfully',
            });
          }
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          if (kDebugMode) print('⏱️ [AuthService] Auto-retrieval timeout');
          // Only complete if neither codeSent nor verificationFailed fired yet
          if (!completer.isCompleted) {
            completer.complete({
              'success': true,
              'verificationId': verificationId,
              'sessionId': verificationId,
              'message': 'OTP sent successfully',
            });
          }
        },
      );

      // Wait for the first callback to fire.
      // 90s safety net handles complete network failure.
      return await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          if (kDebugMode) print('❌ [AuthService] sendOtp timed out');
          return {
            'success': false,
            'error': 'timeout',
            'message': 'Request timed out. Please check your connection and try again.',
          };
        },
      );
    } catch (e) {
      if (kDebugMode) print('❌ [AuthService] sendOtp error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to send OTP. Please try again.',
      };
    }
  }

  /// Verify OTP code entered by the user
  Future<Map<String, dynamic>> verifyOtp(
    String verificationId,
    String otpCode,
    String phoneNumber,
  ) async {
    try {
      if (kDebugMode) print('🔵 [AuthService] Verifying OTP: $otpCode');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) {
        print('✅ [AuthService] OTP verified, user: ${userCredential.user?.uid}');
      }

      return {
        'success': true,
        'user': userCredential.user,
        'sessionId': verificationId,
        'message': 'OTP verified successfully',
      };
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) print('❌ [AuthService] Verification failed: ${e.message}');
      return {
        'success': false,
        'error': e.code,
        'message': _getFriendlyVerifyError(e.code),
      };
    } catch (e) {
      if (kDebugMode) print('❌ [AuthService] verifyOtp error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Verification failed. Please try again.',
      };
    }
  }

  /// Login: checks user exists in Firestore, then sends OTP
  Future<Map<String, dynamic>> loginWithPassword(
    String phoneNumber,
    String password,
  ) async {
    try {
      if (kDebugMode) print('🔵 [AuthService] Login attempt for $phoneNumber');

      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+234${phoneNumber.replaceFirst('0', '')}';

      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: formattedPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No account found with this phone number.',
        };
      }

      return await sendOtp(phoneNumber);
    } catch (e) {
      if (kDebugMode) print('❌ [AuthService] Login error: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Login failed. Please try again.',
      };
    }
  }

  /// No-op — Firebase Phone Auth doesn't use passwords
  Future<Map<String, dynamic>> setPasswordForUser(
    String phoneNumber,
    String password,
  ) async {
    return {'success': true, 'message': 'Password set successfully'};
  }

  /// No-op — just sends an OTP for re-verification
  Future<Map<String, dynamic>> resetPasswordRequest(
    String phoneNumber,
    String action,
  ) async {
    try {
      return await sendOtp(phoneNumber);
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to send reset code.',
      };
    }
  }

  /// No-op — Firebase persists sessions by default
  Future<void> setRememberMe(bool rememberMe) async {}

  Future<void> signOut() async => _auth.signOut();

  User? getCurrentUser() => _auth.currentUser;

  bool isSignedIn() => _auth.currentUser != null;

  // ── HELPERS ──────────────────────────────────────────────────────────────

  String _getFriendlyError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorised. Please contact support.';
      default:
        return 'Could not send OTP. Please check your number and try again.';
    }
  }

  String _getFriendlyVerifyError(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Incorrect code. Please check and try again.';
      case 'session-expired':
        return 'Code expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Verification failed. Please try again.';
    }
  }
}