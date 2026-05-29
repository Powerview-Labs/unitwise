import 'token_document.dart';

/// TokenHistoryFilter - Client-side filtering for token history
/// 
/// SECURITY PRINCIPLE: All filtering happens client-side for MVP
/// - No server-side queries with user input (prevents injection)
/// - All filter operations are read-only
/// - Search queries are sanitized before use
/// 
/// PERFORMANCE: Designed for <100 tokens
/// - For larger datasets, implement server-side pagination post-MVP
class TokenHistoryFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? disco;
  final String? band;
  final String? searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final double? minUnits;
  final double? maxUnits;
  
  const TokenHistoryFilter({
    this.startDate,
    this.endDate,
    this.disco,
    this.band,
    this.searchQuery,
    this.minAmount,
    this.maxAmount,
    this.minUnits,
    this.maxUnits,
  });
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return startDate != null ||
        endDate != null ||
        disco != null ||
        band != null ||
        searchQuery != null ||
        minAmount != null ||
        maxAmount != null ||
        minUnits != null ||
        maxUnits != null;
  }
  
  /// Apply all filters to a list of tokens
  /// SECURITY: All operations are read-only, no mutations
  List<TokenDocument> apply(List<TokenDocument> tokens) {
    var filtered = tokens;
    
    // SECURITY: Validate input list is not null
    if (tokens.isEmpty) return [];
    
    // Date range filter
    filtered = _applyDateFilter(filtered);
    
    // DisCo filter
    filtered = _applyDiscoFilter(filtered);
    
    // Band filter
    filtered = _applyBandFilter(filtered);
    
    // Amount range filter
    filtered = _applyAmountFilter(filtered);
    
    // Units range filter
    filtered = _applyUnitsFilter(filtered);
    
    // Search filter (must be last - most expensive operation)
    filtered = _applySearchFilter(filtered);
    
    return filtered;
  }
  
  /// SECURITY: Safe date filtering with validation
  List<TokenDocument> _applyDateFilter(List<TokenDocument> tokens) {
    var result = tokens;
    
    if (startDate != null) {
      // SECURITY: Normalize to start of day to avoid timezone issues
      final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
      result = result.where((token) {
        final tokenDate = DateTime(
          token.purchaseDate.year,
          token.purchaseDate.month,
          token.purchaseDate.day,
        );
        return tokenDate.isAfter(start) || tokenDate.isAtSameMomentAs(start);
      }).toList();
    }
    
    if (endDate != null) {
      // SECURITY: Normalize to end of day
      final end = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        23,
        59,
        59,
      );
      result = result.where((token) {
        return token.purchaseDate.isBefore(end) ||
            token.purchaseDate.isAtSameMomentAs(end);
      }).toList();
    }
    
    return result;
  }
  
  /// SECURITY: Case-insensitive DisCo filtering
  List<TokenDocument> _applyDiscoFilter(List<TokenDocument> tokens) {
    if (disco == null || disco!.isEmpty) return tokens;
    
    // SECURITY: Sanitize disco string - remove special characters
    final sanitizedDisco = _sanitizeString(disco!);
    
    return tokens.where((token) {
      final tokenDisco = _sanitizeString(token.disco);
      return tokenDisco.toLowerCase() == sanitizedDisco.toLowerCase();
    }).toList();
  }
  
  /// SECURITY: Case-insensitive Band filtering
  List<TokenDocument> _applyBandFilter(List<TokenDocument> tokens) {
    if (band == null || band!.isEmpty) return tokens;
    
    // SECURITY: Sanitize band string
    final sanitizedBand = _sanitizeString(band!);
    
    return tokens.where((token) {
      return token.band.toLowerCase() == sanitizedBand.toLowerCase();
    }).toList();
  }
  
  /// SECURITY: Safe numeric range filtering
  List<TokenDocument> _applyAmountFilter(List<TokenDocument> tokens) {
    var result = tokens;
    
    if (minAmount != null) {
      // SECURITY: Validate min amount is not negative
      final min = minAmount! < 0 ? 0 : minAmount!;
      result = result.where((token) => token.amountPaid >= min).toList();
    }
    
    if (maxAmount != null) {
      // SECURITY: Validate max amount is not negative
      final max = maxAmount! < 0 ? 0 : maxAmount!;
      result = result.where((token) => token.amountPaid <= max).toList();
    }
    
    return result;
  }
  
  /// SECURITY: Safe numeric range filtering for units
  List<TokenDocument> _applyUnitsFilter(List<TokenDocument> tokens) {
    var result = tokens;
    
    if (minUnits != null) {
      // SECURITY: Validate min units is not negative
      final min = minUnits! < 0 ? 0 : minUnits!;
      result = result.where((token) => token.unitsPurchased >= min).toList();
    }
    
    if (maxUnits != null) {
      // SECURITY: Validate max units is not negative
      final max = maxUnits! < 0 ? 0 : maxUnits!;
      result = result.where((token) => token.unitsPurchased <= max).toList();
    }
    
    return result;
  }
  
  /// SECURITY: Sanitized search filtering
  /// Searches across: token code, meter number, date string
  List<TokenDocument> _applySearchFilter(List<TokenDocument> tokens) {
    if (searchQuery == null || searchQuery!.trim().isEmpty) return tokens;
    
    // SECURITY: Sanitize search query - remove special characters, limit length
    final sanitizedQuery = _sanitizeSearchQuery(searchQuery!);
    
    if (sanitizedQuery.isEmpty) return tokens;
    
    return tokens.where((token) {
      // Search in token code
      if (token.tokenCode != null) {
        final tokenCode = _sanitizeString(token.tokenCode!);
        if (tokenCode.toLowerCase().contains(sanitizedQuery.toLowerCase())) {
          return true;
        }
      }
      
      // Search in meter number
      if (token.meterNumber != null) {
        final meterNumber = _sanitizeString(token.meterNumber!);
        if (meterNumber.toLowerCase().contains(sanitizedQuery.toLowerCase())) {
          return true;
        }
      }
      
      // Search in date string (e.g., "Jan 15, 2025")
      final dateStr = token.getPurchaseDateDisplay().toLowerCase();
      if (dateStr.contains(sanitizedQuery.toLowerCase())) {
        return true;
      }
      
      // Search in disco name
      final disco = _sanitizeString(token.disco);
      if (disco.toLowerCase().contains(sanitizedQuery.toLowerCase())) {
        return true;
      }
      
      return false;
    }).toList();
  }
  
  /// SECURITY: Sanitize string input - remove potentially dangerous characters
  String _sanitizeString(String input) {
    // Remove leading/trailing whitespace
    final trimmed = input.trim();
    
    // Remove null bytes and control characters
    final sanitized = trimmed.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    return sanitized;
  }
  
  /// SECURITY: Sanitize search query with length limit
  String _sanitizeSearchQuery(String query) {
    // SECURITY: Limit search query length to prevent DoS
    const maxQueryLength = 100;
    
    final sanitized = _sanitizeString(query);
    
    if (sanitized.length > maxQueryLength) {
      return sanitized.substring(0, maxQueryLength);
    }
    
    return sanitized;
  }
  
  /// Create a copy with updated filters
  TokenHistoryFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? disco,
    String? band,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    double? minUnits,
    double? maxUnits,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearDisco = false,
    bool clearBand = false,
    bool clearSearchQuery = false,
    bool clearAmountRange = false,
    bool clearUnitsRange = false,
  }) {
    return TokenHistoryFilter(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      disco: clearDisco ? null : (disco ?? this.disco),
      band: clearBand ? null : (band ?? this.band),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      minAmount: clearAmountRange ? null : (minAmount ?? this.minAmount),
      maxAmount: clearAmountRange ? null : (maxAmount ?? this.maxAmount),
      minUnits: clearUnitsRange ? null : (minUnits ?? this.minUnits),
      maxUnits: clearUnitsRange ? null : (maxUnits ?? this.maxUnits),
    );
  }
  
  /// Clear all filters
  TokenHistoryFilter clear() {
    return const TokenHistoryFilter();
  }
  
  /// SECURITY: Sanitized string representation (no sensitive data)
  @override
  String toString() {
    return 'TokenHistoryFilter(hasActiveFilters: $hasActiveFilters)';
  }
}
