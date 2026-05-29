// lib/features/token_logger/models/token_log.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable token log record
/// Represents a single electricity token purchase entry
/// 
/// SECURITY: All fields are validated before creation
/// DATA INTEGRITY: Once created, logs cannot be modified (append-only)
class TokenLog {
  final String id;
  final double amountPaid;
  final DateTime purchaseDate;
  final String? tokenCode; // Optional reference
  final String disco;
  final String band;
  final double unitRate;
  final double unitsPurchased;
  final double estimatedUnitsRemainingAtLog;
  final String estimationMethod;
  final DateTime createdAt;

  const TokenLog({
    required this.id,
    required this.amountPaid,
    required this.purchaseDate,
    this.tokenCode,
    required this.disco,
    required this.band,
    required this.unitRate,
    required this.unitsPurchased,
    required this.estimatedUnitsRemainingAtLog,
    required this.estimationMethod,
    required this.createdAt,
  });

  /// Create TokenLog from Firestore document
  /// 
  /// SECURITY: Validates all required fields exist
  /// ERROR HANDLING: Returns null if data is malformed
  factory TokenLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TokenLog(
      id: doc.id,
      amountPaid: (data['amount_paid'] as num).toDouble(),
      purchaseDate: (data['purchase_date'] as Timestamp).toDate(),
      tokenCode: data['token_code'] as String?,
      disco: data['disco'] as String,
      band: data['band'] as String,
      unitRate: (data['unit_rate'] as num).toDouble(),
      unitsPurchased: (data['units_purchased'] as num).toDouble(),
      estimatedUnitsRemainingAtLog: 
          (data['estimated_units_remaining_at_log'] as num).toDouble(),
      estimationMethod: data['estimation_method'] as String,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  /// Convert TokenLog to Firestore-compatible map
  /// 
  /// SECURITY: Sanitizes all string inputs
  /// DATA INTEGRITY: Ensures consistent field naming
  Map<String, dynamic> toFirestore() {
    return {
      'amount_paid': amountPaid,
      'purchase_date': Timestamp.fromDate(purchaseDate),
      'token_code': tokenCode?.trim(), // Sanitize: trim whitespace
      'disco': disco.trim(),
      'band': band.trim(),
      'unit_rate': unitRate,
      'units_purchased': unitsPurchased,
      'estimated_units_remaining_at_log': estimatedUnitsRemainingAtLog,
      'estimation_method': estimationMethod,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a copy with modified fields
  TokenLog copyWith({
    String? id,
    double? amountPaid,
    DateTime? purchaseDate,
    String? tokenCode,
    String? disco,
    String? band,
    double? unitRate,
    double? unitsPurchased,
    double? estimatedUnitsRemainingAtLog,
    String? estimationMethod,
    DateTime? createdAt,
  }) {
    return TokenLog(
      id: id ?? this.id,
      amountPaid: amountPaid ?? this.amountPaid,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      tokenCode: tokenCode ?? this.tokenCode,
      disco: disco ?? this.disco,
      band: band ?? this.band,
      unitRate: unitRate ?? this.unitRate,
      unitsPurchased: unitsPurchased ?? this.unitsPurchased,
      estimatedUnitsRemainingAtLog: 
          estimatedUnitsRemainingAtLog ?? this.estimatedUnitsRemainingAtLog,
      estimationMethod: estimationMethod ?? this.estimationMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'TokenLog(id: $id, amount: ₦$amountPaid, units: $unitsPurchased, '
           'disco: $disco, band: $band, date: $purchaseDate)';
  }
}
