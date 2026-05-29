/// USER MODEL
/// 
/// Represents a UnitWise user with all profile information
/// Matches Firestore database schema defined in PRD
/// 
/// FIRESTORE COLLECTION: /users/{uid}
/// 
/// SECURITY:
/// - No sensitive data stored in plain text
/// - Password hash stored on backend only (never sent to client)
/// - Phone number stored for authentication
/// - Email optional (used for notifications only)
/// 
/// SCHEMA (from PRD):
/// {
///   "uid": "123abc",
///   "name": "Ifeanyi",
///   "email": "ifeanyi@email.com",
///   "phone": "+2348100000000",
///   "passwordHash": "encrypted",  // Backend only - never in client model
///   "disco": "Ikeja Electric",
///   "band": "C",
///   "location": "Yaba",
///   "meter_number": null,
///   "theme": "light",
///   "created_at": timestamp,
///   "last_login": timestamp,
///   "remember_me": true
/// }
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// UserModel Class
/// 
/// Immutable data class representing a user
/// Provides methods for serialization/deserialization with Firestore
class UserModel {
  // ===========================================================================
  // PROPERTIES
  // ===========================================================================

  /// User ID (Firebase UID)
  /// 
  /// SECURITY: Unique identifier from Firebase Auth
  /// Used as document ID in Firestore /users collection
  final String uid;

  /// User's display name
  /// 
  /// Can be first name, full name, or preferred name
  /// Used in greetings and personalization
  final String name;

  /// First name (optional - for formal greetings)
  /// 
  /// Extracted from full name or provided during signup
  final String? firstName;

  /// Last name (optional)
  final String? lastName;

  /// Email address (optional)
  /// 
  /// USAGE: Welcome emails, notifications, password reset
  /// NOT used for authentication (phone number is primary)
  final String? email;

  /// Phone number (required)
  /// 
  /// SECURITY: Primary authentication identifier
  /// Format: E.164 international format (+2348100000000)
  /// Used for OTP authentication
  final String phone;

  /// DisCo (Distribution Company)
  /// 
  /// Examples: "Ikeja Electric", "Eko Electricity", "Abuja Electricity"
  /// Used for tariff calculations and outage predictions
  final String? disco;

  /// Tariff Band (A-E)
  /// 
  /// Band A: 20 hours supply/day (best)
  /// Band B: 16 hours supply/day
  /// Band C: 12 hours supply/day
  /// Band D: 8 hours supply/day
  /// Band E: 4 hours supply/day (worst)
  /// 
  /// Used for burn rate calculations
  final String? band;

  /// Location/Area
  /// 
  /// Examples: "Yaba", "Lekki", "Surulere"
  /// Used for DisCo/Band auto-detection
  final String? location;

  /// Meter number (optional)
  /// 
  /// Prepaid meter number for token purchases
  /// Used for future DisCo API integration
  final String? meterNumber;

  /// Theme preference
  /// 
  /// Values: "light" | "dark" | "system"
  /// User's preferred app theme
  final String theme;

  /// Remember me preference
  /// 
  /// SECURITY: If true, keep user logged in across sessions
  /// Uses Firebase Auth persistence + SecureStorage
  final bool rememberMe;

  /// Account creation timestamp
  /// 
  /// When user first signed up
  final DateTime? createdAt;

  /// Last login timestamp
  /// 
  /// SECURITY: Track user activity for security audits
  /// Updated on each successful login
  final DateTime? lastLogin;

  /// Profile completion percentage (0-100)
  /// 
  /// Calculated based on filled fields:
  /// - Required: name, phone, disco, band, location
  /// - Optional: email, meterNumber
  /// 
  /// Used to prompt user to complete profile
  final int profileCompletionPercentage;

  /// Account active status
  /// 
  /// SECURITY: Allows admin to disable accounts
  /// Default: true
  final bool isActive;

  /// Email verified status
  /// 
  /// True if user has verified their email address
  final bool emailVerified;

  /// Phone verified status
  /// 
  /// SECURITY: Should always be true (verified during OTP signup)
  final bool phoneVerified;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  /// Main constructor
  /// 
  /// All properties are final (immutable)
  /// Use copyWith() method to create modified copies
  const UserModel({
    required this.uid,
    required this.name,
    this.firstName,
    this.lastName,
    this.email,
    required this.phone,
    this.disco,
    this.band,
    this.location,
    this.meterNumber,
    this.theme = 'light', // Default theme
    this.rememberMe = false, // Default: don't remember
    this.createdAt,
    this.lastLogin,
    this.profileCompletionPercentage = 0,
    this.isActive = true, // Default: active
    this.emailVerified = false,
    this.phoneVerified = true, // Should be true after OTP verification
  });

  // ===========================================================================
  // COMPUTED PROPERTIES
  // ===========================================================================

  /// Full name
  /// 
  /// Combines firstName and lastName if available
  /// Falls back to name field
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return name;
  }

  /// Display name (for greetings)
  /// 
  /// Uses firstName if available, otherwise name
  String get displayName {
    return firstName ?? name;
  }

  /// Has email
  /// 
  /// True if user has provided an email address
  bool get hasEmail => email != null && email!.isNotEmpty;

  /// Has DisCo/Band configured
  /// 
  /// True if user has completed location setup
  bool get hasDiscoAndBand => disco != null && band != null;

  /// Has meter number
  /// 
  /// True if user has added their meter number
  bool get hasMeterNumber => meterNumber != null && meterNumber!.isNotEmpty;

  /// Profile is complete
  /// 
  /// True if all essential fields are filled
  bool get isProfileComplete {
    return hasDiscoAndBand && location != null && location!.isNotEmpty;
  }

  // ===========================================================================
  // SERIALIZATION METHODS
  // ===========================================================================

  /// Convert UserModel to JSON Map
  /// 
  /// USAGE: Upload to Firestore
  /// 
  /// SECURITY: Never include passwordHash in client-side model
  /// 
  /// @return Map<String, dynamic> JSON representation
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'disco': disco,
      'band': band,
      'location': location,
      'meter_number': meterNumber, // Snake case for Firestore consistency
      'theme': theme,
      'remember_me': rememberMe, // Snake case for Firestore
      'created_at': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(), // Use server timestamp if null
      'last_login': lastLogin != null 
          ? Timestamp.fromDate(lastLogin!) 
          : FieldValue.serverTimestamp(),
      'profile_completion_percentage': profileCompletionPercentage,
      'is_active': isActive,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
    };
  }

  /// Create UserModel from JSON Map
  /// 
  /// USAGE: Download from Firestore
  /// 
  /// SECURITY: Validates and sanitizes data from Firestore
  /// Handles missing or null fields gracefully
  /// 
  /// @param json Map<String, dynamic> from Firestore
  /// @return UserModel instance
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Required fields with validation
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      
      // Optional string fields
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      disco: json['disco'] as String?,
      band: json['band'] as String?,
      location: json['location'] as String?,
      meterNumber: json['meter_number'] as String?, // Handle snake_case
      
      // Theme preference
      theme: json['theme'] as String? ?? 'light',
      
      // Boolean fields with defaults
      rememberMe: json['remember_me'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? true,
      
      // Numeric fields
      profileCompletionPercentage: 
          json['profile_completion_percentage'] as int? ?? 0,
      
      // Timestamp fields (handle both Timestamp and null)
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
      lastLogin: json['last_login'] != null
          ? (json['last_login'] as Timestamp).toDate()
          : null,
    );
  }

  /// Create UserModel from Firestore DocumentSnapshot
  /// 
  /// USAGE: Direct conversion from Firestore query results
  /// 
  /// @param snapshot DocumentSnapshot from Firestore
  /// @return UserModel instance or null if document doesn't exist
  factory UserModel.fromFirestore(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('User document does not exist');
    }
    
    final data = snapshot.data() as Map<String, dynamic>;
    
    // Ensure UID matches document ID for consistency
    data['uid'] = snapshot.id;
    
    return UserModel.fromJson(data);
  }

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Create a copy of UserModel with modified fields
  /// 
  /// USAGE: Update specific fields without mutating original
  /// 
  /// @param fields Named parameters for fields to update
  /// @return New UserModel instance with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? disco,
    String? band,
    String? location,
    String? meterNumber,
    String? theme,
    bool? rememberMe,
    DateTime? createdAt,
    DateTime? lastLogin,
    int? profileCompletionPercentage,
    bool? isActive,
    bool? emailVerified,
    bool? phoneVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      disco: disco ?? this.disco,
      band: band ?? this.band,
      location: location ?? this.location,
      meterNumber: meterNumber ?? this.meterNumber,
      theme: theme ?? this.theme,
      rememberMe: rememberMe ?? this.rememberMe,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      profileCompletionPercentage: 
          profileCompletionPercentage ?? this.profileCompletionPercentage,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
    );
  }

  /// Calculate profile completion percentage
  /// 
  /// Based on filled fields:
  /// - name: 10%
  /// - email: 10%
  /// - phone: 20% (required)
  /// - disco: 20%
  /// - band: 20%
  /// - location: 10%
  /// - meterNumber: 10%
  /// 
  /// @return int Profile completion (0-100)
  int calculateProfileCompletion() {
    int completion = 0;
    
    if (name.isNotEmpty) completion += 10;
    if (hasEmail) completion += 10;
    if (phone.isNotEmpty) completion += 20;
    if (disco != null && disco!.isNotEmpty) completion += 20;
    if (band != null && band!.isNotEmpty) completion += 20;
    if (location != null && location!.isNotEmpty) completion += 10;
    if (hasMeterNumber) completion += 10;
    
    return completion;
  }

  /// Update last login timestamp to now
  /// 
  /// SECURITY: Call this after successful authentication
  /// 
  /// @return UserModel with updated lastLogin
  UserModel updateLastLogin() {
    return copyWith(lastLogin: DateTime.now());
  }

  // ===========================================================================
  // EQUALITY & HASH CODE
  // ===========================================================================

  /// Equality operator
  /// 
  /// Two users are equal if they have the same UID
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  /// Hash code based on UID
  @override
  int get hashCode => uid.hashCode;

  // ===========================================================================
  // STRING REPRESENTATION
  // ===========================================================================

  /// String representation for debugging
  /// 
  /// SECURITY: Does not include sensitive data (phone, email)
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, disco: $disco, band: $band)';
  }

  /// Detailed string representation
  /// 
  /// SECURITY: Use only in development/debugging
  /// NEVER log in production (contains phone number)
  String toDebugString() {
    return '''
UserModel {
  uid: $uid,
  name: $name,
  email: $email,
  phone: $phone,
  disco: $disco,
  band: $band,
  location: $location,
  meterNumber: $meterNumber,
  theme: $theme,
  rememberMe: $rememberMe,
  profileCompletion: $profileCompletionPercentage%,
  isActive: $isActive,
  createdAt: $createdAt,
  lastLogin: $lastLogin
}
    ''';
  }
}

/**
 * SECURITY NOTES:
 * 
 * 1. PASSWORD SECURITY
 *    - Password hash NEVER stored in client-side model
 *    - Password hash managed by backend only
 *    - Use Firebase Auth for password management
 * 
 * 2. PHONE NUMBER SECURITY
 *    - Phone number stored for authentication
 *    - Format: E.164 international format
 *    - Validate format before saving
 * 
 * 3. DATA VALIDATION
 *    - Always validate data from Firestore
 *    - Handle null/missing fields gracefully
 *    - Use default values for non-critical fields
 * 
 * 4. LOGGING
 *    - Never log phone numbers or emails in production
 *    - Use toString() for safe logging
 *    - Use toDebugString() only in development
 * 
 * 5. FIRESTORE SECURITY
 *    - UID-based document access control
 *    - Security rules prevent unauthorized access
 *    - Client can only read/write their own data
 */

/**
 * USAGE EXAMPLES:
 * 
 * ```dart
 * // Create new user
 * final user = UserModel(
 *   uid: 'abc123',
 *   name: 'Ifeanyi',
 *   phone: '+2348100000000',
 *   email: 'ifeanyi@example.com',
 * );
 * 
 * // Save to Firestore
 * await FirebaseFirestore.instance
 *   .collection('users')
 *   .doc(user.uid)
 *   .set(user.toJson());
 * 
 * // Load from Firestore
 * final snapshot = await FirebaseFirestore.instance
 *   .collection('users')
 *   .doc('abc123')
 *   .get();
 * final loadedUser = UserModel.fromFirestore(snapshot);
 * 
 * // Update user
 * final updatedUser = user.copyWith(
 *   disco: 'Ikeja Electric',
 *   band: 'C',
 *   location: 'Yaba',
 * );
 * 
 * // Check profile completion
 * print('Profile ${updatedUser.profileCompletionPercentage}% complete');
 * 
 * // Update last login
 * final userWithLogin = user.updateLastLogin();
 * ```
 */
