import 'package:flutter/material.dart';
import '../models/monthly_summary.dart';

/// MonthlySummaryCard - Display aggregated monthly token statistics
/// 
/// SECURITY: All data computed client-side from TokenDocument models
/// - No server-side aggregation
/// - Read-only display
/// - No sensitive data logged
class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;
  final bool isExpanded;
  final VoidCallback onTap;
  
  const MonthlySummaryCard({
    Key? key,
    required this.summary,
    required this.isExpanded,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF007BFF).withOpacity(0.05),
                const Color(0xFF00C896).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Month/Year
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                size: 20,
                                color: Color(0xFF007BFF),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                summary.monthYear,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF007BFF),
                                ),
                              ),
                              if (summary.isCurrentMonth) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C896),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Current',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.getTokenCountDisplay(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Expand icon
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Summary stats (always visible)
                Row(
                  children: [
                    Expanded(
                      child: _buildStatColumn(
                        label: 'Total Spent',
                        value: summary.getTotalSpentDisplay(),
                        icon: Icons.payments,
                        color: const Color(0xFF007BFF),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatColumn(
                        label: 'Total Units',
                        value: summary.getTotalUnitsDisplay(),
                        icon: Icons.electric_bolt,
                        color: const Color(0xFF00C896),
                      ),
                    ),
                  ],
                ),
                
                // Expanded details
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Average stats
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatColumn(
                          label: 'Avg Rate',
                          value: summary.getAvgRateDisplay(),
                          icon: Icons.show_chart,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatColumn(
                          label: 'Avg Units/Token',
                          value: summary.getAvgUnitsPerTokenDisplay(),
                          icon: Icons.analytics,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  
                  // Primary DisCo (if available)
                  if (summary.primaryDisco != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Primary DisCo:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            summary.primaryDisco!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatColumn({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
