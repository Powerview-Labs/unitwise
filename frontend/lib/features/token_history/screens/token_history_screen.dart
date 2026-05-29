import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/token_history_provider.dart';
import '../models/token_document.dart';
import '../models/monthly_summary.dart';
import '../widgets/token_entry_card.dart';
import '../widgets/monthly_summary_card.dart';

/// TokenHistoryScreen - Main screen for viewing token purchase history
/// 
/// SECURITY:
/// - All data access via TokenHistoryProvider (user-scoped)
/// - Delete requires confirmation dialog
/// - Error states are sanitized
/// - No direct Firestore access
/// 
/// FEATURES:
/// - List of all tokens (most recent first)
/// - Monthly summary cards
/// - Search and filter
/// - Pull to refresh
/// - Empty state
/// - Loading states
class TokenHistoryScreen extends StatefulWidget {
  const TokenHistoryScreen({Key? key}) : super(key: key);
  
  @override
  State<TokenHistoryScreen> createState() => _TokenHistoryScreenState();
}

class _TokenHistoryScreenState extends State<TokenHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _expandedTokenId;
  String? _expandedSummaryKey;
  bool _showMonthlySummaries = true;
  
  @override
  void initState() {
    super.initState();
    // Fetch tokens on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TokenHistoryProvider>().fetchTokens();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token History'),
        backgroundColor: const Color(0xFF007BFF),
        elevation: 0,
        actions: [
          // Filter button
          IconButton(
            icon: Consumer<TokenHistoryProvider>(
              builder: (context, provider, _) {
                return Badge(
                  isLabelVisible: provider.hasActiveFilter,
                  child: const Icon(Icons.filter_list),
                );
              },
            ),
            onPressed: _showFilterSheet,
            tooltip: 'Filter',
          ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TokenHistoryProvider>().refresh();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<TokenHistoryProvider>(
        builder: (context, provider, _) {
          // Loading state
          if (provider.isLoading && !provider.hasTokens) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // Error state
          if (provider.error != null && !provider.hasTokens) {
            return _buildErrorState(provider.error!);
          }
          
          // Empty state
          if (!provider.hasTokens) {
            return _buildEmptyState();
          }
          
          // Main content
          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: Column(
              children: [
                // Search bar
                _buildSearchBar(provider),
                
                // Active filter chips
                if (provider.hasActiveFilter)
                  _buildActiveFiltersChips(provider),
                
                // Toggle monthly summaries
                _buildMonthlySummariesToggle(),
                
                // Content list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      // Monthly summaries (if enabled)
                      if (_showMonthlySummaries &&
                          provider.monthlySummaries.isNotEmpty) ...[
                        _buildMonthlySummariesSection(provider),
                        const SizedBox(height: 8),
                        const Divider(thickness: 2),
                        const SizedBox(height: 8),
                      ],
                      
                      // Token list header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'All Tokens',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${provider.filteredTokens.length} ${provider.filteredTokens.length == 1 ? 'token' : 'tokens'}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Token list
                      ...provider.filteredTokens.map((token) {
                        return TokenEntryCard(
                          token: token,
                          isExpanded: _expandedTokenId == token.id,
                          onTap: () => _toggleTokenExpansion(token.id),
                          onDelete: () => _confirmDelete(context, token),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSearchBar(TokenHistoryProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by token code, meter, date...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.updateSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          provider.updateSearchQuery(value);
        },
      ),
    );
  }
  
  Widget _buildActiveFiltersChips(TokenHistoryProvider provider) {
    final filter = provider.currentFilter;
    final chips = <Widget>[];
    
    if (filter.disco != null) {
      chips.add(_buildFilterChip(
        label: 'DisCo: ${filter.disco}',
        onDeleted: () => provider.updateDiscoFilter(null),
      ));
    }
    
    if (filter.band != null) {
      chips.add(_buildFilterChip(
        label: 'Band: ${filter.band}',
        onDeleted: () => provider.updateBandFilter(null),
      ));
    }
    
    if (filter.startDate != null || filter.endDate != null) {
      chips.add(_buildFilterChip(
        label: 'Date range',
        onDeleted: () => provider.updateDateRange(),
      ));
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips,
            ),
          ),
          TextButton(
            onPressed: provider.clearFilters,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIconColor: Colors.grey[600],
      backgroundColor: const Color(0xFF007BFF).withOpacity(0.1),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: Color(0xFF007BFF),
      ),
    );
  }
  
  Widget _buildMonthlySummariesToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.insights, size: 18),
          const SizedBox(width: 8),
          const Text(
            'Monthly Summaries',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Switch(
            value: _showMonthlySummaries,
            onChanged: (value) {
              setState(() {
                _showMonthlySummaries = value;
              });
            },
            activeColor: const Color(0xFF00C896),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMonthlySummariesSection(TokenHistoryProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Monthly Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...provider.monthlySummaries.map((summary) {
          final key = '${summary.year}-${summary.month}';
          return MonthlySummaryCard(
            summary: summary,
            isExpanded: _expandedSummaryKey == key,
            onTap: () => _toggleSummaryExpansion(key),
          );
        }).toList(),
      ],
    );
  }
  
  // ✅ SIMPLIFIED: Shows only icon and "No tokens logged yet" text
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No tokens logged yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TokenHistoryProvider>().refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007BFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _toggleTokenExpansion(String tokenId) {
    setState(() {
      _expandedTokenId = _expandedTokenId == tokenId ? null : tokenId;
    });
  }
  
  void _toggleSummaryExpansion(String key) {
    setState(() {
      _expandedSummaryKey = _expandedSummaryKey == key ? null : key;
    });
  }
  
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(),
    );
  }
  
  // SECURITY: Require explicit confirmation before deletion
  Future<void> _confirmDelete(BuildContext context, TokenDocument token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Token?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will permanently delete this token from your history.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.getPurchaseDateDisplay(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${token.getAmountDisplay()} → ${token.getUnitsDisplay()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 20,
                    color: Colors.orange[800],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deleting this token will affect your current balance.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && context.mounted) {
      final provider = context.read<TokenHistoryProvider>();
      final success = await provider.deleteToken(token.id);
      
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token deleted. Balance updated.'),
              backgroundColor: Color(0xFF00C896),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.error ?? 'Failed to delete token'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

/// Filter sheet widget
class _FilterSheet extends StatefulWidget {
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedDisco;
  String? _selectedBand;
  DateTimeRange? _dateRange;
  
  @override
  void initState() {
    super.initState();
    final filter = context.read<TokenHistoryProvider>().currentFilter;
    _selectedDisco = filter.disco;
    _selectedBand = filter.band;
    
    if (filter.startDate != null || filter.endDate != null) {
      _dateRange = DateTimeRange(
        start: filter.startDate ?? DateTime.now().subtract(const Duration(days: 365)),
        end: filter.endDate ?? DateTime.now(),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = context.read<TokenHistoryProvider>();
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              const Text(
                'Filter Tokens',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Filter options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Date range
                    _buildFilterOption(
                      icon: Icons.date_range,
                      label: 'Date Range',
                      value: _dateRange != null
                          ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                          : 'All time',
                      onTap: _selectDateRange,
                    ),
                    const SizedBox(height: 16),
                    
                    // DisCo
                    _buildFilterOption(
                      icon: Icons.location_on,
                      label: 'DisCo',
                      value: _selectedDisco ?? 'All DisCos',
                      onTap: () => _selectDisco(provider),
                    ),
                    const SizedBox(height: 16),
                    
                    // Band
                    _buildFilterOption(
                      icon: Icons.electric_bolt,
                      label: 'Band',
                      value: _selectedBand ?? 'All Bands',
                      onTap: () => _selectBand(provider),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        provider.clearFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        provider.applyFilter(
                          provider.currentFilter.copyWith(
                            startDate: _dateRange?.start,
                            endDate: _dateRange?.end,
                            disco: _selectedDisco,
                            band: _selectedBand,
                            clearStartDate: _dateRange == null,
                            clearEndDate: _dateRange == null,
                            clearDisco: _selectedDisco == null,
                            clearBand: _selectedBand == null,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BFF),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildFilterOption({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF007BFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007BFF),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (range != null) {
      setState(() {
        _dateRange = range;
      });
    }
  }
  
  Future<void> _selectDisco(TokenHistoryProvider provider) async {
    final discos = provider.getAvailableDiscos();
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select DisCo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All DisCos'),
                trailing: _selectedDisco == null
                    ? const Icon(Icons.check, color: Color(0xFF007BFF))
                    : null,
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(),
              ...discos.map((disco) {
                return ListTile(
                  title: Text(disco),
                  trailing: _selectedDisco == disco
                      ? const Icon(Icons.check, color: Color(0xFF007BFF))
                      : null,
                  onTap: () => Navigator.pop(context, disco),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
    
    if (selected != null || selected == null) {
      setState(() {
        _selectedDisco = selected;
      });
    }
  }
  
  Future<void> _selectBand(TokenHistoryProvider provider) async {
    final bands = provider.getAvailableBands();
    
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Band'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Bands'),
                trailing: _selectedBand == null
                    ? const Icon(Icons.check, color: Color(0xFF007BFF))
                    : null,
                onTap: () => Navigator.pop(context, null),
              ),
              const Divider(),
              ...bands.map((band) {
                return ListTile(
                  title: Text('Band $band'),
                  trailing: _selectedBand == band
                      ? const Icon(Icons.check, color: Color(0xFF007BFF))
                      : null,
                  onTap: () => Navigator.pop(context, band),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
    
    if (selected != null || selected == null) {
      setState(() {
        _selectedBand = selected;
      });
    }
  }
  
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}