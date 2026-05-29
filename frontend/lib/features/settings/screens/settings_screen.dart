// 📄 File: lib/features/settings/screens/settings_screen.dart
// Phase 2: UI Implementation - Complete Settings Screen with Theme Switching
// Material Design 3 with UnitWise branding

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/settings_provider.dart';
import '../widgets/band_change_dialog.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';

/// Settings Screen
///
/// BUG FIX:
/// ✅ "Settings provider not available" on first login — fixed.
///    Root cause: SettingsProvider is registered but loadSettings() hasn't
///    completed yet on first open after signup. The screen was showing a
///    permanent error instead of waiting.
///    Fix: null provider now shows a spinner + schedules a retry via
///    addPostFrameCallback, so the screen self-heals as soon as the
///    provider becomes ready.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _userName;
  String? _userPhone;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initSettings();
      _loadUserProfile();
    });
  }

  /// ✅ FIX: Try to load settings, and if the provider isn't ready yet,
  /// schedule another attempt after a short delay so the screen self-heals.
  void _initSettings() {
    final provider = context.read<SettingsProvider?>();
    if (provider != null) {
      provider.loadSettings();
    } else {
      // Provider registered but not yet available — retry after 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final retryProvider = context.read<SettingsProvider?>();
        retryProvider?.loadSettings();
        // Trigger a rebuild so Consumer picks up the now-available provider
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          final data = doc.exists ? doc.data() : null;
          _userName = data?['name'] as String? ?? 'Not set';
          _userEmail = data?['email'] as String? ?? 'Not set';
          String? phone = data?['phone'] as String? ?? user.phoneNumber;
          if (phone != null && phone.startsWith('+234')) {
            phone = '0${phone.substring(4)}';
          }
          _userPhone = phone ?? 'Not set';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Not set';
          _userEmail = 'Not set';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Consumer<SettingsProvider?>(
        builder: (context, provider, child) {
          // ✅ FIX: Provider null = still initialising, not a real error.
          // Show spinner and schedule a retry instead of showing error text.
          if (provider == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) setState(() {});
                });
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!provider.hasSettings) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load settings',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadSettings(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final settings = provider.settings!;

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              // ========== PERSONALIZATION SECTION ==========
              SettingsSection(
                title: 'Personalization',
                children: [
                  SettingsTile.info(
                    title: 'Name',
                    value: _userName ?? 'Loading...',
                    icon: Icons.person,
                  ),
                  SettingsTile.info(
                    title: 'Phone',
                    value: _userPhone ?? 'Loading...',
                    icon: Icons.phone,
                  ),
                  SettingsTile.info(
                    title: 'Email',
                    value: _userEmail ?? 'Loading...',
                    icon: Icons.email,
                  ),
                  SettingsTile.navigation(
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    icon: Icons.logout,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ========== ACCOUNT SECTION ==========
              SettingsSection(
                title: 'Account & Meter',
                children: [
                  SettingsTile.navigation(
                    title: 'DisCo',
                    value: settings.disco,
                    icon: Icons.business,
                    onTap: () => _showDiscoSelector(context, provider),
                  ),
                  SettingsTile.navigation(
                    title: 'Band',
                    value: 'Band ${settings.band}',
                    subtitle: '${settings.bandSupplyHours} hours/day average supply',
                    icon: Icons.signal_cellular_alt,
                    onTap: () => _showBandSelector(context, provider),
                  ),
                  SettingsTile.navigation(
                    title: 'Meter Number',
                    value: settings.meterNumber.isEmpty ? 'Not set' : settings.meterNumber,
                    icon: Icons.electric_meter,
                    onTap: () => _showMeterNumberDialog(context, provider),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ========== ALERTS SECTION ==========
              SettingsSection(
                title: 'Alerts & Thresholds',
                children: [
                  SettingsTile.navigation(
                    title: 'Low Unit Threshold',
                    value: '${settings.lowUnitThreshold.toStringAsFixed(0)} units',
                    subtitle: 'Alert when units drop below this value',
                    icon: Icons.battery_alert,
                    onTap: () => _showThresholdDialog(context, provider),
                  ),
                  SettingsTile.switchTile(
                    title: 'Low Unit Alerts',
                    subtitle: 'Notify when approaching threshold',
                    value: settings.lowUnitAlertsEnabled,
                    icon: Icons.notifications_active,
                    onChanged: (value) =>
                        provider.toggleNotification('lowUnitAlertsEnabled', value),
                  ),
                  SettingsTile.switchTile(
                    title: 'Critical Alerts',
                    subtitle: 'Notify when < 1 day remaining',
                    value: settings.criticalAlertsEnabled,
                    icon: Icons.warning,
                    onChanged: (value) =>
                        provider.toggleNotification('criticalAlertsEnabled', value),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ========== PREFERENCES SECTION ==========
              SettingsSection(
                title: 'Preferences',
                children: [
                  SettingsTile.switchTile(
                    title: 'Outage Mode',
                    subtitle: settings.outageMode
                        ? 'Active - Burn tracking paused'
                        : 'Toggle when power is out',
                    value: settings.outageMode,
                    icon: Icons.power_off,
                    onChanged: (value) => provider.toggleOutageMode(value),
                  ),
                  SettingsTile.navigation(
                    title: 'Theme',
                    value: _getThemeDisplayName(settings.theme),
                    icon: Icons.palette,
                    onTap: () => _showThemeSelector(context, provider),
                  ),
                  SettingsTile.info(
                    title: 'Language',
                    value: 'English',
                    subtitle: 'More languages coming soon',
                    icon: Icons.language,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ========== NOTIFICATIONS SECTION ==========
              SettingsSection(
                title: 'Notifications',
                children: [
                  SettingsTile.switchTile(
                    title: 'Enable Notifications',
                    subtitle: 'Master toggle for all notifications',
                    value: settings.notificationsEnabled,
                    icon: Icons.notifications,
                    onChanged: (value) =>
                        provider.toggleNotification('notificationsEnabled', value),
                  ),
                  SettingsTile.switchTile(
                    title: 'Behavioral Reminders',
                    subtitle: 'Tips and usage suggestions',
                    value: settings.behavioralRemindersEnabled,
                    icon: Icons.lightbulb_outline,
                    onChanged: (value) =>
                        provider.toggleNotification('behavioralRemindersEnabled', value),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ========== APP INFO SECTION ==========
              SettingsSection(
                title: 'About',
                children: [
                  SettingsTile.info(
                    title: 'Version',
                    value: '1.0.0',
                    icon: Icons.info_outline,
                  ),
                  SettingsTile.navigation(
                    title: 'Support',
                    subtitle: 'Get help or report issues',
                    icon: Icons.help_outline,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support coming soon')),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Last updated: ${_formatTimestamp(settings.updatedAt)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  // ========== DIALOG HELPERS ==========

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDiscoSelector(BuildContext context, SettingsProvider provider) {
    const discos = [
      'Abuja Electricity Distribution Company',
      'Benin Electricity Distribution Company',
      'Eko Electricity Distribution Company',
      'Enugu Electricity Distribution Company',
      'Ibadan Electricity Distribution Company',
      'Ikeja Electric',
      'Jos Electricity Distribution',
      'Kaduna Electricity Distribution Company',
      'Kano Electricity Distribution Company',
      'Port Harcourt Electricity Distribution',
      'Yola Electricity Distribution Company',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select DisCo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: discos.length,
            itemBuilder: (context, index) {
              final disco = discos[index];
              final isSelected = provider.settings?.disco == disco;
              return ListTile(
                title: Text(disco),
                trailing: isSelected ? const Icon(Icons.check) : null,
                selected: isSelected,
                onTap: () {
                  provider.updateDisco(disco);
                  Navigator.pop(context);
                  _showChangeConfirmation(
                    context,
                    'DisCo changed to $disco.',
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBandSelector(BuildContext context, SettingsProvider provider) {
    const bands = ['A', 'B', 'C', 'D', 'E'];
    final currentBand = provider.settings?.band ?? 'C';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Band'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: bands.map((band) {
            final isSelected = currentBand == band;
            final supplyHours = _getBandSupplyHours(band);
            return ListTile(
              title: Text('Band $band'),
              subtitle: Text('$supplyHours hours/day average'),
              trailing: isSelected ? const Icon(Icons.check) : null,
              selected: isSelected,
              onTap: () {
                Navigator.pop(context);
                showBandChangeDialog(
                  context: context,
                  currentBand: currentBand,
                  newBand: band,
                  onConfirm: () {
                    provider.updateBand(band);
                    _showChangeConfirmation(
                      context,
                      'Band changed to $band. This affects future estimates only.',
                    );
                  },
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMeterNumberDialog(BuildContext context, SettingsProvider provider) {
    final controller = TextEditingController(
      text: provider.settings?.meterNumber ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Meter Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your meter number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final meterNumber = controller.text.trim();
              if (meterNumber.isNotEmpty) {
                provider.updateMeterNumber(meterNumber);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThresholdDialog(BuildContext context, SettingsProvider provider) {
    double threshold = provider.settings?.lowUnitThreshold ?? 10.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Low Unit Threshold'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${threshold.toStringAsFixed(0)} units',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Slider(
                value: threshold,
                min: 5,
                max: 100,
                divisions: 19,
                label: threshold.toStringAsFixed(0),
                onChanged: (value) => setState(() => threshold = value),
              ),
              const SizedBox(height: 8),
              const Text(
                "You'll be notified when your units drop below this value",
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
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
                provider.updateLowUnitThreshold(threshold);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, SettingsProvider provider) {
    const themes = {
      'light': 'Light',
      'dark': 'Dark',
      'system': 'System Default',
    };
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.entries.map((entry) {
            final isSelected = provider.settings?.theme == entry.key;
            return ListTile(
              title: Text(entry.value),
              trailing: isSelected ? const Icon(Icons.check) : null,
              selected: isSelected,
              onTap: () async {
                await provider.updateTheme(entry.key);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme changed to ${entry.value}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showChangeConfirmation(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  // ========== HELPERS ==========

  int _getBandSupplyHours(String band) {
    const bandHours = {'A': 20, 'B': 16, 'C': 12, 'D': 8, 'E': 4};
    return bandHours[band] ?? 12;
  }

  String _getThemeDisplayName(String theme) {
    const names = {'light': 'Light', 'dark': 'Dark', 'system': 'System Default'};
    return names[theme] ?? 'System Default';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}