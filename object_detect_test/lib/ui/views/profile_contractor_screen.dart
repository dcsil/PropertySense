import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/contractor_details_model.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/ui/viewmodels/profile_contractor_viewmodel.dart';
import 'package:object_detect_test/utils/toaster.dart';
import 'package:provider/provider.dart';

class ProfileContractorScreen extends StatelessWidget {
  const ProfileContractorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileContractorViewModel(
        context.read<AuthRepository>(),
        context.read<UserRepository>(),
        context.read<ContractorListingRepository>(),
      ),
      child: const ProfileContractorContent(),
    );
  }
}

class ProfileContractorContent extends StatefulWidget {
  const ProfileContractorContent({super.key});

  @override
  State<ProfileContractorContent> createState() => _ProfileContractorContentState();
}

class _ProfileContractorContentState extends State<ProfileContractorContent> {
  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _licenseNumberController;
  late TextEditingController _idPhotoUrlController;
  
  late Set<ListingType> _selectedListingTypes;
  late double _radiusMeters;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ProfileContractorViewModel>();
    
    _givenNameController = TextEditingController(text: viewModel.givenName ?? '');
    _familyNameController = TextEditingController(text: viewModel.familyName ?? '');
    _companyNameController = TextEditingController(
      text: viewModel.contractorDetails?.companyName ?? '',
    );
    _licenseNumberController = TextEditingController(
      text: viewModel.contractorDetails?.licenseNumber ?? '',
    );
    _idPhotoUrlController = TextEditingController(
      text: viewModel.contractorDetails?.idPhotoUrl ?? '',
    );
    
    _selectedListingTypes = Set.from(viewModel.listingTypeSet);
    _radiusMeters = viewModel.radiusMeters;
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _companyNameController.dispose();
    _licenseNumberController.dispose();
    _idPhotoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileContractorViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Personal Info
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _givenNameController,
                    decoration: const InputDecoration(
                      labelText: 'Given Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _familyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Family Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contractor Details
                  Text(
                    'Business Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _licenseNumberController,
                    decoration: const InputDecoration(
                      labelText: 'License Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _idPhotoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'ID Photo URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.photo_outlined),
                      hintText: 'Upload ID photo and paste URL',
                    ),
                  ),
                  
                  if (viewModel.contractorDetails?.approvalDate != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Verified Contractor',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Job Preferences
                  Text(
                    'Job Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Job Types
                  Text(
                    'Job Types',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ListingType.values.map((type) {
                      final isSelected = _selectedListingTypes.contains(type);
                      return FilterChip(
                        label: Text(_getListingTypeLabel(type)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedListingTypes.add(type);
                            } else {
                              _selectedListingTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search Radius
                  Text(
                    'Search Radius: ${(_radiusMeters / 1000).toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _radiusMeters,
                    min: 500,
                    max: 10000,
                    divisions: 19,
                    label: '${(_radiusMeters / 1000).toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setState(() {
                        _radiusMeters = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  FilledButton.icon(
                    onPressed: () => _saveProfile(context, viewModel),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sign out button
                  OutlinedButton.icon(
                    onPressed: () => _showSignOutDialog(context, viewModel),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _saveProfile(BuildContext context, ProfileContractorViewModel viewModel) async {
    if (_givenNameController.text.isEmpty || _familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name')),
      );
      return;
    }

    if (_companyNameController.text.isEmpty || 
        _licenseNumberController.text.isEmpty || 
        _idPhotoUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all business details')),
      );
      return;
    }

    if (_selectedListingTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one job type')),
      );
      return;
    }

    final contractorDetails = ContractorDetails(
      companyName: _companyNameController.text,
      licenseNumber: _licenseNumberController.text,
      idPhotoUrl: _idPhotoUrlController.text,
      approvalDate: viewModel.contractorDetails?.approvalDate,
    );

    await viewModel.updateProfile(
      givenName: _givenNameController.text,
      familyName: _familyNameController.text,
      contractorDetails: contractorDetails,
    );
    
    await viewModel.setListingTypeFilter(_selectedListingTypes);
    await viewModel.setRadiusMeters(_radiusMeters);

    if (context.mounted) {
      Toaster.showSuccess('Profile updated successfully');
    }
  }

  Future<void> _showSignOutDialog(BuildContext context, ProfileContractorViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await viewModel.signOut();
      context.go('/');
    }
  }

  String _getListingTypeLabel(ListingType type) {
    switch (type) {
      case ListingType.roofing:
        return 'Roofing';
      case ListingType.exterior:
        return 'Exterior';
      case ListingType.structure:
        return 'Structure';
      case ListingType.electrical:
        return 'Electrical';
      case ListingType.heating:
        return 'Heating';
      case ListingType.cooling:
        return 'Cooling';
      case ListingType.insulation:
        return 'Insulation';
      case ListingType.plumbing:
        return 'Plumbing';
      case ListingType.interior:
        return 'Interior';
    }
  }
}