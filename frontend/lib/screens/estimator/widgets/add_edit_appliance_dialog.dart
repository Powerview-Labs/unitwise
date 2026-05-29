/**
 * Add/Edit Appliance Dialog - WITH CATALOG BROWSER
 * 
 * Features:
 * 1. Browse Catalog mode - shows all 33 pre-defined appliances
 * 2. Create Custom mode - manual entry
 * 3. Search & filter by category
 * 4. Tap appliance to select and configure
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/appliance_model.dart';
import '../../../controllers/estimator/appliance_estimator_controller.dart';

class AddEditApplianceDialog extends StatefulWidget {
  final Appliance? appliance;

  const AddEditApplianceDialog({
    super.key,
    this.appliance,
  });

  @override
  State<AddEditApplianceDialog> createState() => _AddEditApplianceDialogState();
}

class _AddEditApplianceDialogState extends State<AddEditApplianceDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  final _nameController = TextEditingController();
  final _wattageController = TextEditingController();
  final _hoursController = TextEditingController();
  final _quantityController = TextEditingController();
  String _selectedCategory = 'Kitchen';
  
  // Catalog browsing
  String _searchQuery = '';
  String _selectedCatalogCategory = 'All';
  Appliance? _selectedCatalogAppliance;

  @override
  void initState() {
    super.initState();
    
    // If editing existing appliance, pre-fill form
    if (widget.appliance != null) {
      _nameController.text = widget.appliance!.name;
      _wattageController.text = widget.appliance!.wattage.toString();
      _hoursController.text = widget.appliance!.hoursPerDay.toString();
      _quantityController.text = widget.appliance!.quantity.toString();
      _selectedCategory = widget.appliance!.category;
    }
    
    // Tab controller: Catalog (0) or Custom (1)
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.appliance != null ? 1 : 0, // If editing, go to custom mode
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _wattageController.dispose();
    _hoursController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  List<Appliance> _getFilteredCatalog(BuildContext context) {
    final controller = context.read<ApplianceEstimatorController>();
    List<Appliance> catalog;
    
    // Filter by category
    if (_selectedCatalogCategory == 'All') {
      catalog = controller.getCatalog();
    } else {
      catalog = controller.getCatalogByCategory(_selectedCatalogCategory);
    }
    
    // Filter by search
    if (_searchQuery.isNotEmpty) {
      catalog = catalog.where((a) {
        return a.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return catalog;
  }

  void _selectCatalogAppliance(Appliance appliance) {
    setState(() {
      _selectedCatalogAppliance = appliance;
      _nameController.text = appliance.name;
      _wattageController.text = appliance.wattage.toString();
      _selectedCategory = appliance.category;
      // Default to 0 hours and quantity 1
      _hoursController.text = '0';
      _quantityController.text = '1';
    });
    
    // Switch to custom tab to configure
    _tabController.animateTo(1);
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ApplianceEstimatorController>();
    
    final appliance = Appliance(
      id: widget.appliance?.id,
      name: _nameController.text.trim(),
      wattage: double.parse(_wattageController.text),
      hoursPerDay: double.parse(_hoursController.text),
      quantity: int.parse(_quantityController.text),
      category: _selectedCategory,
      isCustom: _selectedCatalogAppliance == null, // Custom if not from catalog
    );

    if (widget.appliance != null) {
      controller.updateAppliance(appliance);
    } else {
      controller.addAppliance(appliance);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appliance != null;
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Appliance' : 'Add Appliance',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tabs (only show if adding new)
            if (!isEditing) ...[
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Browse Catalog'),
                  Tab(text: 'Create Custom'),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Content
            Expanded(
              child: isEditing
                  ? _buildCustomForm()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCatalogBrowser(),
                        _buildCustomForm(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogBrowser() {
    return Column(
      children: [
        // Search bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search appliances...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Category chips
        Consumer<ApplianceEstimatorController>(
          builder: (context, controller, _) {
            final categories = ['All', ...controller.getCategories()];
            
            return SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = _selectedCatalogCategory == category;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCatalogCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Catalog grid
        Expanded(
          child: Consumer<ApplianceEstimatorController>(
            builder: (context, controller, _) {
              final catalog = _getFilteredCatalog(context);
              
              if (catalog.isEmpty) {
                return const Center(
                  child: Text('No appliances found'),
                );
              }
              
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85, // Reduced from 0.9 to make even taller
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: catalog.length,
                itemBuilder: (context, index) {
                  final appliance = catalog[index];
                  
                  return _buildCatalogCard(appliance);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogCard(Appliance appliance) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _selectCatalogAppliance(appliance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon based on category
              Icon(
                _getCategoryIcon(appliance.category),
                size: 40,
                color: Colors.blue,
              ),
              
              const SizedBox(height: 8),
              
              // Name
              Text(
                appliance.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Wattage
              Text(
                '${appliance.wattage.toInt()}W',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Category badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appliance.category,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Kitchen':
        return Icons.kitchen;
      case 'Cooling':
        return Icons.ac_unit;
      case 'Lighting':
        return Icons.lightbulb;
      case 'Entertainment':
        return Icons.tv;
      case 'Laundry':
        return Icons.local_laundry_service;
      case 'Heating':
        return Icons.fireplace;
      case 'Electronics':
        return Icons.devices;
      case 'Security':
        return Icons.security;
      default:
        return Icons.electrical_services;
    }
  }

  Widget _buildCustomForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show selected catalog appliance if any
            if (_selectedCatalogAppliance != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(_selectedCatalogAppliance!.category),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${_selectedCatalogAppliance!.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Configure hours and quantity below',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _selectedCatalogAppliance = null;
                          _nameController.clear();
                          _wattageController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Appliance Name *',
                hintText: 'e.g., LED Bulb, Standing Fan',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter appliance name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: [
                'Kitchen',
                'Cooling',
                'Lighting',
                'Entertainment',
                'Laundry',
                'Heating',
                'Electronics',
                'Security',
                'Other',
              ].map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            // Wattage
            TextFormField(
              controller: _wattageController,
              decoration: const InputDecoration(
                labelText: 'Wattage (W) *',
                hintText: 'e.g., 60, 1000',
                border: OutlineInputBorder(),
                suffixText: 'W',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter wattage';
                }
                final wattage = double.tryParse(value);
                if (wattage == null || wattage <= 0) {
                  return 'Please enter a valid wattage';
                }
                if (wattage > 10000) {
                  return 'Wattage seems too high';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Hours per day
            TextFormField(
              controller: _hoursController,
              decoration: const InputDecoration(
                labelText: 'Hours per Day',
                hintText: '0-24',
                border: OutlineInputBorder(),
                suffixText: 'hrs',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter hours';
                }
                final hours = double.tryParse(value);
                if (hours == null || hours < 0 || hours > 24) {
                  return 'Hours must be between 0-24';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: 'How many?',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity < 1) {
                  return 'Quantity must be at least 1';
                }
                if (quantity > 100) {
                  return 'Quantity seems too high';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(widget.appliance != null ? 'Update' : 'Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
