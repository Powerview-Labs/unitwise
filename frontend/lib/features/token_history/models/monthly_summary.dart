import 'token_document.dart';

/// MonthlySummary - Aggregated token statistics for a specific month
/// 
/// SECURITY PRINCIPLE: Client-side aggregation only
/// - No server-side computation with user data
/// - All calculations are read-only
/// - No sensitive data stored or logged
/// 
/// PERFORMANCE: Designed for monthly grouping of <100 tokens
class MonthlySummary {
  final String monthYear; // "September 2025"
  final int year;
  final int month;
  final int tokenCount;
  final double totalSpent;
  final double totalUnits;
  final double avgRate;
  final double avgUnitsPerToken;
  final String? primaryDisco; // Most frequent DisCo this month
  
  const MonthlySummary({
    required this.monthYear,
    required this.year,
    required this.month,
    required this.tokenCount,
    required this.totalSpent,
    required this.totalUnits,
    required this.avgRate,
    required this.avgUnitsPerToken,
    this.primaryDisco,
  });
  
  /// SECURITY: Safe client-side aggregation from list of tokens
  /// - Validates input data
  /// - Handles edge cases (empty list, division by zero)
  /// - No external API calls or database writes
  factory MonthlySummary.compute(List<TokenDocument> monthTokens) {
    // SECURITY: Validate input
    if (monthTokens.isEmpty) {
      throw Exception('Cannot compute summary from empty token list');
    }
    
    // Get month/year from first token (all tokens should be same month)
    final firstToken = monthTokens.first;
    final year = firstToken.purchaseDate.year;
    final month = firstToken.purchaseDate.month;
    
    // Month names for display
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final monthYear = '${monthNames[month - 1]} $year';
    
    // SECURITY: Safe aggregation with validation
    double totalSpent = 0.0;
    double totalUnits = 0.0;
    double totalRate = 0.0;
    final discoCount = <String, int>{};
    
    for (final token in monthTokens) {
      // SECURITY: Validate numeric values are not negative
      final amount = token.amountPaid < 0 ? 0 : token.amountPaid;
      final units = token.unitsPurchased < 0 ? 0 : token.unitsPurchased;
      final rate = token.rateUsed < 0 ? 0 : token.rateUsed;
      
      totalSpent += amount;
      totalUnits += units;
      totalRate += rate;
      
      // Count DisCo frequency
      discoCount[token.disco] = (discoCount[token.disco] ?? 0) + 1;
    }
    
    // SECURITY: Safe division - handle zero counts
    final tokenCount = monthTokens.length;
    final avgRate = tokenCount > 0 ? totalRate / tokenCount : 0.0;
    final avgUnitsPerToken = tokenCount > 0 ? totalUnits / tokenCount : 0.0;
    
    // Find most frequent DisCo
    String? primaryDisco;
    if (discoCount.isNotEmpty) {
      primaryDisco = discoCount.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }
    
    return MonthlySummary(
      monthYear: monthYear,
      year: year,
      month: month,
      tokenCount: tokenCount,
      totalSpent: totalSpent,
      totalUnits: totalUnits,
      avgRate: avgRate,
      avgUnitsPerToken: avgUnitsPerToken,
      primaryDisco: primaryDisco,
    );
  }
  
  /// Group tokens by month and compute summaries
  /// SECURITY: Read-only operation, no mutations
  static List<MonthlySummary> computeAll(List<TokenDocument> tokens) {
    if (tokens.isEmpty) return [];
    
    // Group tokens by month/year
    final monthGroups = <String, List<TokenDocument>>{};
    
    for (final token in tokens) {
      final key = '${token.purchaseDate.year}-${token.purchaseDate.month.toString().padLeft(2, '0')}';
      monthGroups[key] = [...(monthGroups[key] ?? []), token];
    }
    
    // Compute summary for each month
    final summaries = <MonthlySummary>[];
    
    for (final group in monthGroups.values) {
      try {
        summaries.add(MonthlySummary.compute(group));
      } catch (e) {
        // SECURITY: Silent fail for individual month - don't break entire list
        continue;
      }
    }
    
    // Sort by date (most recent first)
    summaries.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });
    
    return summaries;
  }
  
  /// Get formatted total spent
  String getTotalSpentDisplay() {
    return '₦${totalSpent.toStringAsFixed(2)}';
  }
  
  /// Get formatted total units
  String getTotalUnitsDisplay() {
    return '${totalUnits.toStringAsFixed(1)} units';
  }
  
  /// Get formatted average rate
  String getAvgRateDisplay() {
    return '₦${avgRate.toStringAsFixed(2)}/unit';
  }
  
  /// Get formatted average units per token
  String getAvgUnitsPerTokenDisplay() {
    return '${avgUnitsPerToken.toStringAsFixed(1)} units/token';
  }
  
  /// Get formatted token count
  String getTokenCountDisplay() {
    return tokenCount == 1 ? '1 token' : '$tokenCount tokens';
  }
  
  /// Check if this is the current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }
  
  /// SECURITY: Sanitized string representation (no sensitive amounts)
  @override
  String toString() {
    return 'MonthlySummary($monthYear, tokens: $tokenCount)';
  }
}
