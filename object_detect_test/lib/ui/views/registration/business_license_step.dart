import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
import 'package:provider/provider.dart';

class BusinessLicenseStep extends StatefulWidget {
  const BusinessLicenseStep({super.key});

  @override
  State<BusinessLicenseStep> createState() => _BusinessLicenseStepState();
}

class _BusinessLicenseStepState extends State<BusinessLicenseStep> {
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  List<Location> _searchResults = [];
  List<Placemark> _placemarks = [];
  bool _isSearching = false;
  Location? _selectedLocation;
  Placemark? _selectedPlacemark;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<RegistrationViewModel>();
    _companyNameController.text = viewModel.companyName;
    _licenseNumberController.text = viewModel.licenseNumber;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _licenseNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _placemarks = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final locations = await locationFromAddress(query);
      final placemarks = <Placemark>[];
      
      for (final location in locations) {
        try {
          final locationPlacemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (locationPlacemarks.isNotEmpty) {
            placemarks.add(locationPlacemarks.first);
          }
        } catch (e) {
          debugPrint('Error getting placemark: $e');
        }
      }

      setState(() {
        _searchResults = locations;
        _placemarks = placemarks;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Error searching address: $e');
      setState(() {
        _searchResults = [];
        _placemarks = [];
        _isSearching = false;
      });
    }
  }

  void _selectAddress(int index) {
    setState(() {
      _selectedLocation = _searchResults[index];
      _selectedPlacemark = _placemarks[index];
    });
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street?.isNotEmpty ?? false) parts.add(placemark.street!);
    if (placemark.locality?.isNotEmpty ?? false) parts.add(placemark.locality!);
    if (placemark.administrativeArea?.isNotEmpty ?? false) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode?.isNotEmpty ?? false) {
      parts.add(placemark.postalCode!);
    }
    return parts.join(', ');
  }

  void _saveAndContinue() {
    final viewModel = context.read<RegistrationViewModel>();
    viewModel.companyName = _companyNameController.text;
    viewModel.licenseNumber = _licenseNumberController.text;
    
    if (_selectedLocation != null && _selectedPlacemark != null) {
      viewModel.location = _selectedLocation!;
      viewModel.placemark = _selectedPlacemark!;
    }
    
    viewModel.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegistrationViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Business License',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your business information',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseNumberController,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Business Address',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _addressController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _addressController.clear();
                                setState(() {
                                  _searchResults = [];
                                  _placemarks = [];
                                  _selectedLocation = null;
                                  _selectedPlacemark = null;
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_addressController.text == value) {
                          _searchAddress(value);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final location = _searchResults[index];
                          final placemark = _placemarks[index];
                          final isSelected = _selectedLocation == location;

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on,
                              size: 20,
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : null,
                            ),
                            title: Text(
                              _formatAddress(placemark),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => _selectAddress(index),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _companyNameController.text.isNotEmpty &&
                    _licenseNumberController.text.isNotEmpty &&
                    _selectedLocation != null
                ? _saveAndContinue
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}