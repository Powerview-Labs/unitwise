import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_state.dart';
import '../widgets/unit_balance_card.dart';
import '../widgets/days_remaining_card.dart';
import '../widgets/burn_status_indicator.dart';
import '../widgets/outage_toggle.dart';
import '../widgets/locked_forecast_banner.dart';
import '../widgets/alert_banner.dart';
import '../widgets/manual_override_input.dart';
import '../widgets/smart_tips_panel.dart';
import '../widgets/shortcut_buttons.dart';
import '../widgets/last_updated_timestamp.dart';
import '../../../shared/constants/dashboard_constants.dart';
import '../../token_logger/services/token_logger_gating_service.dart';
// ✅ Import estimator screen so we can push it directly with isFromDashboard: true
import '../../../screens/estimator/appliance_estimator_screen.dart';

/// Dashboard Screen - Main home screen of UnitWise
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    if (lifecycleState == AppLifecycleState.resumed) {
      context.read<DashboardProvider>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardConstants.lightBackground,
      appBar: AppBar(
        title: const Text(DashboardConstants.appBarTitle),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DashboardProvider>().refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.state == DashboardState.empty()) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.errorMessage != null) ...[
                    _buildErrorBanner(provider.errorMessage!),
                    const SizedBox(height: 16),
                  ],

                  AlertBanner(alerts: provider.state.alerts),
                  if (provider.state.alerts.hasAlerts) const SizedBox(height: 16),

                  // ✅ Bug 2: This banner is driven by hasEstimatorCompleted which
                  // is set immediately when user skips — so it shows right away.
                  if (!provider.state.hasEstimatorCompleted) ...[
                    LockedForecastBanner(
                      onCompleteEstimator: () => _navigateToEstimator(context),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!provider.state.hasTokenLogged) ...[
                    _buildTokenMissingBanner(context),
                    const SizedBox(height: 16),
                  ],

                  UnitBalanceCard(state: provider.state),
                  const SizedBox(height: DashboardConstants.cardSpacing),

                  DaysRemainingCard(state: provider.state),
                  if (provider.state.hasEstimatorCompleted)
                    const SizedBox(height: 16),

                  Center(child: BurnStatusIndicator(state: provider.state)),
                  const SizedBox(height: 16),

                  LastUpdatedTimestamp(timestamp: provider.state.lastCalculatedAt),
                  const SizedBox(height: DashboardConstants.sectionSpacing),

                  OutageToggle(
                    isActive: provider.state.outageModeActive,
                    onChanged: (value) async {
                      if (kDebugMode) {
                        debugPrint(
                            '🔵 [Dashboard] Toggle clicked: current=${provider.state.outageModeActive}, new=$value');
                      }
                      await provider.toggleOutage();
                      if (kDebugMode) {
                        debugPrint(
                            '✅ [Dashboard] Toggle completed: ${provider.state.outageModeActive}');
                      }
                    },
                  ),
                  const SizedBox(height: DashboardConstants.sectionSpacing),

                  ManualOverrideInput(
                    isActive: provider.state.manualOverride,
                    currentValue: provider.state.manualUnits,
                    onApply: (units) {
                      provider.applyManualOverride(units).catchError((e) {
                        _showErrorSnackBar(
                          context,
                          provider.errorMessage ?? 'Invalid unit value',
                        );
                      });
                    },
                    onDisable: () => provider.disableManualOverride(),
                  ),
                  const SizedBox(height: DashboardConstants.sectionSpacing),

                  SmartTipsPanel(alerts: provider.state.alerts),
                  if (provider.state.alerts.suggestions.isNotEmpty)
                    const SizedBox(height: DashboardConstants.sectionSpacing),

                  // ✅ Bug 3: Pass isFromDashboard: true via _navigateToEstimator
                  ShortcutButtons(
                    onAppliancesPressed: () => _navigateToEstimator(context),
                    onBudgetPressed: () => _navigateToBudgetPlanner(context),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== PRIVATE UI BUILDERS =====

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DashboardConstants.dangerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: DashboardConstants.dangerColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: DashboardConstants.dangerColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenMissingBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: DashboardConstants.safeColor, width: 1.5),
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: DashboardConstants.safeColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DashboardConstants.tokenMissingTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: DashboardConstants.safeColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DashboardConstants.tokenMissingMessage,
                  style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _navigateToTokenLogger(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardConstants.safeColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              DashboardConstants.tokenLogButton,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ===== NAVIGATION =====

  /// ✅ Bug 3: Navigate to estimator with isFromDashboard: true
  /// This hides the Skip button and shows Back arrow + Save only.
  /// Dashboard auto-refreshes when user returns.
  Future<void> _navigateToEstimator(BuildContext context) async {
    if (kDebugMode) debugPrint('🔵 [Dashboard] Navigating to estimator...');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ApplianceEstimatorScreen(isFromDashboard: true),
      ),
    );

    if (mounted) {
      if (kDebugMode) debugPrint('🔄 [Dashboard] Returned from estimator, refreshing...');
      await Provider.of<DashboardProvider>(context, listen: false).refresh();
      if (kDebugMode) debugPrint('✅ [Dashboard] Auto-refresh complete');
    }
  }

  Future<void> _navigateToBudgetPlanner(BuildContext context) async {
    if (kDebugMode) debugPrint('🔵 [Dashboard] Navigating to Budget Planner...');
    await Navigator.pushNamed(context, '/budget-planner');
    if (mounted) {
      await Provider.of<DashboardProvider>(context, listen: false).refresh();
    }
  }

  Future<void> _navigateToSettings(BuildContext context) async {
    if (kDebugMode) debugPrint('🔵 [Dashboard] Navigating to Settings...');
    await Navigator.pushNamed(context, '/settings');
    if (mounted) {
      await Provider.of<DashboardProvider>(context, listen: false).refresh();
    }
  }

  Future<void> _navigateToTokenLogger(BuildContext context) async {
    if (kDebugMode) debugPrint('🔵 [Dashboard] Checking Token Logger prerequisites...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar(context, 'Please log in first');
        return;
      }

      final gatingService = TokenLoggerGatingService();
      final result = await gatingService.checkAccess(user.uid);

      if (!result.canAccess) {
        if (result.missingStep == GatingStep.location) {
          await Navigator.pushNamed(context, '/location-setup');
          if (mounted) {
            await Provider.of<DashboardProvider>(context, listen: false).refresh();
          }
          return;
        }

        if (result.missingStep == GatingStep.appliance) {
          // ✅ Bug 3: Also pass isFromDashboard: true here
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ApplianceEstimatorScreen(isFromDashboard: true),
            ),
          );
          if (mounted) {
            await Provider.of<DashboardProvider>(context, listen: false).refresh();
          }
          return;
        }

        if (mounted) {
          _showErrorSnackBar(context, result.message ?? 'Please complete setup first');
        }
        return;
      }

      await Navigator.pushNamed(context, '/token-logger');
      if (mounted) {
        await Provider.of<DashboardProvider>(context, listen: false).refresh();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [Dashboard] Error checking prerequisites: $e');
      if (mounted) _showErrorSnackBar(context, 'Error checking prerequisites: $e');
    }
  }

  // ===== SNACKBAR HELPERS =====

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: DashboardConstants.dangerColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}