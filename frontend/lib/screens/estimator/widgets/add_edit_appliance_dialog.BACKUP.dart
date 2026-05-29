/**
 * Add/Edit Appliance Dialog
 * 
 * Modal dialog for adding new appliance or editing existing one.
 * 
 * Features:
 * - Real-time validation
 * - Input sanitization
 * - Live calculation preview
 * - Accessibility
 * 
 * Security: All inputs validated and sanitized before save
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/appliance_model.dart';
import '../../../controllers/estimator/appliance_estimator_controller.dart';
import '../../../constants/estimator/estimator_constants.dart';
import '../../../constants/estimator/estimator_strings.dart';
import '../../../utils/estimator/estimator_extensions.dart';
import '../../../utils/appliance_calculator.dart';

class AddEditApplianceDialog extends StatefulWidget {
  final Appliance? appliance; // null = add mode, non-null = edit mode

  const AddEditApplianceDialog({
    super.key,
    this.appliance,
  });

  @override
  State<AddEditApplianceDialog> createState() => _AddEditApplianceDialogState();
}

class _AddEditApplianceDialogState extends State<AddEditApplianceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _wattageController = TextEditingController();
  final _hoursController = TextEditingController();
  final _quantityController = TextEditingController();

  String _selectedCategory = 'Other';
  double _previewDailyUnits = 0.0;

  bool get _isEditMode => widget.appliance != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _nameController.text = widget.appliance!.name;
      _wattageController.text = widget.appliance!.wattage.toStringAsFixed(0);
      _hoursController.text = widget.appliance!.hoursPerDay.toStringAsFixed(1);
      _quantityController.text = widget.appliance!.quantity.toString();
      _selectedCategory = widget.appliance!.category;
      _updatePreview();
    }

    // Add listeners for live preview
    _wattageController.addListener(_updatePreview);
    _hoursController.addListener(_updatePreview);
    _quantityController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wattageController.dispose();
    _hoursController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Update preview calculation
  void _updatePreview() {
    final wattage = _wattageController.text.toValidDouble() ?? 0.0;
    final hours = _hoursController.text.toValidDouble() ?? 0.0;
    final quantity = _quantityController.text.toValidInt() ?? 1;

    setState(() {
      _previewDailyUnits = ApplianceCalculator.calculateDailyUnits(
        wattage: wattage,
        adjustedHours: hours,
        quantity: quantity,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildCategoryField(),
                      const SizedBox(height: 16),
                      _buildWattageField(),
                      const SizedBox(height: 16),
                      _buildHoursField(),
                      const SizedBox(height: 16),
                      _buildQuantityField(),
                      const SizedBox(height: 20),
                      _buildPreview(),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            _buildActions(),
          ],
        ),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EstimatorConstants.primaryBlue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditMode ? Icons.edit : Icons.add,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode
                  ? EstimatorStrings.editApplianceTitle
                  : EstimatorStrings.addApplianceTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Build name field
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: EstimatorStrings.nameLabel,
        hintText: EstimatorStrings.nameHint,
        prefixIcon: const Icon(Icons.label_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return EstimatorStrings.validationNameRequired;
        }
        if (value.length > EstimatorConstants.maxNameLength) {
          return EstimatorStrings.validationNameTooLong;
        }
        if (!value.isValidApplianceName()) {
          return EstimatorStrings.validationNameInvalid;
        }
        return null;
      },
    );
  }

  /// Build category dropdown
  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: EstimatorStrings.categoryLabel,
        prefixIcon: const Icon(Icons.category_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: EstimatorConstants.categoryIcons.keys.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                EstimatorConstants.categoryIcons[category],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value!;
        });
      },
    );
  }

  /// Build wattage field
  Widget _buildWattageField() {
    return TextFormField(
      controller: _wattageController,
      decoration: InputDecoration(
        labelText: EstimatorStrings.wattageLabel,
        hintText: EstimatorStrings.wattageHint,
        suffixText: 'W',
        prefixIcon: const Icon(Icons.bolt_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        final wattage = value?.toValidDouble();
        if (wattage == null) {
          return EstimatorStrings.validationWattageRequired;
        }
        if (!wattage.isValidWattage()) {
          if (wattage < EstimatorConstants.minWattage) {
            return EstimatorStrings.validationWattageTooLow;
          } else {
            return EstimatorStrings.validationWattageTooHigh;
          }
        }
        return null;
      },
    );
  }

  /// Build hours field
  Widget _buildHoursField() {
    return TextFormField(
      controller: _hoursController,
      decoration: InputDecoration(
        labelText: EstimatorStrings.hoursLabel,
        hintText: EstimatorStrings.hoursHint,
        suffixText: 'hrs',
        prefixIcon: const Icon(Icons.access_time_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
      ],
      validator: (value) {
        final hours = value?.toValidDouble();
        if (hours == null) {
          return EstimatorStrings.validationHoursRequired;
        }
        if (!hours.isValidHours()) {
          if (hours < EstimatorConstants.minHours) {
            return EstimatorStrings.validationHoursTooLow;
          } else {
            return EstimatorStrings.validationHoursTooHigh;
          }
        }
        return null;
      },
    );
  }

  /// Build quantity field
  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: EstimatorStrings.quantityLabel,
        hintText: EstimatorStrings.quantityHint,
        prefixIcon: const Icon(Icons.format_list_numbered),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        final quantity = value?.toValidInt();
        if (quantity == null) {
          return EstimatorStrings.validationQuantityRequired;
        }
        if (!quantity.isValidQuantity()) {
          if (quantity < EstimatorConstants.minQuantity) {
            return EstimatorStrings.validationQuantityTooLow;
          } else {
            return EstimatorStrings.validationQuantityTooHigh;
          }
        }
        return null;
      },
    );
  }

  /// Build preview
  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EstimatorConstants.accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EstimatorConstants.accentGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.flash_on,
            color: EstimatorConstants.accentGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EstimatorStrings.previewLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewDailyUnits.toUnitsString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: EstimatorConstants.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(EstimatorStrings.cancelButton),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveAppliance,
            style: ElevatedButton.styleFrom(
              backgroundColor: EstimatorConstants.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: Text(_isEditMode
                ? EstimatorStrings.saveButton
                : EstimatorStrings.addButton),
          ),
        ],
      ),
    );
  }

  /// Save appliance
  void _saveAppliance() {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ApplianceEstimatorController>();

    // Security: Sanitize name
    final sanitizedName = _nameController.text.sanitizeApplianceName();

    final appliance = Appliance(
      id: _isEditMode ? widget.appliance!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      name: sanitizedName,
      category: _selectedCategory,
      wattage: _wattageController.text.toValidDouble()!,
      hoursPerDay: _hoursController.text.toValidDouble()!,
      quantity: _quantityController.text.toValidInt()!,
    );

    if (_isEditMode) {
      controller.updateAppliance(appliance);
    } else {
      controller.addAppliance(appliance);
    }

    Navigator.pop(context, true);
  }
}
