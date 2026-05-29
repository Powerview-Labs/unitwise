import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'providers/budget_planner_provider.dart';
import 'screens/budget_planner_screen.dart';
import 'screens/budget_planner_gate_screen.dart';

/// Budget Planner Navigator
/// 
/// WHY: Handles dependency checking and initialization before showing Budget Planner
/// SECURITY: Verifies user authentication and required setup completion
/// 
/// Flow:
/// 1. Check if user is authenticated
/// 2. Fetch user profile data (burn rate, DisCo, Band)
/// 3. Initialize BudgetPlannerProvider
/// 4. Show gate screen if dependencies not met
/// 5. Show main Budget Planner screen if all OK
class BudgetPlannerNavigator extends StatefulWidget {
  const BudgetPlannerNavigator({super.key});

  @override
  State<BudgetPlannerNavigator> createState() => _BudgetPlannerNavigatorState();
}

class _BudgetPlannerNavigatorState extends State<BudgetPlannerNavigator> {
  bool _isInitializing = true;
  String? _errorMessage;
  bool _dependenciesMet = false;

  @override
  void initState() {
    super.initState();
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final provider = context.read<BudgetPlannerProvider>();
    
    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (kDebugMode) {
          debugPrint('❌ [BudgetPlannerNavigator] No user logged in');
        }
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Please log in first';
          _dependenciesMet = false;
        });
        return;
      }

      if (kDebugMode) {
        debugPrint('🔵 [BudgetPlannerNavigator] User ID: ${user.uid}');
      }

      // Fetch user profile data
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        if (kDebugMode) {
          debugPrint('❌ [BudgetPlannerNavigator] User profile not found');
        }
        setState(() {
          _isInitializing = false;
          _errorMessage = 'User profile not found';
          _dependenciesMet = false;
        });
        return;
      }

      final userData = userDoc.data()!;

      if (kDebugMode) {
        debugPrint('📊 [BudgetPlannerNavigator] User data keys: ${userData.keys.toList()}');
      }

      // ═══════════════════════════════════════════════════════════
      // CRITICAL FIX: Handle nested disco object
      // ═══════════════════════════════════════════════════════════
      String? discoName;
      String? band;

      final discoData = userData['disco'];
      if (discoData is Map<String, dynamic>) {
        // Nested object format: {name: "Ikeja Electric", band: "A", ...}
        discoName = discoData['name'] as String?;
        band = discoData['band'] as String?;
        
        if (kDebugMode) {
          debugPrint('🔍 [BudgetPlannerNavigator] Extracted from nested disco:');
          debugPrint('   - name: $discoName');
          debugPrint('   - band: $band');
        }
      } else if (discoData is String) {
        // String format (legacy or manual)
        discoName = discoData;
        band = userData['band'] as String?;
        
        if (kDebugMode) {
          debugPrint('🔍 [BudgetPlannerNavigator] Using string disco: $discoName');
          debugPrint('   - band from separate field: $band');
        }
      }

      // Extract burn rate
      final burnRate = userData['daily_burn_estimate'] as double?;
      final cachedRate = userData['current_rate'] as double?;
      final cacheTimestamp = (userData['rate_updated_at'] as Timestamp?)?.toDate();

      // Check if Appliance Estimator is complete
      final applianceComplete = (userData['appliance_setup_completed'] == true) || 
                                 (burnRate != null && burnRate > 0);

      if (kDebugMode) {
        debugPrint('🔍 [BudgetPlannerNavigator] Dependency check:');
        debugPrint('   - burnRate: $burnRate (${burnRate != null && burnRate > 0 ? '✅' : '❌'})');
        debugPrint('   - discoName: $discoName (${discoName != null && discoName.isNotEmpty ? '✅' : '❌'})');
        debugPrint('   - band: $band (${band != null && band.isNotEmpty ? '✅' : '❌'})');
        debugPrint('   - applianceComplete: $applianceComplete (${applianceComplete ? '✅' : '❌'})');
      }

      // Validate all dependencies
      if (!applianceComplete) {
        if (kDebugMode) {
          debugPrint('❌ [BudgetPlannerNavigator] Appliance Estimator not complete');
        }
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Please complete Appliance Estimator first';
          _dependenciesMet = false;
        });
        return;
      }

      if (discoName == null || discoName.isEmpty || band == null || band.isEmpty) {
        if (kDebugMode) {
          debugPrint('❌ [BudgetPlannerNavigator] Location not set');
        }
        setState(() {
          _isInitializing = false;
          _errorMessage = 'Please set your location (DisCo and Band) first';
          _dependenciesMet = false;
        });
        return;
      }

      // All dependencies met - initialize provider
      if (kDebugMode) {
        debugPrint('✅ [BudgetPlannerNavigator] All dependencies met, initializing...');
      }

      await provider.initialize(
        userId: user.uid,
        burnRate: burnRate ?? 0.0,
        disco: discoName,
        band: band,
        cachedRate: cachedRate,
        cacheTimestamp: cacheTimestamp,
      );

      if (kDebugMode) {
        debugPrint('✅ [BudgetPlannerNavigator] Initialization complete');
      }

      setState(() {
        _isInitializing = false;
        _dependenciesMet = true;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ [BudgetPlannerNavigator] Error initializing: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Error loading Budget Planner: $e';
        _dependenciesMet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Budget Planner'),
          backgroundColor: const Color(0xFF007BFF),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF007BFF), // Energy Blue
              ),
              SizedBox(height: 16),
              Text('Loading Budget Planner...'),
            ],
          ),
        ),
      );
    }

    // Show gate screen if dependencies not met
    if (!_dependenciesMet) {
      if (kDebugMode) {
        debugPrint('🚧 [BudgetPlannerNavigator] Showing gate screen');
        debugPrint('   Error: $_errorMessage');
      }
      
      return BudgetPlannerGateScreen(
        missingDependencies: _parseMissingDependencies(_errorMessage),
        onCompleteSetup: () {
          // Navigate to Appliance Estimator
          Navigator.pushReplacementNamed(context, '/appliance-estimator');
        },
      );
    }

    // Show main Budget Planner screen
    if (kDebugMode) {
      debugPrint('✅ [BudgetPlannerNavigator] Showing Budget Planner screen');
    }
    return const BudgetPlannerScreen();
  }

  /// Parse error message to extract missing dependencies
  List<String> _parseMissingDependencies(String? error) {
    if (error == null) return ['Setup required'];
    
    // Try to extract dependency names from error message
    // Example: "Please complete: Appliance Estimator, Location Setup"
    if (error.contains(':')) {
      final parts = error.split(':');
      if (parts.length > 1) {
        return parts[1]
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }
    
    return [error];
  }
}