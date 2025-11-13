import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:provider/provider.dart';

class SetPriceStep extends StatelessWidget {
  const SetPriceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Set your price',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What\'s your budget for this job?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        TextFormField(
          initialValue: viewModel.price?.toStringAsFixed(0),
          onChanged: (value) {
            final price = double.tryParse(value);
            viewModel.setPrice(price);
          },
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            labelText: 'Budget',
            hintText: '0',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        OutlinedButton(
          onPressed: () => viewModel.setPrice(null),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('I don\'t know'),
        ),
        const SizedBox(height: 24),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'About pricing',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Your budget helps contractors understand your expectations\n'
                  '• You can always negotiate the final price\n'
                  '• If unsure, skip this and get quotes from contractors',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}