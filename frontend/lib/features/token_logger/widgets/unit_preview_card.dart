// lib/features/token_logger/widgets/unit_preview_card.dart

import 'package:flutter/material.dart';
import '../services/token_calculation_service.dart';

/// Unit Preview Card
/// 
/// PURPOSE: Show calculated units in real-time as user types
/// FEEDBACK: Immediate visual feedback on calculation
/// 
/// DISPLAYS:
///   - Units purchased
///   - Estimated remaining (if past purchase)
///   - Warning message (if applicable)
class UnitPreviewCard extends StatelessWidget {
  final double unitsPurchased;
  final double estimatedRemaining;
  final double amountPaid;
  final String disco;
  final String band;
  final String? warning;

  const UnitPreviewCard({
    Key? key,
    required this.unitsPurchased,
    required this.estimatedRemaining,
    required this.amountPaid,
    required this.disco,
    required this.band,
    this.warning,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPastPurchase = estimatedRemaining < unitsPurchased;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: Colors.amber.shade600,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Calculated Units',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // Units purchased
            _buildUnitRow(
              label: 'Units Purchased',
              value: unitsPurchased,
              color: Colors.blue,
              isMainValue: true,
            ),

            // Estimated remaining (if different)
            if (isPastPurchase) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              _buildUnitRow(
                label: 'Est. Remaining Today',
                value: estimatedRemaining,
                color: estimatedRemaining > 0 ? Colors.green : Colors.red,
                isMainValue: false,
              ),
            ],

            const SizedBox(height: 16),

            // Summary text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                TokenCalculationService.formatAmount(amountPaid) +
                    ' with $disco (Band $band) ≈ ' +
                    TokenCalculationService.formatUnits(unitsPurchased),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Warning message (if applicable)
            if (warning != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build unit row with label and value
  Widget _buildUnitRow({
    required String label,
    required double value,
    required Color color,
    required bool isMainValue,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMainValue ? 16 : 14,
            color: Colors.black87,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            TokenCalculationService.formatUnits(value),
            style: TextStyle(
              fontSize: isMainValue ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
