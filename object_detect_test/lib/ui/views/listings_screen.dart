import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/ui/viewmodels/listings_viewmodel.dart';
import 'package:provider/provider.dart';

class ListingOverviewScreen extends StatelessWidget {
  const ListingOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ListingsViewModel(
        context.read<ListingRepository>(),
        context.read<UserRepository>()
      ),
      child: const ListingOverviewScreenContent(),
    );
  }
}

class ListingOverviewScreenContent extends StatelessWidget {
  const ListingOverviewScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
      // Trigger a state change by emitting the updated user
    final viewModel = context.watch<ListingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All listings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-listing'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: viewModel.selectedFilter == null,
                  onSelected: (_) => viewModel.setFilter(null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Draft'),
                  selected: viewModel.selectedFilter == ListingStatus.draft,
                  onSelected: (_) => viewModel.setFilter(ListingStatus.draft),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pending'),
                  selected: viewModel.selectedFilter == ListingStatus.pending,
                  onSelected: (_) => viewModel.setFilter(ListingStatus.pending),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Done'),
                  selected: viewModel.selectedFilter == ListingStatus.done,
                  onSelected: (_) => viewModel.setFilter(ListingStatus.done),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Listings list
          Expanded(
            child: _buildListingsBody(context, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsBody(BuildContext context, ListingsViewModel viewModel) {
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
              onPressed: viewModel.refreshListings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.filteredListings.isEmpty) {
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
              'No listings found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first listing to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshListings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.filteredListings.length,
        itemBuilder: (context, index) {
          final listing = viewModel.filteredListings[index];
          return _ListingCard(
            listing: listing,
            onTap: () => context.push('/listing/${listing.id}'),
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;

  const _ListingCard({
    required this.listing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');
    final formattedDate = dateFormat.format(listing.createdDate.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: listing.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          listing.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.image_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${listing.price.toStringAsFixed(0)} · ${_getStatusLabel()} · Listed on $formattedDate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Menu button
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showOptionsMenu(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (listing.listingStatus) {
      case ListingStatus.draft:
        return 'Draft';
      case ListingStatus.pending:
        return 'Available';
      case ListingStatus.done:
        return 'Sold';
    }
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit listing'),
              onTap: () {
                Navigator.pop(context);
                context.push('/listing/${listing.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete listing'),
              onTap: () {
                Navigator.pop(context);
                // Handle delete
              },
            ),
          ],
        ),
      ),
    );
  }
}