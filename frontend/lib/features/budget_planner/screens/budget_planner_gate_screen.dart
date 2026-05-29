import 'package:flutter/material.dart';

/// Gate screen shown when Appliance Estimator is incomplete
/// WHY: Prevents garbage-in-garbage-out calculations
/// SECURITY: Enforces dependency chain (Estimator → Budget Planner)
class BudgetPlannerGateScreen extends StatelessWidget {
  final List<String> missingDependencies;
  final VoidCallback onCompleteSetup;

  const BudgetPlannerGateScreen({
    super.key,
    required this.missingDependencies,
    required this.onCompleteSetup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        backgroundColor: const Color(0xFF007BFF), // Energy Blue
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Setup Required',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Explanation
              Text(
                'To plan your electricity budget accurately, we need some information first.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[700],
                      fontFamily: 'Inter',
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Missing dependencies card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0), // Light amber
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFA726), // Amber
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFFFA726),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Please complete:',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Poppins',
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...missingDependencies.map((dep) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.arrow_right,
                                color: Color(0xFFFFA726),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dep,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'Inter',
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Why this matters
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF007BFF),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Budget estimates are based on your daily burn rate, '
                        'which we calculate from your appliance usage.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[900],
                              fontFamily: 'Inter',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // CTA Button
              ElevatedButton(
                onPressed: onCompleteSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007BFF), // Energy Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  missingDependencies.contains('Appliance Estimator')
                      ? 'Complete Appliance Setup'
                      : 'Complete Setup',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
