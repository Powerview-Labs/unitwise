import 'package:flutter/material.dart';

/// Dashboard constants
/// All UI values, thresholds, and strings centralized here
/// 
/// IMPORTANT: Changes here affect UI behavior across the dashboard
class DashboardConstants {
  // ===== BRAND COLORS (UnitWise Design System) =====
  
  /// Energy Blue - Primary brand color (safe state)
  static const Color safeColor = Color(0xFF007BFF);
  
  /// Warning Orange - Moderate usage (caution state)
  static const Color moderateColor = Color(0xFFFFA500);
  
  /// Danger Red - Critical state
  static const Color dangerColor = Color(0xFFDC3545);
  
  /// Electric Green - Success/active state
  static const Color successColor = Color(0xFF00C896);
  
  /// Background shades
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  
  // ===== UNIT THRESHOLDS =====
  
  /// Above this threshold = Safe (Blue)
  static const double safeUnitsThreshold = 30.0;
  
  /// Between this and safe = Moderate (Yellow)
  static const double moderateUnitsThreshold = 10.0;
  
  /// Below this = Danger (Red)
  static const double dangerUnitsThreshold = 10.0;
  
  // ===== UI STRINGS =====
  
  /// App bar title
  static const String appBarTitle = 'Dashboard';
  
  /// Welcome message prefix
  static const String welcomePrefix = 'Welcome back, ';
  
  /// Default welcome when name unknown
  static const String defaultWelcome = 'Welcome back';
  
  /// Estimated label (always shown with unit values)
  static const String estimatedLabel = '~ Estimated';
  
  /// Status indicators
  static const String trackingActive = 'Tracking Active';
  static const String trackingPaused = 'Paused (Outage Mode)';
  static const String manualOverrideActive = 'Manual Override Active';
  
  /// Outage toggle text
  static const String outageToggleTitle = 'No light right now?';
  static const String outageToggleSubtitle = 'Pause tracking during power outages';
  
  // ===== BANNER MESSAGES =====
  
  /// Shown when estimator not completed
  static const String estimatorLockedTitle = 'Forecasts Locked';
  static const String estimatorLockedMessage = 
      'Complete appliance estimator to unlock forecasts';
  static const String estimatorLockedAction = 'Set Up';
  
  /// Shown when token not logged
  static const String tokenMissingTitle = 'No Token Logged';
  static const String tokenMissingMessage = 
      'Log your token to start tracking';
  static const String tokenMissingAction = 'Log Token';
  
  /// First time user welcome
  static const String firstTimeWelcome = 
      'Welcome to UnitWise! Let\'s get you set up.';
  
  // ===== CARD LABELS =====
  
  static const String unitsRemainingLabel = 'Units Remaining';
  static const String daysRemainingLabel = 'Estimated to Last';
  static const String dailyBurnLabel = 'Daily Usage';
  static const String lastUpdatedLabel = 'Last Updated';
  
  // ===== QUICK ACTIONS =====
  
  static const String quickActionsTitle = 'Quick Actions';
  static const String appliancesButton = 'Appliances';
  static const String budgetButton = 'Budget';
  static const String tokenLogButton = 'Log Token';
  static const String settingsButton = 'Settings';
  
  // ===== MANUAL OVERRIDE =====
  
  static const String manualOverrideTitle = 'Manual Unit Correction';
  static const String manualOverrideDescription = 
      'If the estimate seems wrong, enter your actual unit balance:';
  static const String manualOverrideHint = 'Enter units';
  static const String manualOverrideButton = 'Set';
  static const String manualOverrideDisable = 'Disable';
  static const String manualOverrideActiveMessage = 
      'Manual override is active. Auto-tracking paused.';
  
  // ===== STATUS LABELS =====
  
  static const String statusSafe = 'Safe';
  static const String statusModerate = 'Moderate';
  static const String statusLow = 'Low';
  static const String statusCritical = 'Critical';
  
  // ===== SPACING & SIZING =====
  
  /// Card padding
  static const double cardPadding = 16.0;
  
  /// Spacing between cards
  static const double cardSpacing = 12.0;
  
  /// Border radius for cards
  static const double borderRadius = 12.0;
  
  /// Section spacing
  static const double sectionSpacing = 24.0;
  
  /// Icon size for status indicators
  static const double statusIconSize = 20.0;
  
  /// Button height
  static const double buttonHeight = 48.0;
  
  // ===== ANIMATION DURATIONS =====
  
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // ===== ERROR MESSAGES =====
  
  static const String errorLoadingDashboard = 'Failed to load dashboard';
  static const String errorRefreshingDashboard = 'Failed to refresh dashboard';
  static const String errorTogglingOutage = 'Failed to toggle outage mode';
  static const String errorApplyingOverride = 'Invalid unit value';
  static const String errorDisablingOverride = 'Failed to disable override';
  static const String errorNetworkIssue = 'Network error. Using cached data.';
  
  // ===== SUCCESS MESSAGES =====
  
  static const String successRefresh = 'Dashboard refreshed';
  static const String successOutageToggled = 'Outage mode updated';
  static const String successOverrideApplied = 'Manual units set';
  static const String successOverrideDisabled = 'Auto-tracking resumed';
  
  // ===== TIME FORMATS =====
  
  /// Format for "Last updated" timestamp
  /// Example: "Today, 10:32 AM"
  static String formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (dateToCheck == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      return '${_formatDate(dateTime)}, ${_formatTime(dateTime)}';
    }
  }
  
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final displayHour = hour == 0 ? 12 : hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$displayHour:$minute $period';
  }
  
  static String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
  
  // ===== HELPER METHODS =====
  
  /// Get color for unit level
  static Color getColorForUnits(double units) {
    if (units > safeUnitsThreshold) {
      return safeColor;
    } else if (units >= moderateUnitsThreshold) {
      return moderateColor;
    } else {
      return dangerColor;
    }
  }
  
  /// Get status label for unit level
  static String getStatusLabelForUnits(double units) {
    if (units > safeUnitsThreshold) {
      return statusSafe;
    } else if (units >= moderateUnitsThreshold) {
      return statusModerate;
    } else if (units >= 5) {
      return statusLow;
    } else {
      return statusCritical;
    }
  }
  
  /// Get icon for unit level
  static IconData getIconForUnits(double units) {
    if (units > safeUnitsThreshold) {
      return Icons.check_circle;
    } else if (units >= moderateUnitsThreshold) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }
}
