import 'package:flutter/material.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:io';

class ReviewSubmitContractorStep extends StatelessWidget {
  const ReviewSubmitContractorStep({super.key});

  String _formatAddress(RegistrationViewModel viewModel) {
    final placemark = viewModel.placemark;
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
    final viewModel = context.watch<RegistrationViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Review Your Profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your information before submitting',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your profile will be reviewed by our team. This typically takes 1-2 business days.',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: 'Personal Information'),
                  _InfoCard(
                    children: [
                      if (viewModel.profilePhotoUrl.isNotEmpty)
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.file(
                                File(viewModel.profilePhotoUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      _InfoRow(
                        label: 'Name',
                        value:
                            '${viewModel.givenName} ${viewModel.familyName}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Business Information'),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        label: 'Company Name',
                        value: viewModel.companyName,
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'License Number',
                        value: viewModel.licenseNumber,
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Business Address',
                        value: _formatAddress(viewModel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Documents'),
                  _InfoCard(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Identification',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                if (viewModel.idPhotoUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(viewModel.idPhotoUrl),
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (viewModel.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ElevatedButton(
              onPressed: viewModel.register,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Submit for Review'),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}