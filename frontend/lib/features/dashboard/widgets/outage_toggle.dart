import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Outage Toggle - "No light right now?" switch
///
/// FEATURES:
/// - Toggle switch for outage mode
/// - Clear labeling
/// - Subtitle explanation
/// - Orange active color
///
/// BEHAVIOR:
/// - When ON: Burn engine pauses
/// - When OFF: Burn engine resumes
///
/// ✅ BUG #4 FIX: Added debug logging
class OutageToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;

  const OutageToggle({
    super.key,
    required this.isActive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: SwitchListTile(
        title: Text(
          DashboardConstants.outageToggleTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            DashboardConstants.outageToggleSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        value: isActive,
        onChanged: (value) {
          // ✅ BUG #4 FIX: Debug logging
          if (kDebugMode) {
            debugPrint('🔵 [OutageToggle] Switch tapped: current=$isActive, new=$value');
          }
          
          onChanged(value);
          
          if (kDebugMode) {
            debugPrint('✅ [OutageToggle] onChanged callback called with $value');
          }
        },
        activeColor: Colors.orange,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}