import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:provider/provider.dart';

class SelectLocationStep extends StatefulWidget {
  const SelectLocationStep({super.key});

  @override
  State<SelectLocationStep> createState() => _SelectLocationStepState();
}

class _SelectLocationStepState extends State<SelectLocationStep> {
  final TextEditingController _searchController = TextEditingController();

  List<Location> _searchResults = [];
  List<Placemark> _placemarks = [];
  bool _isSearching = false;
  Location? _selectedLocation;
  Placemark? _selectedPlacemark;

  @override
  void dispose() {
    _searchController.dispose();
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
      // Get locations from fuzzy address search
      final locations = await locationFromAddress(query);
      
      // Get placemarks for each location
      final placemarks = <Placemark>[];
      for (final location in locations) {
        try {
          debugPrint('Found location: ${location.latitude}, ${location.longitude}');
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find address: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectAddress(int index) {
    setState(() {
      _selectedLocation = _searchResults[index];
      _selectedPlacemark = _placemarks[index];
    });

    final viewModel = context.read<CreateListingViewModel>();
    viewModel.location = _selectedLocation!;
  }

  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street?.isNotEmpty ?? false) {
      parts.add(placemark.street!);
    }
    if (placemark.locality?.isNotEmpty ?? false) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty ?? false) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.postalCode?.isNotEmpty ?? false) {
      parts.add(placemark.postalCode!);
    }
    
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Where do you need this done?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us find contractors in your area',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Location',
              hintText: 'Enter city, state or zip code',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
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
              // Debounce the search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  _searchAddress(value);
                }
              });
            },
            onSubmitted: _searchAddress,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your exact address will not be shared publicly',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No locations found. Try a different search.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            )
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your location:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        final placemark = _placemarks[index];
                        final isSelected = _selectedLocation == location;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1)
                              : null,
                          child: ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(
                              _formatAddress(placemark),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                            onTap: () => _selectAddress(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_searching,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Search for your location above',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}