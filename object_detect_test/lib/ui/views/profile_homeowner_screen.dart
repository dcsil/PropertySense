import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';
import 'package:object_detect_test/ui/viewmodels/profile_homeowner_viewmodel.dart';
import 'package:object_detect_test/utils/toaster.dart';
import 'package:provider/provider.dart';

class ProfileHomeownerScreen extends StatelessWidget {
  const ProfileHomeownerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileHomeownerViewModel(
        context.read<AuthRepository>(),
        context.read<UserRepository>(),
      ),
      child: const ProfileHomeownerContent(),
    );
  }
}

class ProfileHomeownerContent extends StatefulWidget {
  const ProfileHomeownerContent({super.key});

  @override
  State<ProfileHomeownerContent> createState() => _ProfileHomeownerContentState();
}

class _ProfileHomeownerContentState extends State<ProfileHomeownerContent> {
  late TextEditingController _givenNameController;
  late TextEditingController _familyNameController;
  late TextEditingController _unitNumberController;
  
  UnitType? _selectedUnitType;
  bool _isRental = false;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<ProfileHomeownerViewModel>();
    
    _givenNameController = TextEditingController(text: viewModel.givenName ?? '');
    _familyNameController = TextEditingController(text: viewModel.familyName ?? '');
    _unitNumberController = TextEditingController(
      text: viewModel.homeownerDetails?.unitNumber.toString() ?? '',
    );
    
    _selectedUnitType = viewModel.homeownerDetails?.unitType;
    _isRental = viewModel.homeownerDetails?.isRental ?? false;
  }

  @override
  void dispose() {
    _givenNameController.dispose();
    _familyNameController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileHomeownerViewModel>();

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
                  
                  // Property Details
                  Text(
                    'Property Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<UnitType>(
                    value: _selectedUnitType,
                    decoration: const InputDecoration(
                      labelText: 'Unit Type',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home_outlined),
                    ),
                    items: UnitType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getUnitTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUnitType = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _unitNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Unit Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SwitchListTile(
                    title: const Text('Is this a rental property?'),
                    value: _isRental,
                    onChanged: (value) {
                      setState(() {
                        _isRental = value;
                      });
                    },
                    secondary: const Icon(Icons.key),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
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

  Future<void> _saveProfile(BuildContext context, ProfileHomeownerViewModel viewModel) async {
    if (_givenNameController.text.isEmpty || _familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in your name')),
      );
      return;
    }

    if (_selectedUnitType == null || _unitNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all property details')),
      );
      return;
    }

    final unitNumber = int.tryParse(_unitNumberController.text);
    if (unitNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid unit number')),
      );
      return;
    }

    final homeownerDetails = HomeownerDetails(
      unitType: _selectedUnitType!,
      unitNumber: unitNumber,
      isRental: _isRental,
    );

    await viewModel.updateProfile(
      givenName: _givenNameController.text,
      familyName: _familyNameController.text,
      homeownerDetails: homeownerDetails,
    );

    if (context.mounted) {
      Toaster.showSuccess('Profile updated successfully');
    }
  }

  Future<void> _showSignOutDialog(BuildContext context, ProfileHomeownerViewModel viewModel) async {
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
      // removing this await breaks signout...
      // I have no idea but whatever don't have time
      // TODO fix
      await viewModel.signOut();
      context.go('/');
    }
  }

  String _getUnitTypeLabel(UnitType type) {
    switch (type) {
      case UnitType.apartment:
        return 'Apartment';
      case UnitType.singleFamily:
        return 'Single Family';
      case UnitType.multiFamily:
        return 'Multi Family';
      case UnitType.condo:
        return 'Condo';
      case UnitType.townhouse:
        return 'Townhouse';
    }
  }
}