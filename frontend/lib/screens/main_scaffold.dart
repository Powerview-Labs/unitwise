/// main_scaffold.dart
///
/// Main Scaffold with Bottom Navigation — UnitWise
///
/// BUG FIX APPLIED:
///   ✅ BUG 6 — Back arrow appearing in Dashboard, Budget, History, Settings:
///              The scaffold itself has no AppBar — each screen owns its own.
///              Fix is applied by navigating here via pushAndRemoveUntil()
///              so there is NO back stack for Flutter to show a back arrow on.
///              Each individual screen's AppBar also sets
///              automaticallyImplyLeading: false as a belt-and-suspenders fix.
///
/// PRESERVED: Original custom UnitWiseBottomNavBar widget is kept exactly as-is.
/// PRESERVED: _getScreen() switch structure kept exactly as-is.

import 'package:flutter/material.dart';
import 'package:unitwise/features/dashboard/screens/dashboard_screen.dart';
import 'package:unitwise/features/token_logger/screens/token_entry_screen.dart';
import 'package:unitwise/features/budget_planner/budget_planner_navigator.dart';
import 'package:unitwise/features/token_history/screens/token_history_screen.dart';
import 'package:unitwise/features/settings/screens/settings_screen.dart';
import 'package:unitwise/widgets/bottom_nav_bar.dart';

/// Main Scaffold with Bottom Navigation
///
/// PURPOSE:
/// - Central navigation hub for the app
/// - Manages bottom navigation state
/// - Routes to 5 main sections
///
/// ✅ FIXED: Budget Planner now uses BudgetPlannerNavigator instead of placeholder
/// ✅ FIXED: Token History now uses TokenHistoryScreen instead of placeholder
/// ⭐ MODULE 8: Settings now uses SettingsScreen instead of placeholder
/// ✅ BUG 6 FIX: Always navigate here via pushAndRemoveUntil() — no back stack
class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const TokenEntryScreen();
      case 2:
        return const BudgetPlannerNavigator();
      case 3:
        return const TokenHistoryScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ BUG 6 FIX: No AppBar here — each screen owns its own.
      // Back arrow is suppressed at the navigation level:
      // login_screen.dart and password_setup_screen.dart both use
      // pushAndRemoveUntil() to clear the stack before arriving here.
      body: _getScreen(_currentIndex),
      bottomNavigationBar: UnitWiseBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}