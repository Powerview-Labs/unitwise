import 'package:flutter/material.dart';
import '../models/token_document.dart';

/// TokenEntryCard - Expandable card for displaying token information
/// 
/// SECURITY: All displayed data comes from TokenDocument model
/// - No direct Firestore access
/// - No mutation of token data
/// - Optional fields handled safely
class TokenEntryCard extends StatelessWidget {
  final TokenDocument token;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool showDeleteButton;
  
  const TokenEntryCard({
    Key? key,
    required this.token,
    required this.isExpanded,
    required this.onTap,
    this.onDelete,
    this.showDeleteButton = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsed view (always visible)
              _buildCollapsedView(context),
              
              // Expanded view (conditional)
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _buildExpandedView(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCollapsedView(BuildContext context) {
    return Row(
      children: [
        // Left side: Date and main info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    token.getPurchaseDateDisplay(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Amount → Units
              Row(
                children: [
                  Text(
                    token.getAmountDisplay(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007BFF), // Energy Blue
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    token.getUnitsDisplay(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C896), // Electric Green
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // DisCo + Band
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007BFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      token.disco,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007BFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C896).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Band ${token.band}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00C896),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Right side: Expand icon
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.grey[600],
        ),
      ],
    );
  }
  
  Widget _buildExpandedView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rate per unit
        _buildDetailRow(
          context,
          icon: Icons.attach_money,
          label: 'Rate per unit',
          value: token.getRatePerUnitDisplay(),
        ),
        const SizedBox(height: 12),
        
        // Token code (if available)
        if (token.tokenCode != null && token.tokenCode!.isNotEmpty) ...[
          _buildDetailRow(
            context,
            icon: Icons.confirmation_number,
            label: 'Token code',
            value: token.tokenCode!,
            isMonospace: true,
          ),
          const SizedBox(height: 12),
        ],
        
        // Meter number (if available)
        if (token.meterNumber != null && token.meterNumber!.isNotEmpty) ...[
          _buildDetailRow(
            context,
            icon: Icons.electric_meter,
            label: 'Meter number',
            value: token.meterNumber!,
            isMonospace: true,
          ),
          const SizedBox(height: 12),
        ],
        
        // Estimated coverage (if available)
        if (token.getCoverageDaysDisplay() != null) ...[
          _buildDetailRow(
            context,
            icon: Icons.schedule,
            label: 'Estimated coverage',
            value: token.getCoverageDaysDisplay()!,
          ),
          const SizedBox(height: 12),
        ],
        
        // Disclaimer for historical data
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Values shown reflect estimates at time of purchase',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Delete button (if enabled)
        if (showDeleteButton && onDelete != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Token'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
