import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/estimator/appliance_estimator_controller.dart';
import '../../../constants/estimator/estimator_constants.dart';
import '../../../constants/estimator/estimator_strings.dart';
import '../../../utils/estimator/estimator_extensions.dart';

class DailyBurnDisplay extends StatelessWidget {
  const DailyBurnDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ApplianceEstimatorController>(
      builder: (context, controller, child) {
        final totalBurn = controller.totalDailyBurn;
        final consumptionLevel = totalBurn.consumptionLevel();
        final consumptionColor = totalBurn.consumptionColor();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                EstimatorConstants.primaryBlue,
                EstimatorConstants.primaryBlue.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: EstimatorConstants.primaryBlue.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flash_on,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    EstimatorStrings.dailyBurnTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ✅ FIXED: Main value without duplicate "units" label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    totalBurn.toStringAsFixed(1),  // ✅ Just the number
                    style: const TextStyle(
                      fontSize: 42,  // ✅ Slightly smaller to prevent overflow
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'units/day',  // ✅ Single label
                    style: TextStyle(
                      fontSize: 16,  // ✅ Slightly smaller
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Consumption level badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: consumptionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getConsumptionIcon(consumptionLevel),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$consumptionLevel Consumption',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getConsumptionIcon(String level) {
    switch (level) {
      case 'High':
        return Icons.trending_up;
      case 'Moderate':
        return Icons.trending_flat;
      case 'Low':
        return Icons.trending_down;
      default:
        return Icons.flash_on;
    }
  }
}
