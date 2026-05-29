// lib/features/token_logger/screens/token_entry_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/token_logger_provider.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/past_purchase_warning.dart';
import '../widgets/unit_preview_card.dart';

/// Token Entry Screen
/// 
/// PURPOSE: Main UI for logging electricity tokens
/// 
/// ✅ UPDATED: Works with bottom navigation
/// ✅ Form clears after successful save
/// ✅ User can log multiple tokens without navigating away
class TokenEntryScreen extends StatefulWidget {
  const TokenEntryScreen({Key? key}) : super(key: key);

  @override
  State<TokenEntryScreen> createState() => _TokenEntryScreenState();
}

class _TokenEntryScreenState extends State<TokenEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _tokenCodeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initialize provider with user data
  Future<void> _initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Should never happen (gated by auth)
      return;
    }

    final provider = context.read<TokenLoggerProvider>();
    await provider.initialize(user.uid);

    // Check for errors
    if (provider.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tokenCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Token'),
        centerTitle: true,
        backgroundColor: const Color(0xFF007BFF), // Energy Blue
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // No back button (using bottom nav)
      ),
      body: Consumer<TokenLoggerProvider>(
        builder: (context, provider, child) {
          // Show loading indicator during initialization
          if (provider.isLoading && provider.disco == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error if initialization failed
          if (provider.errorMessage != null && provider.disco == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => _initialize(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Location info (read-only)
                  _buildLocationInfoCard(provider),
                  
                  const SizedBox(height: 24),

                  // Amount paid input
                  _buildAmountInput(provider),

                  const SizedBox(height: 16),

                  // Purchase date picker
                  _buildDatePicker(provider),

                  const SizedBox(height: 16),

                  // Token code input (optional)
                  _buildTokenCodeInput(provider),

                  const SizedBox(height: 24),

                  // Past purchase warning (if applicable)
                  if (provider.elapsedBurnExplanation != null)
                    PastPurchaseWarning(
                      explanation: provider.elapsedBurnExplanation!,
                    ),

                  // Unit preview card
                  if (provider.unitsPurchased != null)
                    UnitPreviewCard(
                      unitsPurchased: provider.unitsPurchased!,
                      estimatedRemaining: provider.estimatedRemaining!,
                      amountPaid: provider.amountPaid,
                      disco: provider.disco!,
                      band: provider.band!,
                      warning: provider.lowRemainingWarning,
                    ),

                  const SizedBox(height: 24),

                  // Calculate & Save button
                  _buildSaveButton(provider),

                  const SizedBox(height: 16),

                  // Disclaimer
                  _buildDisclaimer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Location info card (DisCo + Band)
  Widget _buildLocationInfoCard(TokenLoggerProvider provider) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.disco ?? 'Unknown DisCo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Band ${provider.band ?? '?'} • ₦${provider.unitRate?.toStringAsFixed(2) ?? '?'}/unit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Amount paid input field
  Widget _buildAmountInput(TokenLoggerProvider provider) {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Amount Paid (₦)',
        hintText: 'Enter amount',
        prefixIcon: Icon(Icons.money),
        border: OutlineInputBorder(),
        helperText: 'Amount between ₦100 - ₦100,000',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter amount';
        }
        final amount = double.tryParse(value);
        if (amount == null) {
          return 'Please enter a valid number';
        }
        if (amount < 100 || amount > 100000) {
          return 'Amount must be between ₦100 and ₦100,000';
        }
        return null;
      },
      onChanged: (value) {
        final amount = double.tryParse(value);
        if (amount != null) {
          provider.setAmountPaid(amount);
        }
      },
    );
  }

  /// Purchase date picker
  Widget _buildDatePicker(TokenLoggerProvider provider) {
    return InkWell(
      onTap: () => _selectDate(context, provider),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Purchase Date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          provider.formattedDate,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Token code input (optional)
  Widget _buildTokenCodeInput(TokenLoggerProvider provider) {
    return TextFormField(
      controller: _tokenCodeController,
      decoration: const InputDecoration(
        labelText: 'Token Code (Optional)',
        hintText: 'Enter token code for reference',
        prefixIcon: Icon(Icons.confirmation_number),
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => provider.setTokenCode(value),
    );
  }

  /// Save button
  Widget _buildSaveButton(TokenLoggerProvider provider) {
    final canSave = provider.canSave && !provider.isLoading;

    return ElevatedButton(
      onPressed: canSave ? () => _handleSave(provider) : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.blue,
        disabledBackgroundColor: Colors.grey.shade300,
      ),
      child: provider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Calculate & Log Token',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  /// Disclaimer text
  Widget _buildDisclaimer() {
    return Text(
      'This is an estimate based on your DisCo tariff and appliance usage. '
      'Actual units may vary.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  /// Handle date selection
  Future<void> _selectDate(
    BuildContext context,
    TokenLoggerProvider provider,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.purchaseDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select Purchase Date',
    );

    if (picked != null && picked != provider.purchaseDate) {
      provider.setPurchaseDate(picked);
    }
  }

  /// Handle save button press
  /// ✅ UPDATED: Clears form after successful save
  Future<void> _handleSave(TokenLoggerProvider provider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        unitsPurchased: provider.unitsPurchased!,
        estimatedRemaining: provider.estimatedRemaining!,
        amountPaid: provider.amountPaid,
        purchaseDate: provider.purchaseDate,
        disco: provider.disco!,
        band: provider.band!,
      ),
    );

    if (confirmed != true) {
      return;
    }

    // Save to Firestore
    final user = FirebaseAuth.instance.currentUser!;
    final success = await provider.saveTokenLog(user.uid);

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Token logged successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ Clear form for next entry
      _amountController.clear();
      _tokenCodeController.clear();
      provider.reset();
      
      // NOTE: User can switch to Dashboard via bottom nav to see updated balance
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Failed to save token log. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}