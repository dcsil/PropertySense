import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
import 'package:provider/provider.dart';

class AddressDetailsStep extends StatefulWidget {
  const AddressDetailsStep({super.key});

  @override
  State<AddressDetailsStep> createState() => _AddressDetailsStepState();
}

class _AddressDetailsStepState extends State<AddressDetailsStep> {
  final TextEditingController _unitNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<RegistrationViewModel>();

    // Pre-populate from viewmodel if available
    if (viewModel.unitNumber > 0) {
      _unitNumberController.text = viewModel.unitNumber.toString();
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    super.dispose();
  }

  void _saveDetails() {
    final viewModel = context.read<RegistrationViewModel>();

    // Parse unit number
    final unitNumber = int.tryParse(_unitNumberController.text) ?? 0;
    viewModel.unitNumber = unitNumber;

    viewModel.nextStep();
  }

  String _getUnitTypeLabel(UnitType type) {
    switch (type) {
      case UnitType.apartment:
        return 'Apartment';
      case UnitType.singleFamily:
        return 'Single Family Home';
      case UnitType.multiFamily:
        return 'Multi-Family Home';
      case UnitType.condo:
        return 'Condo';
      case UnitType.townhouse:
        return 'Townhouse';
    }
  }

  String _getFormattedAddress() {
    final viewModel = context.read<RegistrationViewModel>();
    final placemark = viewModel.placemark;
    final parts = <String>[];

    if (placemark.street?.isNotEmpty ?? false) { parts.add(placemark.street!);
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
    final viewModel = context.watch<RegistrationViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Address Details',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add any additional information about your address',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getFormattedAddress(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Unit Type Dropdown
          DropdownButtonFormField<UnitType>(
            value: viewModel.unitType,
            decoration: const InputDecoration(
              labelText: 'Property Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.home),
            ),
            items: UnitType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getUnitTypeLabel(type)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                viewModel.unitType = value;
              }
            },
          ),
          const SizedBox(height: 16),

          // Unit Number Input
          TextFormField(
            controller: _unitNumberController,
            decoration: const InputDecoration(
              labelText: 'Unit/Apartment Number (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.door_front_door_outlined),
              hintText: 'e.g., Apt 5B, Unit 123',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),

          // Is Rental Switch
          // TODO: this is broken but I don't give a shit rn
          // want to get to core feature. Been taking too long just to get auth
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.grey[300]!),
          //     borderRadius: BorderRadius.circular(8),
          //   ),
          //   child: Row(
          //     children: [
          //       const Icon(Icons.key),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Is this a rental property?',
          //               style: Theme.of(context).textTheme.bodyLarge,
          //             ),
          //             Text(
          //               'Are you renting or do you own this property?',
          //               style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                 color: Colors.grey[600],
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //       Switch(
          //         value: viewModel.isRental,
          //         onChanged: (value) {
          //           viewModel.isRental = value;
          //         },
          //       ),
          //     ],
          //   ),
          // ),

          const Spacer(),
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
