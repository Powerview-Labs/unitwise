import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unitwise/controllers/estimator/appliance_estimator_controller.dart';
import 'package:unitwise/models/appliance_model.dart';
import 'package:unitwise/constants/estimator/estimator_constants.dart';
import 'appliance_row_widget.dart';
import 'add_edit_appliance_dialog.dart';

class ApplianceListWidget extends StatelessWidget {
  final ApplianceEstimatorController controller;
  final bool canEdit;

  const ApplianceListWidget({
    super.key,
    required this.controller,
    this.canEdit = true,
  });

  @override
  Widget build(BuildContext context) {
    final appliances = controller.appliances;

    if (appliances.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No appliances added yet.\nTap "Add Appliance" to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: appliances.length,
      itemBuilder: (context, index) {
        final appliance = appliances[index];
        
        return Dismissible(
          key: Key(appliance.id),
          direction: canEdit ? DismissDirection.endToStart : DismissDirection.none,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: EstimatorConstants.warningRed,
            child: const Icon(Icons.delete, color: Colors.white, size: 32),
          ),
          confirmDismiss: (direction) async => canEdit,
          onDismissed: (direction) {
            if (canEdit) _deleteApplianceWithUndo(context, controller, appliance);
          },
          child: ApplianceRowWidget(
            appliance: appliance,
            onTap: canEdit ? () { _editAppliance(context, controller, appliance); } : () {},
            onDelete: canEdit ? () { _deleteApplianceWithUndo(context, controller, appliance); } : () {},
          ),
        );
      },
    );
  }

  void _editAppliance(BuildContext context, ApplianceEstimatorController controller, Appliance appliance) {
    showDialog(
      context: context,
      builder: (context) => AddEditApplianceDialog(
        appliance: appliance,
      ),
    );
  }

  void _deleteApplianceWithUndo(BuildContext context, ApplianceEstimatorController controller, Appliance appliance) {
    final deletedAppliance = appliance;
    controller.deleteAppliance(appliance.id);
    ScaffoldMessenger.of(context).clearSnackBars();
    
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${appliance.name} deleted', style: const TextStyle(color: Colors.white)),
        backgroundColor: EstimatorConstants.warningRed,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.fixed,
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Colors.white,
          onPressed: () {
            controller.restoreAppliance(deletedAppliance);
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );

    Timer(const Duration(seconds: 5), () {
      try { snackBarController.close(); } catch (e) {}
    });
  }
}