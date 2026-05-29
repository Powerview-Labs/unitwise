import 'package:cloud_firestore/cloud_firestore.dart';

/// TokenDocument - Read-only model for historical token purchase records
/// 
/// SECURITY PRINCIPLE: Immutable after creation
/// - Once logged by Token Logger, tokens cannot be edited
/// - Only deletion is allowed (with Dashboard recalculation)
/// - All fields are historical snapshots, never recalculated
/// 
/// DATA OWNERSHIP:
/// - Created by: Token Logger (Module 5)
/// - Read by: Token History (Module 7), Dashboard (Module 4)
/// - Modified by: NONE (immutable)
/// - Deleted by: User (with confirmation + Dashboard sync)
class TokenDocument {
  final String id;
  final String userId;
  
  // Core purchase data
  final double amountPaid;
  final double unitsPurchased;
  final DateTime purchaseDate;
  final String? tokenCode; // Optional - user may not provide
  
  // Rate & DisCo info (historical snapshot from time of purchase)
  final double rateUsed;
  final String disco;
  final String band;
  final String? meterNumber; // From user profile at time of logging
  
  // Estimator context (historical snapshot from time of purchase)
  final double? estimatorBurnRate; // May be null if estimator not completed
  final double? estimatedCoverageDays; // May be null if burn rate unavailable
  
  // Metadata
  final DateTime createdAt;
  
  TokenDocument({
    required this.id,
    required this.userId,
    required this.amountPaid,
    required this.unitsPurchased,
    required this.purchaseDate,
    this.tokenCode,
    required this.rateUsed,
    required this.disco,
    required this.band,
    this.meterNumber,
    this.estimatorBurnRate,
    this.estimatedCoverageDays,
    required this.createdAt,
  });
  
  /// SECURITY: Safe Firestore deserialization with validation
  /// - Validates all required fields exist
  /// - Sanitizes numeric inputs
  /// - Handles missing optional fields safely
  /// - Never exposes raw Firestore data structures
  factory TokenDocument.fromFirestore(DocumentSnapshot doc) {
    // SECURITY: Verify document exists before attempting to read data
    if (!doc.exists) {
      throw Exception('Token document does not exist');
    }
    
    final data = doc.data() as Map<String, dynamic>?;
    
    // SECURITY: Validate data map is not null
    if (data == null) {
      throw Exception('Token document data is null');
    }
    
    // SECURITY: Validate required fields exist
    _validateRequiredFields(data);
    
    try {
      return TokenDocument(
        id: doc.id,
        
        // SECURITY: Validate userId matches authenticated user (enforced in service layer)
        userId: data['userId'] as String,
        
        // SECURITY: Sanitize numeric inputs - ensure they're valid numbers
        amountPaid: _toDouble(data['amount_paid'] ?? data['amountPaid']),
        unitsPurchased: _toDouble(data['units_purchased'] ?? data['unitsPurchased'] ?? data['estimated_units']),
        
        // SECURITY: Safe timestamp conversion
        purchaseDate: _toDateTime(data['purchase_date'] ?? data['purchaseDate']),
        
        // SECURITY: Optional fields - safe null handling
        tokenCode: data['token_code'] as String?,
        
        // SECURITY: Sanitize rate and DisCo data
        rateUsed: _toDouble(data['unit_rate'] ?? data['rate_used'] ?? data['rateUsed']),
        disco: data['disco'] as String,
        band: data['band'] as String,
        meterNumber: data['meter_number'] as String?,
        
        // SECURITY: Optional estimator context - may not exist
        estimatorBurnRate: _toDoubleOrNull(data['estimator_burn_rate'] ?? data['estimatorBurnRate']),
        estimatedCoverageDays: _toDoubleOrNull(data['estimated_coverage_days'] ?? data['estimatedCoverageDays']),
        
        // SECURITY: Safe timestamp conversion
        createdAt: _toDateTime(data['created_at'] ?? data['createdAt']),
      );
    } catch (e) {
      // SECURITY: Never expose raw error details to user
      throw Exception('Failed to parse token document: Invalid data format');
    }
  }
  
  /// SECURITY: Validate all required fields exist
  static void _validateRequiredFields(Map<String, dynamic> data) {
    final requiredFields = [
      'userId',
      'disco',
      'band',
    ];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        throw Exception('Missing required field: $field');
      }
    }
    
    // SECURITY: Validate at least one amount field exists
    if (!data.containsKey('amount_paid') && !data.containsKey('amountPaid')) {
      throw Exception('Missing required field: amount_paid');
    }
    
    // SECURITY: Validate at least one units field exists
    if (!data.containsKey('units_purchased') && 
        !data.containsKey('unitsPurchased') && 
        !data.containsKey('estimated_units')) {
      throw Exception('Missing required field: units_purchased');
    }
  }
  
  /// SECURITY: Safe numeric conversion with validation
  static double _toDouble(dynamic value) {
    if (value == null) {
      throw Exception('Cannot convert null to double');
    }
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    
    // SECURITY: Validate string conversion
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed == null) {
        throw Exception('Invalid numeric value: $value');
      }
      return parsed;
    }
    
    throw Exception('Cannot convert ${value.runtimeType} to double');
  }
  
  /// SECURITY: Safe nullable numeric conversion
  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    
    try {
      return _toDouble(value);
    } catch (_) {
      return null; // Silent fail for optional fields
    }
  }
  
  /// SECURITY: Safe timestamp conversion
  static DateTime _toDateTime(dynamic value) {
    if (value == null) {
      throw Exception('Cannot convert null to DateTime');
    }
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is DateTime) {
      return value;
    }
    
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed == null) {
        throw Exception('Invalid date format: $value');
      }
      return parsed;
    }
    
    throw Exception('Cannot convert ${value.runtimeType} to DateTime');
  }
  
  /// Calculate coverage days on-demand (read-only computation)
  /// SECURITY: Never store this - always compute from historical values
  String? getCoverageDaysDisplay() {
    if (estimatorBurnRate == null || estimatorBurnRate == 0) {
      return null; // Not available
    }
    
    final days = unitsPurchased / estimatorBurnRate!;
    return '${days.toStringAsFixed(1)} days';
  }
  
  /// Get formatted rate per unit
  String getRatePerUnitDisplay() {
    return '₦${rateUsed.toStringAsFixed(2)}/unit';
  }
  
  /// Get formatted amount
  String getAmountDisplay() {
    return '₦${amountPaid.toStringAsFixed(2)}';
  }
  
  /// Get formatted units
  String getUnitsDisplay() {
    return '${unitsPurchased.toStringAsFixed(1)} units';
  }
  
  /// Get formatted purchase date
  String getPurchaseDateDisplay() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[purchaseDate.month - 1]} ${purchaseDate.day}, ${purchaseDate.year}';
  }
  
  /// SECURITY: Sanitized string representation (no sensitive data in logs)
  @override
  String toString() {
    return 'TokenDocument(id: $id, date: ${getPurchaseDateDisplay()}, disco: $disco, band: $band)';
  }
}
