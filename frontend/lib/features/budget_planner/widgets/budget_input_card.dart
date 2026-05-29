import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/budget_input_mode.dart';
import '../providers/budget_planner_provider.dart';

/// Card containing input fields for budget amount or target units
/// SECURITY: Enforces numeric-only input with validation
class BudgetInputCard extends StatelessWidget {
  const BudgetInputCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BudgetPlannerProvider>(
      builder: (context, provider, child) {
        final isAmountMode = provider.inputMode == BudgetInputMode.budgetAmount;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Budget Amount Field
                TextField(
                  enabled: isAmountMode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    // SECURITY: Only allow digits and decimal point
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Budget Amount (₦)',
                    hintText: 'Enter amount in Naira',
                    prefixText: '₦ ',
                    errorText: isAmountMode ? provider.budgetAmountError : null,
                    enabled: isAmountMode,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF007BFF),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: isAmountMode ? provider.setBudgetAmount : null,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: isAmountMode ? Colors.black : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 20),

                // OR divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 20),

                // Target Units Field
                TextField(
                  enabled: !isAmountMode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    // SECURITY: Only allow digits and decimal point
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Target Units',
                    hintText: 'Enter desired units',
                    suffixText: 'units',
                    errorText: !isAmountMode ? provider.targetUnitsError : null,
                    enabled: !isAmountMode,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF007BFF),
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: !isAmountMode ? provider.setTargetUnits : null,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                    color: !isAmountMode ? Colors.black : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
