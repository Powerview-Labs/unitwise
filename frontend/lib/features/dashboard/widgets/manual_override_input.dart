import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/dashboard_constants.dart';

/// Manual Override Input - Allows user to correct unit balance
///
/// FEATURES:
/// - Two states: Active/Inactive
/// - Active: Shows current value with disable button
/// - Inactive: Shows input field with set button
/// - Numeric keyboard
/// - Input validation
///
/// SECURITY:
/// - Only accepts positive numbers
/// - Validates before submitting
///
/// ✅ BUG #1 FIX: Improved validation and error messages
class ManualOverrideInput extends StatefulWidget {
  final bool isActive;
  final double? currentValue;
  final Function(double) onApply;
  final VoidCallback onDisable;

  const ManualOverrideInput({
    super.key,
    required this.isActive,
    this.currentValue,
    required this.onApply,
    required this.onDisable,
  });

  @override
  State<ManualOverrideInput> createState() => _ManualOverrideInputState();
}

class _ManualOverrideInputState extends State<ManualOverrideInput> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    // Clear previous error
    setState(() => _errorText = null);
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Parse value
    final value = double.tryParse(_controller.text.trim());
    if (value == null) {
      setState(() => _errorText = 'Please enter a valid number');
      return;
    }

    // Additional validation
    if (value < 0) {
      setState(() => _errorText = 'Units cannot be negative');
      return;
    }

    if (value > 10000) {
      setState(() => _errorText = 'Maximum value is 10,000 units');
      return;
    }

    // All validation passed - submit
    setState(() => _isSubmitting = true);
    
    try {
      await widget.onApply(value);
      
      // Success - clear input and reset state
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = null;
        });
        _controller.clear();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Units updated to ${value.toStringAsFixed(1)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Error occurred
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorText = 'Failed to update units. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DashboardConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: widget.isActive
            ? _buildActiveState(context)
            : _buildInactiveState(context),
      ),
    );
  }

  Widget _buildActiveState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit,
              color: DashboardConstants.safeColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DashboardConstants.manualOverrideActive,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.onDisable,
              style: TextButton.styleFrom(
                foregroundColor: DashboardConstants.dangerColor,
              ),
              child: Text(
                DashboardConstants.manualOverrideDisable,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Current units: ${widget.currentValue?.toStringAsFixed(1) ?? 'N/A'}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DashboardConstants.manualOverrideActiveMessage,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildInactiveState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DashboardConstants.manualOverrideTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DashboardConstants.manualOverrideDescription,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        
        // ✅ BUG #1 FIX: Better error display
        if (_errorText != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: DashboardConstants.manualOverrideHint,
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    // ✅ BUG #1 FIX: Show error state visually
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    // ✅ BUG #1 FIX: Allow decimals properly
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  validator: (value) {
                    // Basic validation in the form validator
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a value';
                    }
                    final number = double.tryParse(value.trim());
                    if (number == null) {
                      return 'Invalid number format';
                    }
                    // Detailed validation happens in _handleSubmit
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSubmit(),
                  // ✅ BUG #1 FIX: Clear error on change
                  onChanged: (_) {
                    if (_errorText != null) {
                      setState(() => _errorText = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardConstants.safeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        DashboardConstants.manualOverrideButton,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
        
        // ✅ BUG #1 FIX: Add helpful hint
        const SizedBox(height: 8),
        Text(
          'Example: Enter 50 or 100.5',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}