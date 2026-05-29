// lib/features/token_logger/widgets/past_purchase_warning.dart

import 'package:flutter/material.dart';

/// Past Purchase Warning Widget
/// 
/// PURPOSE: Explain elapsed usage calculation to user
/// BUILDS TRUST: Transparency about how estimates are made
/// 
/// SHOWS:
///   - Days elapsed since purchase
///   - Explanation that usage was estimated
///   - Reference to appliance setup
class PastPurchaseWarning extends StatelessWidget {
  final String explanation;

  const PastPurchaseWarning({
    Key? key,
    required this.explanation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.access_time,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Past Purchase',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
