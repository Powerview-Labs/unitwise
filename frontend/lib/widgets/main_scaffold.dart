import 'package:flutter/material.dart';
import 'package:unitwise/screens/dashboard/dashboard_screen.dart';
import 'package:unitwise/features/token_logger/screens/token_entry_screen.dart';
import 'package:unitwise/widgets/bottom_nav_bar.dart';

/// Main Scaffold with Bottom Navigation
/// 
/// PURPOSE:
/// - Central navigation hub for the app
/// - Manages bottom navigation state
/// - Routes to 5 main sections
/// 
/// SECTIONS:
/// 0. Dashboard (Home)
/// 1. Token Logger
/// 2. Budget Planner (TODO)
/// 3. History (TODO)
/// 4. Settings (TODO)
/// 
/// USAGE:
/// ```dart
/// Navigator.pushReplacement(
///   context,
///   MaterialPageRoute(builder: (_) => MainScaffold(initialIndex: 1)),
/// );
/// ```
class MainScaffold extends StatefulWidget {
  final int initialIndex;

  const MainScaffold({
    super.key,
    this.initialIndex = 0, // Default to Dashboard
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
        // TODO: Budget Planner Screen
        return _buildPlaceholderScreen(
          'Budget Planner',
          'Plan your electricity budget',
          Icons.account_balance_wallet,
        );
      case 3:
        // TODO: History Screen
        return _buildPlaceholderScreen(
          'Token History',
          'View your token purchase history',
          Icons.history,
        );
      case 4:
        // TODO: Settings Screen
        return _buildPlaceholderScreen(
          'Settings',
          'Manage your app settings',
          Icons.settings,
        );
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildPlaceholderScreen(String title, String subtitle, IconData icon) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF007BFF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreen(_currentIndex),
      bottomNavigationBar: UnitWiseBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
