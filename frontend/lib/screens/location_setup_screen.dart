/// ==============================================================================
/// 📍 LOCATION SETUP SCREEN - UPDATED FOR MODULE 8 (SETTINGS) INTEGRATION
/// ==============================================================================
///
/// CHANGES IN THIS VERSION:
/// ✅ Creates initial Settings after location setup completes
/// ✅ Navigates to appliance_estimator_prompt (not /appliance-estimator directly)
/// ✅ Updated for Module 4 dashboard integration
/// ✅ Maintains all existing functionality (auto-detect, search, manual entry)
///
/// NAVIGATION FLOW:
/// Location Setup → Create Settings → Appliance Estimator Prompt → [Skip or Setup] → Dashboard
///
/// ==============================================================================

import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/user_service.dart';
import '../config/theme/colors.dart';
// ⭐ MODULE 8: Settings integration
import '../features/settings/services/settings_service.dart';

class LocationSetupScreen extends StatefulWidget {
  final String phoneNumber;
  final String name;
  final String email;

  const LocationSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.name,
    required this.email,
  });

  @override
  State<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends State<LocationSetupScreen> {
  // State variables
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _hasResult = false;
  bool _isSaving = false;
  String? _error;
  Map<String, dynamic>? _locationData;

  // Phase 1 supported DisCos
  final List<String> _phase1Discos = [
    'Ikeja Electric',
    'Eko Electricity Distribution Company',
    'Abuja Electricity Distribution Company',
  ];

  final List<String> _allDiscos = [
    'Abuja Electricity Distribution Company',
    'Benin Electricity Distribution Company',
    'Eko Electricity Distribution Company',
    'Enugu Electricity Distribution Company',
    'Ibadan Electricity Distribution Company',
    'Ikeja Electric',
    'Jos Electricity Distribution',
    'Kaduna Electricity Distribution Company',
    'Kano Electricity Distribution Company',
    'Port Harcourt Electricity Distribution',
    'Yola Electricity Distribution Company',
  ];

  final List<String> _availableBands = ['A', 'B', 'C', 'D', 'E'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Auto-detect location
  Future<void> _detectLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasResult = false;
    });

    try {
      final result = await _locationService.setupUserLocation();
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _locationData = result;
          _hasResult = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Could not detect your location. Please search manually.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try manual search.';
        _isLoading = false;
      });
    }
  }

  // Search location
  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() => _error = 'Please enter an area name');
      return;
    }

    if (query.length < 3) {
      setState(() => _error = 'Please enter at least 3 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasResult = false;
    });

    try {
      final result = await _locationService.manualAreaLookup(query);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _locationData = result;
          _hasResult = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No results found for "$query".';
          _isLoading = false;
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showManualEntryDialog(query);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Search failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  // Manual entry dialog
  void _showManualEntryDialog([String? initialArea]) {
    final isEditing = _locationData != null && _hasResult;
    
    final areaController = TextEditingController(
      text: isEditing ? _locationData!['area'] ?? '' : (initialArea ?? ''),
    );
    final stateController = TextEditingController(
      text: isEditing ? _locationData!['state'] ?? '' : '',
    );
    String? selectedDisco = isEditing ? _locationData!['disco'] : null;
    String? selectedBand = isEditing ? _locationData!['band'] : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Enter Location Manually',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phase 1 info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Perfect in Lagos & Abuja',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Other areas work too - we\'ll add full support soon!',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Area input
                  const Text('Area *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: areaController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., Yaba, Garki, Ikeja',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // State input
                  const Text('State *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: stateController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'e.g., Lagos State, FCT',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // DisCo dropdown
                  const Text('Electricity Provider *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDisco,
                    isDense: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Select your DisCo',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    items: _allDiscos.map((disco) {
                      final isPhase1 = _phase1Discos.contains(disco);
                      return DropdownMenuItem(
                        value: disco,
                        child: Text(
                          disco,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isPhase1 ? FontWeight.w600 : FontWeight.normal,
                            color: isPhase1 ? Colors.green[700] : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedDisco = value),
                  ),
                  const SizedBox(height: 14),

                  // Band dropdown
                  const Text('Service Band *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedBand,
                    isDense: true,
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Select Band',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    items: _availableBands.map((band) {
                      return DropdownMenuItem(
                        value: band,
                        child: Text(
                          'Band $band (${_getBandSupplyHours(band)} hrs/day)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => selectedBand = value),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Tip: Check your meter or bill for DisCo and Band',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (areaController.text.trim().isEmpty ||
                    stateController.text.trim().isEmpty ||
                    selectedDisco == null ||
                    selectedBand == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final manualData = {
                  'area': areaController.text.trim(),
                  'city': areaController.text.trim(),
                  'state': stateController.text.trim(),
                  'country': 'Nigeria',
                  'disco': selectedDisco,
                  'band': selectedBand,
                  'hours': int.parse(_getBandSupplyHours(selectedBand!)),
                  'confidence': 1.0,
                  'latitude': 0.0,
                  'longitude': 0.0,
                  'accuracy': 0.0,
                  'needsManual': false,
                  'source': 'manual_entry',
                  'manualEntry': true,
                  'phase1Supported': _phase1Discos.contains(selectedDisco),
                };

                Navigator.pop(context);

                setState(() {
                  _locationData = manualData;
                  _hasResult = true;
                  _error = null;
                });

                developer.log(
                  'Manual entry: ${manualData['area']} - ${manualData['disco']}',
                  name: 'LocationSetupScreen',
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ⭐ UPDATED: Create initial Settings AND navigate to appliance estimator prompt
  /// This allows user to skip or set up appliances
  Future<void> _confirmAndContinue() async {
    if (_locationData == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      // 1. Save location data to UserService (existing)
      final locationData = {
        'area': _locationData!['area'] ?? '',
        'city': _locationData!['city'] ?? '',
        'state': _locationData!['state'] ?? '',
        'country': _locationData!['country'] ?? 'Nigeria',
        'latitude': _locationData!['latitude'] ?? 0.0,
        'longitude': _locationData!['longitude'] ?? 0.0,
        'detectionMethod': _locationData!['source'] ?? 'manual',
      };

      final discoData = {
        'disco': _locationData!['disco'] ?? 'Unknown',
        'band': _locationData!['band'] ?? 'C',
        'confidence': (_locationData!['confidence'] ?? 1.0).toDouble(),
        'manualOverride': _locationData!['manualEntry'] == true,
      };

      final success = await _userService.saveCompleteLocationSetup(
        locationData: locationData,
        discoData: discoData,
      );

      if (!mounted) return;

        // 1.5. Save basic user profile (name, email, phone)
        await _userService.saveBasicProfile(
          name: widget.name,
          email: widget.email,
          phoneNumber: widget.phoneNumber,
        );

      if (success) {
        // 2. ⭐ MODULE 8: Create initial Settings
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          try {
            final settingsService = SettingsService(userId: userId);
            
            await settingsService.createInitialSettings(
              disco: _locationData!['disco'] ?? 'Unknown',
              band: _locationData!['band'] ?? 'C',
              meterNumber: null, // No meter number at this stage
            );
            
            developer.log(
              '✅ Initial settings created for user $userId',
              name: 'LocationSetupScreen',
            );
          } catch (e) {
            // SECURITY: Settings creation failure is non-blocking
            // User can still proceed, settings can be created later
            developer.log(
              '⚠️ Settings creation failed (non-blocking): $e',
              name: 'LocationSetupScreen',
              level: 900,
            );
          }
        }

        // 3. Background submission (non-blocking)
        if (_locationData!['manualEntry'] == true) {
          _userService
              .submitLocationForReview(
            area: _locationData!['area'],
            state: _locationData!['state'],
            disco: _locationData!['disco'],
            band: _locationData!['band'],
            submittedBy: widget.phoneNumber,
          )
              .catchError((e) {
            developer.log(
              'Background submission failed: $e',
              name: 'LocationSetupScreen',
              level: 900,
            );
            return false;
          });
        }

        // 4. Navigate to appliance estimator prompt
        Navigator.pushReplacementNamed(context, '/appliance-estimator-prompt');
        
      } else {
        setState(() {
          _error = 'Failed to save location. Please try again.';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save. Please try again.';
        _isSaving = false;
      });
    }
  }

  void _editResult() {
    if (_locationData == null) return;
    _showManualEntryDialog(_locationData!['area']);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasResult) {
          setState(() {
            _hasResult = false;
            _locationData = null;
            _error = null;
            _isSaving = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Location Setup'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _hasResult
                  ? _buildResultState()
                  : _buildInputState(),
        ),
      ),
    );
  }

  // UI builders (keeping existing implementation)
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'Getting your location...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInputState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${widget.name}!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s set up your location',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Coverage banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[50]!, Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfect Coverage In:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lagos & Abuja',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Expanding soon!',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detect button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _detectLocation,
              icon: const Icon(Icons.my_location, size: 24),
              label: const Text(
                'Detect My Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

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
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[300])),
            ],
          ),

          const SizedBox(height: 24),

          // Search field
          Text(
            'Search your area',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'e.g., Yaba, Victoria Island, Garki',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                onPressed: _searchLocation,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _searchLocation(),
          ),

          // Error state
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showManualEntryDialog(_searchController.text),
                      icon: const Icon(Icons.edit_location, size: 18),
                      label: const Text('Enter Manually'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultState() {
    if (_locationData == null) return const SizedBox.shrink();

    final area = _locationData!['area'] ?? 'Unknown';
    final state = _locationData!['state'] ?? '';
    final disco = _locationData!['disco'] ?? 'Unknown';
    final band = _locationData!['band'] ?? '?';
    final isManualEntry = _locationData!['manualEntry'] == true;
    final isPhase1 = _phase1Discos.contains(disco);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: Colors.green[600], size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Location Set!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.location_on, 'Location', area),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.map, 'State', state),
                const Divider(height: 32),
                _buildDetailRow(Icons.flash_on, 'Electricity Provider', disco),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.analytics,
                  'Service Band',
                  'Band $band (${_getBandSupplyHours(band)} hrs/day)',
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  Icons.verified,
                  'Coverage',
                  isPhase1 ? 'Full Support' : 'Manual Entry',
                  valueColor: isPhase1 ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),

          if (isManualEntry && !isPhase1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Manual entry saved! We\'ll add full support for your area soon.',
                      style: TextStyle(color: Colors.blue[700], fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _editResult,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _confirmAndContinue,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Confirm & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getBandSupplyHours(String band) {
    const supplyHours = {'A': '20', 'B': '16', 'C': '12', 'D': '8', 'E': '4'};
    return supplyHours[band.toUpperCase()] ?? '12';
  }
}