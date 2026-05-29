// lib/features/token_logger/widgets/confirmation_dialog.dart

import 'package:flutter/material.dart';
import '../services/token_calculation_service.dart';

/// Confirmation Dialog
/// 
/// PURPOSE: Show user calculated results before saving
/// REQUIRED: User must explicitly confirm before log is saved
/// 
/// DISPLAYS:
///   - Units purchased
///   - Estimated remaining (if past purchase)
///   - Disclaimer about estimate vs actual meter reading
class ConfirmationDialog extends StatelessWidget {
  final double unitsPurchased;
  final double estimatedRemaining;
  final double amountPaid;
  final DateTime purchaseDate;
  final String disco;
  final String band;

  const ConfirmationDialog({
    Key? key,
    required this.unitsPurchased,
    required this.estimatedRemaining,
    required this.amountPaid,
    required this.purchaseDate,
    required this.disco,
    required this.band,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPastPurchase = purchaseDate.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('Confirm Token Log'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount paid
            _buildInfoRow(
              'Amount Paid:',
              TokenCalculationService.formatAmount(amountPaid),
            ),
            const SizedBox(height: 12),

            // Purchase date
            _buildInfoRow(
              'Purchase Date:',
              TokenCalculationService.formatDate(purchaseDate),
            ),
            const SizedBox(height: 12),

            // DisCo + Band
            _buildInfoRow(
              'DisCo:',
              '$disco (Band $band)',
            ),
            const SizedBox(height: 12),

            const Divider(),
            const SizedBox(height: 12),

            // Units purchased
            _buildHighlightRow(
              'Units Purchased:',
              TokenCalculationService.formatUnits(unitsPurchased),
              Colors.blue,
            ),

            // Estimated remaining (if past purchase)
            if (isPastPurchase) ...[
              const SizedBox(height: 12),
              _buildHighlightRow(
                'Est. Remaining Today:',
                TokenCalculationService.formatUnits(estimatedRemaining),
                estimatedRemaining > 0 ? Colors.green : Colors.red,
              ),
            ],

            const SizedBox(height: 16),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is an estimate, not a meter reading. '
                      'Actual units may vary.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),

        // Confirm button
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: const Text('Confirm & Save'),
        ),
      ],
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build highlighted row (for important values)
  Widget _buildHighlightRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
