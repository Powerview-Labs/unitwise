/// Firebase Configuration for UnitWise
/// 
/// SECURITY: Firebase credentials are public (client-side)
/// Backend security is enforced via Firestore rules and Cloud Functions
library;

class FirebaseConfig {
  // Firebase Project ID
  static const String projectId = 'unitwise-83a71';
  
  // Cloud Functions Region
  static const String functionsRegion = 'us-central1';
  
  // Cloud Functions Base URL
  static String get functionsBaseUrl {
    // Use emulator in debug mode
    const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
    
    if (isDebug) {
      // Local emulator
      return 'http://10.0.2.2:5001/$projectId/$functionsRegion';
    } else {
      // Production
      return 'https://$functionsRegion-$projectId.cloudfunctions.net';
    }
  }
  
  // Function endpoints
  static const String sendOtpEndpoint = 'sendOtp';
  static const String verifyOtpEndpoint = 'verifyOtp';
  static const String createUserProfileEndpoint = 'createUserProfile';
  static const String resetPasswordEndpoint = 'resetPassword';
  static const String healthCheckEndpoint = 'healthCheck';
}
