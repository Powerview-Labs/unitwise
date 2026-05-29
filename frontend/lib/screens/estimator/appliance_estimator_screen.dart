/**
 * Appliance Estimator Screen
 *
 * BUG FIXES:
 * ✅ Bug 1 — No snackbar on validation failure. Red banner at top is enough.
 * ✅ Bug 3 — isFromDashboard = true: shows Back arrow + Save only (no Skip).
 * ✅ Bug 4 — isFromDashboard = false (onboarding): shows Skip + Save.
 */

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/estimator/appliance_estimator_controller.dart';
import '../../constants/estimator/estimator_constants.dart';
import '../../constants/estimator/estimator_strings.dart';
import '../../utils/estimator/estimator_extensions.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/user_service.dart';
import 'widgets/appliance_list_widget.dart';
import 'widgets/daily_burn_display.dart';
import 'widgets/add_edit_appliance_dialog.dart';

class ApplianceEstimatorScreen extends StatefulWidget {
  /// true  → came from Quick Actions (Back arrow + Save only, no Skip)
  /// false → onboarding flow (Skip + Save)
  final bool isFromDashboard;

  const ApplianceEstimatorScreen({
    super.key,
    this.isFromDashboard = false,
  });

  @override
  State<ApplianceEstimatorScreen> createState() => _ApplianceEstimatorScreenState();
}

class _ApplianceEstimatorScreenState extends State<ApplianceEstimatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApplianceEstimatorController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: Consumer<ApplianceEstimatorController>(
        builder: (context, controller, child) {
          return LoadingOverlay(
            isLoading: controller.isLoading,
            message: EstimatorStrings.loadingMessage,
            child: _buildBody(context, controller),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        EstimatorStrings.screenTitle,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      backgroundColor: EstimatorConstants.primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      // ✅ Bug 3: Show back arrow only when coming from dashboard
      automaticallyImplyLeading: widget.isFromDashboard,
      leading: widget.isFromDashboard
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      actions: [
        Consumer<ApplianceEstimatorController>(
          builder: (context, controller, child) {
            return IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: EstimatorStrings.loadDefaultsTooltip,
              onPressed: controller.isEmpty
                  ? () => _loadDefaults(context, controller)
                  : null,
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: EstimatorConstants.warningRed),
                  const SizedBox(width: 12),
                  const Text(EstimatorStrings.clearAllButton),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20, color: EstimatorConstants.primaryBlue),
                  const SizedBox(width: 12),
                  const Text(EstimatorStrings.helpButton),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ApplianceEstimatorController controller) {
    return Column(
      children: [
        const DailyBurnDisplay(),
        if (controller.hasError) _buildErrorBanner(context, controller),
        Expanded(
          child: controller.isEmpty
              ? _buildEmptyState(context, controller)
              : ApplianceListWidget(controller: controller),
        ),
        _buildBottomActionBar(context, controller),
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context, ApplianceEstimatorController controller) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EstimatorConstants.warningRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EstimatorConstants.warningRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: EstimatorConstants.warningRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.error!,
              style: TextStyle(
                color: EstimatorConstants.warningRed,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: EstimatorConstants.warningRed,
            onPressed: controller.clearError,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ApplianceEstimatorController controller) {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_other_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                EstimatorStrings.emptyStateTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                EstimatorStrings.emptyStateMessage,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _loadDefaults(context, controller),
                icon: const Icon(Icons.add),
                label: const Text(EstimatorStrings.loadDefaultsButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EstimatorConstants.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ Bug 3 & 4: Bottom bar adapts based on where the user came from
  Widget _buildBottomActionBar(BuildContext context, ApplianceEstimatorController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: widget.isFromDashboard
            ? _buildSaveOnlyBar(context, controller)
            : _buildSkipAndSaveBar(context, controller),
      ),
    );
  }

  /// Save only — Quick Actions flow (back is in AppBar)
  Widget _buildSaveOnlyBar(BuildContext context, ApplianceEstimatorController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: controller.hasUnsavedChanges
            ? () => _saveAndReturn(context, controller)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: EstimatorConstants.primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          EstimatorStrings.saveButton,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  /// Skip + Save — onboarding flow
  Widget _buildSkipAndSaveBar(BuildContext context, ApplianceEstimatorController controller) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: () => _skipToDashboard(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: EstimatorConstants.primaryBlue, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              EstimatorStrings.buttonSkip,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: EstimatorConstants.primaryBlue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: controller.hasUnsavedChanges
                ? () => _saveAndCompleteToDashboard(context, controller)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: EstimatorConstants.primaryBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              EstimatorStrings.saveButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Consumer<ApplianceEstimatorController>(
      builder: (context, controller, child) {
        if (!controller.canAddAppliance) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton(
            onPressed: () => _showAddApplianceDialog(context),
            backgroundColor: EstimatorConstants.accentGreen,
            foregroundColor: Colors.white,
            tooltip: EstimatorStrings.addApplianceTooltip,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  /// Quick Actions: save then pop back to dashboard
  Future<void> _saveAndReturn(
    BuildContext context,
    ApplianceEstimatorController controller,
  ) async {
    final success = await controller.saveEstimator();
    if (!mounted) return;

    // ✅ Bug 1: No snackbar — error banner at top is sufficient
    if (!success) return;

    try {
      final userService = context.read<UserService>();
      await userService.updateUserProfile({
        'appliance_setup_completed': true,
        'onboarding_completed': true,
        'appliance_completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[Estimator] ❌ Error updating profile: $e');
    }

    if (!mounted) return;
    context.showSuccessSnackbar(EstimatorStrings.saveSuccessMessage);
    Navigator.pop(context); // Back to dashboard — it auto-refreshes on return
  }

  /// Onboarding: skip → dashboard (forecasts locked banner will show)
  Future<void> _skipToDashboard(BuildContext context) async {
    try {
      final userService = context.read<UserService>();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(userId).get();
        final alreadyCompleted =
            userDoc.data()?['appliance_setup_completed'] as bool? ?? false;

        if (alreadyCompleted) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }
      }

      // ✅ Bug 2: Set false immediately so dashboard shows locked banner right away
      await userService.updateUserProfile({
        'appliance_setup_completed': false,
        'onboarding_completed': true,
        'appliance_skipped_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (kDebugMode) debugPrint('[Estimator] ❌ Error skipping: $e');
      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  /// Onboarding: save → dashboard
  Future<void> _saveAndCompleteToDashboard(
    BuildContext context,
    ApplianceEstimatorController controller,
  ) async {
    final success = await controller.saveEstimator();
    if (!mounted) return;

    // ✅ Bug 1: No snackbar — error banner at top is sufficient
    if (!success) return;

    try {
      final userService = context.read<UserService>();
      await userService.updateUserProfile({
        'appliance_setup_completed': true,
        'onboarding_completed': true,
        'appliance_completed_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      context.showSuccessSnackbar(EstimatorStrings.saveSuccessMessage);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (kDebugMode) debugPrint('[Estimator] ❌ Error completing to dashboard: $e');
      if (!mounted) return;
      context.showSuccessSnackbar(EstimatorStrings.saveSuccessMessage);
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  // ============================================================================
  // EXISTING ACTIONS
  // ============================================================================

  Future<void> _showAddApplianceDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddEditApplianceDialog(),
    );
    if (result != null && mounted) {
      context.showSuccessSnackbar(EstimatorStrings.applianceAddedMessage);
    }
  }

  Future<void> _loadDefaults(
    BuildContext context,
    ApplianceEstimatorController controller,
  ) async {
    if (!controller.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(EstimatorStrings.loadDefaultsConfirmTitle),
          content: const Text(EstimatorStrings.loadDefaultsConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(EstimatorStrings.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(EstimatorStrings.loadDefaultsButton),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await controller.loadDefaults();
    if (mounted && !controller.hasError) {
      context.showSuccessSnackbar(EstimatorStrings.defaultsLoadedMessage);
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    final controller = context.read<ApplianceEstimatorController>();
    switch (action) {
      case 'clear':
        _clearAll(context, controller);
        break;
      case 'help':
        _showHelp(context);
        break;
    }
  }

  Future<void> _clearAll(
    BuildContext context,
    ApplianceEstimatorController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(EstimatorStrings.clearAllConfirmTitle),
        content: const Text(EstimatorStrings.clearAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(EstimatorStrings.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: EstimatorConstants.warningRed),
            child: const Text(EstimatorStrings.clearAllButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.clearAll();
      if (mounted) context.showSuccessSnackbar(EstimatorStrings.clearedMessage);
    }
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(EstimatorStrings.helpTitle),
        content: const SingleChildScrollView(child: Text(EstimatorStrings.helpMessage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(EstimatorStrings.closeButton),
          ),
        ],
      ),
    );
  }
}