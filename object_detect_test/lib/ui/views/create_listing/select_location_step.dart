import 'package:flutter/material.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:provider/provider.dart';

class SelectLocationStep extends StatelessWidget {
  const SelectLocationStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
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
        
        TextFormField(
          initialValue: viewModel.location,
          onChanged: viewModel.setLocation,
          decoration: InputDecoration(
            labelText: 'Location',
            hintText: 'Enter city, state or zip code',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                // TODO: Implement get current location
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Getting current location...')),
                );
              },
            ),
            border: const OutlineInputBorder(),
          ),
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
      ],
    );
  }
}