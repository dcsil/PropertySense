import 'package:flutter/material.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/ui/viewmodels/create_listing_viewmodel.dart';
import 'package:provider/provider.dart';

class SelectJobTypeStep extends StatelessWidget {
  const SelectJobTypeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreateListingViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'What kind of job is this?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the type of work you need done',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        ...ListingType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _JobTypeCard(
              type: type,
              isSelected: viewModel.listingType == type,
              onTap: () => viewModel.setListingType(type),
            ),
          );
        }),
      ],
    );
  }
}

class _JobTypeCard extends StatelessWidget {
  final ListingType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _JobTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _getIconForType(type),
                size: 32,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _getLabelForType(type),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(ListingType type) {
    switch (type) {
      case ListingType.roofing:
        return Icons.roofing;
      case ListingType.exterior:
        return Icons.home;
      case ListingType.structure:
        return Icons.foundation;
      case ListingType.electrical:
        return Icons.electrical_services;
      case ListingType.heating:
        return Icons.local_fire_department;
      case ListingType.cooling:
        return Icons.ac_unit;
      case ListingType.insulation:
        return Icons.layers;
      case ListingType.plumbing:
        return Icons.plumbing;
      case ListingType.interior:
        return Icons.chair;
    }
  }

  String _getLabelForType(ListingType type) {
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