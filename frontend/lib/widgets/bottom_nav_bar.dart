import 'package:flutter/material.dart';

/// Reusable Bottom Navigation Bar for UnitWise
/// 
/// PURPOSE:
/// - Provides consistent app-wide navigation
/// - Shows 5 main sections: Dashboard, Token, Budget, History, Settings
/// - Highlights current active section
/// 
/// USAGE:
/// ```dart
/// UnitWiseBottomNavBar(
///   currentIndex: 0, // Dashboard
///   onTap: (index) => _navigateToSection(index),
/// )
/// ```
/// 
/// SECURITY:
/// - No sensitive data handled
/// - Pure UI component
class UnitWiseBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const UnitWiseBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed, // Keeps all items visible
      selectedItemColor: const Color(0xFF007BFF), // Energy Blue
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_card),
          label: 'Log Token',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet),
          label: 'Budget',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
