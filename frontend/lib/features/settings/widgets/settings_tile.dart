// 📄 File: lib/features/settings/widgets/settings_tile.dart
// Phase 2: UI - Settings Tile Widget with multiple variants

import 'package:flutter/material.dart';

/// Settings Tile Widget
/// 
/// Supports multiple tile types:
/// - Navigation: Tap to navigate/edit
/// - Switch: Toggle on/off
/// - Info: Display-only
/// 
/// Provides consistent styling across all settings
class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? value;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.value,
    this.icon,
    this.trailing,
    this.onTap,
    this.enabled = true,
  }) : super(key: key);

  /// Navigation tile - tap to open dialog/screen
  factory SettingsTile.navigation({
    required String title,
    String? subtitle,
    String? value,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      value: value,
      icon: icon,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  /// Switch tile - toggle boolean value
  factory SettingsTile.switchTile({
    required String title,
    String? subtitle,
    required bool value,
    IconData? icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  /// Info tile - display-only, no interaction
  factory SettingsTile.info({
    required String title,
    String? subtitle,
    String? value,
    IconData? icon,
  }) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      value: value,
      icon: icon,
      enabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: icon != null
          ? Icon(
              icon,
              color: enabled ? theme.colorScheme.primary : Colors.grey,
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled ? Colors.grey[600] : Colors.grey[400],
                ),
              ),
            )
          : null,
      trailing: trailing ??
          (value != null
              ? Text(
                  value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                )
              : null),
    );
  }
}
