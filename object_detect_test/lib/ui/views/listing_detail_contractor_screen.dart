import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/ui/viewmodels/listing_detail_contractor_viewmodel.dart';
import 'package:provider/provider.dart';

class ListingDetailContractorScreen extends StatelessWidget {
  final String listingId;
  final bool showOfferDialog;

  const ListingDetailContractorScreen({
    super.key,
    required this.listingId,
    this.showOfferDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ListingDetailContractorViewModel(
        context.read<ListingRepository>(),
        context.read<UserRepository>(),
        listingId,
      ),
      child: ListingDetailContractorScreenContent(
        showOfferDialog: showOfferDialog,
      ),
    );
  }
}

class ListingDetailContractorScreenContent extends StatefulWidget {
  final bool showOfferDialog;

  const ListingDetailContractorScreenContent({
    super.key,
    this.showOfferDialog = false,
  });

  @override
  State<ListingDetailContractorScreenContent> createState() =>
      _ListingDetailContractorScreenContentState();
}

class _ListingDetailContractorScreenContentState
    extends State<ListingDetailContractorScreenContent> {
  @override
  void initState() {
    super.initState();
    
    // Show dialog after first frame if flag is set
    if (widget.showOfferDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final viewModel = context.read<ListingDetailContractorViewModel>();
        _showMakeOfferDialog(context, viewModel);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListingDetailContractorViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(
      BuildContext context, ListingDetailContractorViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: viewModel.refreshListing,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.listing == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Listing not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshListing,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImageGallery(context, viewModel.listing!),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, viewModel.listing!),
                  const SizedBox(height: 16),
                  _buildStatusChip(context, viewModel.listing!),
                  const SizedBox(height: 24),
                  _buildDescription(context, viewModel.listing!),
                  const SizedBox(height: 24),
                  _buildDetails(context, viewModel.listing!),
                  const SizedBox(height: 24),
                  _buildActions(context, viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context, Listing listing) {
    if (listing.imageUrls.isEmpty) {
      return Hero(
        tag: 'listing-image-${listing.id}',
        child: Container(
          height: 250,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.image_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: listing.imageUrls.length,
        itemBuilder: (context, index) {
          // Only wrap the first image with Hero
          if (index == 0) {
            return Hero(
              tag: 'listing-image-${listing.id}',
              child: Image.network(
                listing.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            );
          }

          return Image.network(
            listing.imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          '\$${listing.price.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, Listing listing) {
    final status = _getStatusInfo(listing.listingStatus);

    return Chip(
      avatar: Icon(status.icon, size: 18, color: status.color),
      label: Text(status.label, style: TextStyle(color: status.color)),
      backgroundColor: status.color.withOpacity(0.1),
      side: BorderSide(color: status.color),
    );
  }

  Widget _buildDescription(BuildContext context, Listing listing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(listing.description, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildDetails(BuildContext context, Listing listing) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final formattedDate = dateFormat.format(listing.createdDate.toDate());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.category,
              label: 'Job Type',
              value: _getJobTypeLabel(listing.listingType),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Listed on',
              value: formattedDate,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.person,
              label: 'Homeowner',
              value: listing.author,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
      BuildContext context, ListingDetailContractorViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _showMakeOfferDialog(context, viewModel),
          icon: const Icon(Icons.send),
          label: const Text('Make an Offer'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Future<void> _showMakeOfferDialog(
    BuildContext context,
    ListingDetailContractorViewModel viewModel,
  ) async {
    DateTime? selectedDate;
    final priceController = TextEditingController();
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Make an Offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proposed Completion Date',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        selectedDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    selectedDate != null
                        ? DateFormat('MMMM d, yyyy').format(selectedDate!)
                        : 'Select Date',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Your Offer Price',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Add any additional details...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (selectedDate != null && priceController.text.isNotEmpty) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a date and enter a price'),
                    ),
                  );
                }
              },
              child: const Text('Send Offer'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      try {
        await viewModel.createOffer(double.parse(priceController.text), selectedDate!, messageController.text);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offer sent successfully!')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send offer: $e')),
          );
        }
      }
    }

    priceController.dispose();
    messageController.dispose();
  }

  ({String label, IconData icon, Color color}) _getStatusInfo(
    ListingStatus status,
  ) {
    switch (status) {
      case ListingStatus.draft:
        return (label: 'Draft', icon: Icons.edit_note, color: Colors.grey);
      case ListingStatus.pending:
        return (label: 'Available', icon: Icons.schedule, color: Colors.blue);
      case ListingStatus.done:
        return (label: 'Completed', icon: Icons.check_circle, color: Colors.green);
    }
  }

  String _getJobTypeLabel(ListingType type) {
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}