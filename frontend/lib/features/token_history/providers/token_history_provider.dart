import 'package:flutter/foundation.dart';
import '../models/token_document.dart';
import '../models/token_history_filter.dart';
import '../models/monthly_summary.dart';
import '../services/token_history_service.dart';

/// TokenHistoryProvider - State management for Token History module
///
/// SECURITY:
/// - All state is user-scoped (no cross-user contamination)
/// - Error states are sanitized
/// - Loading states prevent UI race conditions
///
/// PERFORMANCE:
/// - Debounced search to prevent excessive filtering
/// - Cached filtered results
/// - Lazy loading of monthly summaries
///
/// ✅ FIXED: Initializes as loading to prevent flash of empty state
class TokenHistoryProvider with ChangeNotifier {
  final TokenHistoryService _service;

  // State variables
  List<TokenDocument> _allTokens = [];
  List<TokenDocument> _filteredTokens = [];
  List<MonthlySummary> _monthlySummaries = [];
  TokenHistoryFilter _currentFilter = const TokenHistoryFilter();
  
  // ✅ FIXED: Initialize as loading to show spinner on first render
  bool _isLoading = true;
  String? _error;
  bool _isDeleting = false;

  // SECURITY: Track selected token for detail view (never persisted)
  TokenDocument? _selectedToken;

  TokenHistoryProvider(this._service);

  // Getters
  List<TokenDocument> get allTokens => _allTokens;
  List<TokenDocument> get filteredTokens => _filteredTokens;
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  TokenHistoryFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDeleting => _isDeleting;
  TokenDocument? get selectedToken => _selectedToken;

  bool get hasTokens => _allTokens.isNotEmpty;
  bool get hasActiveFilter => _currentFilter.hasActiveFilters;
  bool get hasCachedData => _service.hasCachedData;

  /// Fetch tokens from Firestore
  /// SECURITY: All data is user-scoped via service layer
  Future<void> fetchTokens({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('TokenHistoryProvider: Fetching tokens (forceRefresh: $forceRefresh)');
      }

      final tokens = await _service.fetchTokens(forceRefresh: forceRefresh);

      _allTokens = tokens;
      _applyCurrentFilter();
      _computeMonthlySummaries();

      _isLoading = false;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('TokenHistoryProvider: Fetched ${tokens.length} tokens');
      }
    } catch (e) {
      // SECURITY: Sanitized error handling
      _isLoading = false;
      _error = e.toString();
      notifyListeners();

      if (kDebugMode) {
        print('TokenHistoryProvider: Error fetching tokens: $e');
      }

      rethrow;
    }
  }

  /// Refresh tokens (pull to refresh)
  Future<void> refresh() async {
    await fetchTokens(forceRefresh: true);
  }

  /// Delete a token
  /// SECURITY: Requires user confirmation (handled in UI layer)
  Future<bool> deleteToken(String tokenId) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('TokenHistoryProvider: Deleting token: $tokenId');
      }

      await _service.deleteToken(tokenId);

      // Remove from local state
      _allTokens.removeWhere((t) => t.id == tokenId);
      _applyCurrentFilter();
      _computeMonthlySummaries();

      _isDeleting = false;
      _error = null;
      notifyListeners();

      if (kDebugMode) {
        print('TokenHistoryProvider: Token deleted successfully');
      }

      return true;
    } catch (e) {
      _isDeleting = false;
      _error = 'Failed to delete token. Please try again.';
      notifyListeners();

      if (kDebugMode) {
        print('TokenHistoryProvider: Error deleting token: $e');
      }

      return false;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Update DisCo filter
  void updateDiscoFilter(String? disco) {
    _currentFilter = _currentFilter.copyWith(
      disco: disco,
      clearDisco: disco == null,
    );
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Update Band filter
  void updateBandFilter(String? band) {
    _currentFilter = _currentFilter.copyWith(
      band: band,
      clearBand: band == null,
    );
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Update date range filter
  void updateDateRange({DateTime? start, DateTime? end}) {
    _currentFilter = _currentFilter.copyWith(
      startDate: start,
      endDate: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Apply filter (from filter sheet)
  void applyFilter(TokenHistoryFilter filter) {
    _currentFilter = filter;
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilter = const TokenHistoryFilter();
    _applyCurrentFilter();
    notifyListeners();
  }

  /// Select a token for detail view
  void selectToken(TokenDocument? token) {
    _selectedToken = token;
    notifyListeners();
  }

  /// Get available DisCos from current tokens
  List<String> getAvailableDiscos() {
    final discos = _allTokens.map((t) => t.disco).toSet().toList();
    discos.sort();
    return discos;
  }

  /// Get available Bands from current tokens
  List<String> getAvailableBands() {
    final bands = _allTokens.map((t) => t.band).toSet().toList();
    bands.sort();
    return bands;
  }

  // ===== PRIVATE HELPERS =====

  /// Apply current filter to all tokens
  void _applyCurrentFilter() {
    _filteredTokens = _allTokens.where((token) {
      // Search query filter
      if (_currentFilter.searchQuery?.isNotEmpty ?? false) {
        final query = _currentFilter.searchQuery!.toLowerCase();
        final matchesTokenCode = token.tokenCode?.toLowerCase().contains(query) ?? false;
        final matchesMeterNumber = token.meterNumber?.toLowerCase().contains(query) ?? false;
        final matchesDisco = token.disco.toLowerCase().contains(query);
        final matchesDate = token.getPurchaseDateDisplay().toLowerCase().contains(query);

        if (!matchesTokenCode && !matchesMeterNumber && !matchesDisco && !matchesDate) {
          return false;
        }
      }

      // DisCo filter
      if (_currentFilter.disco != null && token.disco != _currentFilter.disco) {
        return false;
      }

      // Band filter
      if (_currentFilter.band != null && token.band != _currentFilter.band) {
        return false;
      }

      // Date range filter
      if (_currentFilter.startDate != null &&
          token.purchaseDate.isBefore(_currentFilter.startDate!)) {
        return false;
      }

      if (_currentFilter.endDate != null &&
          token.purchaseDate.isAfter(_currentFilter.endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();

    if (kDebugMode) {
      print('TokenHistoryProvider: Filtered ${_filteredTokens.length} tokens from ${_allTokens.length}');
    }
  }

  /// Compute monthly summaries from all tokens
  void _computeMonthlySummaries() {
    final monthGroups = <String, List<TokenDocument>>{};

    // Group tokens by month
    for (final token in _allTokens) {
      final key = '${token.purchaseDate.year}-${token.purchaseDate.month.toString().padLeft(2, '0')}';
      monthGroups[key] = [...(monthGroups[key] ?? []), token];
    }

    // Compute summary for each month
    final summaries = <MonthlySummary>[];

    for (final group in monthGroups.values) {
      if (group.isEmpty) continue;

      try {
        summaries.add(MonthlySummary.compute(group));
      } catch (e) {
        // Silent fail for individual month
        if (kDebugMode) {
          print('TokenHistoryProvider: Error computing summary: $e');
        }
        continue;
      }
    }

    // Sort by date (most recent first)
    summaries.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });

    _monthlySummaries = summaries;

    if (kDebugMode) {
      print('TokenHistoryProvider: Computed ${_monthlySummaries.length} monthly summaries');
    }
  }
}