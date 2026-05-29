import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait minimum 2s so splash is visible
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // No logged-in user → go to welcome screen
      Navigator.of(context).pushReplacementNamed('/welcome');
      return;
    }

    // User is logged in — check if their profile setup is complete
    try {
      final userProfile = await _userService.getUserProfile();

      if (!mounted) return;

      if (userProfile == null) {
        // Profile missing — send to welcome to re-authenticate
        Navigator.of(context).pushReplacementNamed('/welcome');
        return;
      }

      final locationComplete = userProfile['setupCompleted']?['location'] == true;

      if (locationComplete) {
        // Fully set up — go straight to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        // Signed up but didn't finish setup — resume location setup
        Navigator.of(context).pushReplacementNamed(
          '/location-setup',
          arguments: {
            'phoneNumber': userProfile['phone'] ?? '',
            'name': userProfile['name'] ?? '',
            'email': userProfile['email'] ?? '',
          },
        );
      }
    } catch (e) {
      // Something went wrong — fallback to welcome
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF5472D3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0D47A1),
                        Color(0xFF5472D3),
                      ],
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.bolt,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'UnitWise',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}