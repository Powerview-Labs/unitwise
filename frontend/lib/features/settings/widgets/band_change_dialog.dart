// 📄 File: lib/features/settings/widgets/band_change_dialog.dart
// Phase 2: UI - Band Change Warning Dialog
// CRITICAL: This dialog is MANDATORY before band changes

import 'package:flutter/material.dart';

/// Band Change Warning Dialog
/// 
/// Shows user-friendly warning about band change impact.
/// Exact copy from Document 3:
/// 
/// "Changing your Band will affect future estimates, not past usage.
/// Your previous token records remain unchanged."
/// 
/// CRITICAL UX PRINCIPLES:
/// - Warning is soft, not scary
/// - Explains forward-only impact clearly
/// - Gives user control (Cancel or Confirm)
/// - No blocking, just clarity
void showBandChangeDialog({
  required BuildContext context,
  required String currentBand,
  required String newBand,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Force explicit choice
    builder: (context) => AlertDialog(
      icon: const Icon(
        Icons.info_outline,
        size: 48,
        color: Colors.blue,
      ),
      title: const Text(
        'Change Electricity Band?',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Band change visual
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _BandBadge(band: currentBand),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 16),
              _BandBadge(band: newBand, isNew: true),
            ],
          ),

          const SizedBox(height: 24),

          // Warning text (exact copy from Document 3)
          const Text(
            'Changing your Band will affect future estimates, not past usage.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15),
          ),

          const SizedBox(height: 12),

          const Text(
            'Your previous token records remain unchanged.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 16),

          // What will happen
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What happens next:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _BulletPoint('Future burn rates recalculated'),
                _BulletPoint('Dashboard projections updated'),
                _BulletPoint('Budget estimates adjusted'),
                _BulletPoint('Past token logs unchanged'),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Change'),
        ),
      ],
    ),
  );
}

/// Band badge widget
class _BandBadge extends StatelessWidget {
  final String band;
  final bool isNew;

  const _BandBadge({
    required this.band,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final supplyHours = _getBandSupplyHours(band);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isNew ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Band $band',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNew ? Colors.white : Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${supplyHours}h/day',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  int _getBandSupplyHours(String band) {
    const bandHours = {'A': 20, 'B': 16, 'C': 12, 'D': 8, 'E': 4};
    return bandHours[band] ?? 12;
  }
}

/// Bullet point widget for lists
class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
