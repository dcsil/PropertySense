import 'package:flutter/material.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
import 'package:provider/provider.dart';

class NameStep extends StatelessWidget {
  const NameStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegistrationViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What\'s your name?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start by getting to know you',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: viewModel.givenName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (value) {
              viewModel.givenName = value;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: viewModel.familyName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (value) {
              viewModel.familyName = value;
            },
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: viewModel.nextStep,
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