import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_planner_provider.dart';
import '../widgets/input_mode_selector.dart';
import '../widgets/budget_input_card.dart';
import '../widgets/calculation_results_card.dart';
import '../widgets/power_saving_tips_card.dart';
import '../widgets/rate_info_display.dart';
import '../widgets/save_plan_button.dart';

/// Main Budget Planner screen
/// WHY: Advisory planning tool for ₦ ↔ units ↔ days estimation
class BudgetPlannerScreen extends StatelessWidget {
  const BudgetPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Planner'),
        backgroundColor: const Color(0xFF007BFF), // Energy Blue
        actions: [
          // Link to saved plans
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/saved-plans');
            },
            tooltip: 'View Saved Plans',
          ),
        ],
      ),
      body: Consumer<BudgetPlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF007BFF),
              ),
            );
          }

          if (provider.error != null && !provider.dependenciesMet) {
            // This shouldn't happen - gate screen should catch this
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  provider.error!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card with info
                  _buildHeaderCard(context),
                  const SizedBox(height: 16),

                  // Rate info display
                  const RateInfoDisplay(),
                  const SizedBox(height: 16),

                  // Input mode selector (₦ or Units)
                  const InputModeSelector(),
                  const SizedBox(height: 16),

                  // Input card
                  const BudgetInputCard(),
                  const SizedBox(height: 24),

                  // Calculate button
                  _buildCalculateButton(context, provider),
                  const SizedBox(height: 24),

                  // Results section (only show if calculated)
                  if (provider.calculatedUnits != null) ...[
                    const CalculationResultsCard(),
                    const SizedBox(height: 16),

                    // Tips section
                    if (provider.tips.isNotEmpty) ...[
                      const PowerSavingTipsCard(),
                      const SizedBox(height: 16),
                    ],

                    // Save plan button
                    const SavePlanButton(),
                    const SizedBox(height: 16),

                    // Link to adjust appliances
                    _buildAdjustAppliancesLink(context),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF007BFF).withOpacity(0.1),
            const Color(0xFF00C896).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF007BFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calculate_outlined,
            size: 32,
            color: const Color(0xFF007BFF),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan Your Electricity Budget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimate how long your units will last',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontFamily: 'Inter',
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculateButton(
    BuildContext context,
    BudgetPlannerProvider provider,
  ) {
    return ElevatedButton(
      onPressed: provider.canCalculate
          ? () {
              provider.calculate();
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF007BFF), // Energy Blue
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: provider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Calculate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
    );
  }

  Widget _buildAdjustAppliancesLink(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        // Navigate to Appliance Estimator
        Navigator.pushNamed(context, '/appliance-estimator');
      },
      icon: const Icon(Icons.tune),
      label: const Text(
        'Want to reduce your burn rate? Adjust your appliances',
        style: TextStyle(
          fontFamily: 'Inter',
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF007BFF),
      ),
    );
  }
}
