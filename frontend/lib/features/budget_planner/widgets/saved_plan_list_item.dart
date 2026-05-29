import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/budget_plan.dart';
import '../utils/budget_constants.dart';

/// List item for a saved budget plan
class SavedPlanListItem extends StatelessWidget {
  final BudgetPlan plan;
  final VoidCallback onDelete;

  const SavedPlanListItem({
    super.key,
    required this.plan,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPlanDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.inputSummary,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'Delete plan',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Key metrics row
              Row(
                children: [
                  _buildMetric(
                    context,
                    icon: Icons.bolt,
                    label: 'Units',
                    value: plan.calculatedUnits.toStringAsFixed(1),
                    color: const Color(0xFFFFA726),
                  ),
                  const SizedBox(width: 20),
                  _buildMetric(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Days',
                    value: plan.estimatedDays.toStringAsFixed(1),
                    color: const Color(0xFF00C896),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Metadata
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(plan.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontFamily: 'Inter',
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontFamily: 'Inter',
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPlanDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
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
                const SizedBox(height: 24),

                // Title
                Text(
                  'Plan Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                ),
                const SizedBox(height: 24),

                // Details
                _buildDetailRow('Input', plan.inputSummary),
                _buildDetailRow('Units', BudgetConstants.formatUnits(plan.calculatedUnits)),
                _buildDetailRow('Coverage', BudgetConstants.formatDays(plan.estimatedDays)),
                _buildDetailRow('Burn Rate', BudgetConstants.formatUnits(plan.burnRate)),
                _buildDetailRow('Rate Used', BudgetConstants.formatCurrency(plan.rateUsed)),
                _buildDetailRow('DisCo', plan.disco),
                _buildDetailRow('Band', plan.band),
                _buildDetailRow('Created', DateFormat('MMM dd, yyyy • hh:mm a').format(plan.createdAt)),

                // Tips if available
                if (plan.tipsShown.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Tips Shown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...plan.tipsShown.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(
                              child: Text(
                                tip,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'Inter',
                                    ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
