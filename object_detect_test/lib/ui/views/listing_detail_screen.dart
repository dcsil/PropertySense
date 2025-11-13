import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/ui/viewmodels/listing_detail_viewmodel.dart';
import 'package:provider/provider.dart';

class ListingDetailScreen extends StatelessWidget {
  final String listingId;
  
  const ListingDetailScreen({
    super.key,
    required this.listingId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ListingDetailViewModel(
        context.read<ListingRepository>(),
        listingId,
      ),
      child: const ListingDetailScreenContent(),
    );
  }
}

class ListingDetailScreenContent extends StatelessWidget {
  const ListingDetailScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListingDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing Details'),
        actions: [
          if (viewModel.listing != null)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(context, value, viewModel),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(context, viewModel),
    );
  }

  Widget _buildBody(BuildContext context, ListingDetailViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      return Container(
        height: 250,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: PageView.builder(
        itemCount: listing.imageUrls.length,
        itemBuilder: (context, index) {
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
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
      avatar: Icon(
        status.icon,
        size: 18,
        color: status.color,
      ),
      label: Text(
        status.label,
        style: TextStyle(color: status.color),
      ),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          listing.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
              label: 'Author',
              value: listing.author,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ListingDetailViewModel viewModel) {
    final listing = viewModel.listing!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (listing.listingStatus == ListingStatus.draft)
          FilledButton.icon(
            onPressed: () => _updateStatus(context, viewModel, ListingStatus.pending),
            icon: const Icon(Icons.publish),
            label: const Text('Publish Listing'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (listing.listingStatus == ListingStatus.pending) ...[
          FilledButton.icon(
            onPressed: () => _updateStatus(context, viewModel, ListingStatus.done),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Sold'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, viewModel, ListingStatus.draft),
            icon: const Icon(Icons.unpublished),
            label: const Text('Unpublish'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
        if (listing.listingStatus == ListingStatus.done)
          OutlinedButton.icon(
            onPressed: () => _updateStatus(context, viewModel, ListingStatus.pending),
            icon: const Icon(Icons.refresh),
            label: const Text('Relist'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
      ],
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    String action,
    ListingDetailViewModel viewModel,
  ) async {
    switch (action) {
      case 'edit':
        context.push('/listing/${viewModel.listingId}/edit');
        break;
      case 'delete':
        _showDeleteConfirmation(context, viewModel);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ListingDetailViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text('This action cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await viewModel.deleteListing();
        if (context.mounted) {
          context.go('/listings');
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    ListingDetailViewModel viewModel,
    ListingStatus newStatus,
  ) async {
    try {
      await viewModel.updateListingStatus(newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  ({String label, IconData icon, Color color}) _getStatusInfo(ListingStatus status) {
    switch (status) {
      case ListingStatus.draft:
        return (
          label: 'Draft',
          icon: Icons.edit_note,
          color: Colors.grey,
        );
      case ListingStatus.pending:
        return (
          label: 'Available',
          icon: Icons.schedule,
          color: Colors.blue,
        );
      case ListingStatus.done:
        return (
          label: 'Sold',
          icon: Icons.check_circle,
          color: Colors.green,
        );
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}