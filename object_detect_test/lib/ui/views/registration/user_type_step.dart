import 'package:flutter/material.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
import 'package:provider/provider.dart';

class UserTypeStep extends StatelessWidget {
  const UserTypeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegistrationViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'I am a...',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your account type',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Column(
              children: [
                _UserTypeCard(
                  title: 'Homeowner',
                  description: 'I need help with my property',
                  icon: Icons.home,
                  isSelected: viewModel.userType == UserType.homeowner,
                  onTap: () {
                    viewModel.userType = UserType.homeowner;
                  },
                ),
                const SizedBox(height: 16),
                _UserTypeCard(
                  title: 'Contractor',
                  description: 'I provide services to homeowners',
                  icon: Icons.construction,
                  isSelected: viewModel.userType == UserType.contractor,
                  onTap: () {
                    viewModel.userType = UserType.contractor;
                    viewModel.notifyListeners();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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

class _UserTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}