import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unitwise/constants/estimator/estimator_constants.dart';

extension BuildContextEstimatorExtensions on BuildContext {
  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    final controller = ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EstimatorConstants.successGreen,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.fixed,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(this).hideCurrentSnackBar(),
        ),
      ),
    );
    Timer(const Duration(seconds: 5), () {
      try { controller.close(); } catch (e) {}
    });
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    final controller = ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EstimatorConstants.warningRed,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.fixed,
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(this).hideCurrentSnackBar(),
        ),
      ),
    );
    Timer(const Duration(seconds: 5), () {
      try { controller.close(); } catch (e) {}
    });
  }

  void showInfoSnackbar(String message) {
    ScaffoldMessenger.of(this).clearSnackBars();
    final controller = ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: EstimatorConstants.primaryBlue,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.fixed,
      ),
    );
    Timer(const Duration(seconds: 3), () {
      try { controller.close(); } catch (e) {}
    });
  }
}

// Add missing double extensions:
extension DoubleEstimatorExtensions on double {
  String consumptionLevel() {
    if (this > 5) return 'High';
    if (this > 2) return 'Moderate';
    return 'Low';
  }

  Color consumptionColor() {
    if (this > 5) return EstimatorConstants.warningRed;
    if (this > 2) return Colors.orange;
    return EstimatorConstants.successGreen;
  }

  String toDisplayString() {
    return '${toStringAsFixed(1)} units/day';
  }
}
