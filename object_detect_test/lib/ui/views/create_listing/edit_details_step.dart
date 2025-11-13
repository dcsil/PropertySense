import 'package:flutter/material.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:provider/provider.dart';

class EditDetailsStep extends StatelessWidget {
  const EditDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Add details',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Describe the work you need done',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          initialValue: viewModel.title,
          onChanged: viewModel.setTitle,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Roof repair needed',
            border: OutlineInputBorder(),
          ),
          maxLength: 100,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          initialValue: viewModel.description,
          onChanged: viewModel.setDescription,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe the issue in detail...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          maxLength: 500,
        ),
        const SizedBox(height: 16),
        
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Include specific details like dimensions, materials, and urgency to get better quotes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
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