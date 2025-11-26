import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';
import 'package:object_detect_test/ui/viewmodels/offers_viewmodel.dart';
import 'package:provider/provider.dart';

class OffersOverviewScreen extends StatelessWidget {
  const OffersOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OffersViewModel(
        context.read<ListingRepository>(),
        context.read<UserRepository>(),
      ),
      child: const OffersOverviewScreenContent(),
    );
  }
}

class OffersOverviewScreenContent extends StatelessWidget {
  const OffersOverviewScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OffersViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile-contractor'),
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
                  label: const Text('Offers'),
                  selected: viewModel.selectedFilter == OfferStatus.pending,
                  onSelected: (_) => viewModel.setFilter(OfferStatus.pending),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Appointments'),
                  selected: viewModel.selectedFilter == OfferStatus.accepted,
                  onSelected: (_) => viewModel.setFilter(OfferStatus.accepted),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('History'),
                  selected:
                      viewModel.selectedFilter == OfferStatus.rejected ||
                      viewModel.selectedFilter == OfferStatus.finished,
                  onSelected: (_) => viewModel.setFilter(OfferStatus.rejected),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Offers list
          Expanded(child: _buildOffersBody(context, viewModel)),
        ],
      ),
    );
  }

  Widget _buildOffersBody(BuildContext context, OffersViewModel viewModel) {
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
              onPressed: viewModel.refreshOffers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.filteredOffers.isEmpty) {
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
              'No offers found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateMessage(viewModel.selectedFilter),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.refreshOffers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.filteredOffers.length,
        itemBuilder: (context, index) {
          final offer = viewModel.filteredOffers[index];
          return _OfferCard(
            offer: offer,
            listingTitle: viewModel.listingIdMap[offer.listingId]!.title,
            onTap: () => context.push('/listing-contractor/${offer.listingId}'),
          );
        },
      ),
    );
  }

  String _getEmptyStateMessage(OfferStatus? filter) {
    if (filter == null) return 'No offers yet';
    switch (filter) {
      case OfferStatus.pending:
        return 'No pending offers';
      case OfferStatus.accepted:
        return 'No scheduled appointments';
      case OfferStatus.rejected:
      case OfferStatus.finished:
        return 'No history';
    }
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final String listingTitle;
  final VoidCallback onTap;

  const _OfferCard({required this.offer, required this.listingTitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd');
    final formattedDate = dateFormat.format(offer.createdDate.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(context),
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listing: $listingTitle', // You might want to load the actual listing title
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${offer.offerPrice.toStringAsFixed(0)} · ${_getStatusLabel()} · $formattedDate',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (offer.offerDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Scheduled: ${DateFormat('MMM d, yyyy').format(offer.offerDate!.toDate())}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel() {
    switch (offer.status) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.rejected:
        return 'Rejected';
      case OfferStatus.finished:
        return 'Completed';
    }
  }

  IconData _getStatusIcon() {
    switch (offer.status) {
      case OfferStatus.pending:
        return Icons.schedule;
      case OfferStatus.accepted:
        return Icons.event_available;
      case OfferStatus.rejected:
        return Icons.cancel;
      case OfferStatus.finished:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (offer.status) {
      case OfferStatus.pending:
        return Colors.orange;
      case OfferStatus.accepted:
        return Colors.green;
      case OfferStatus.rejected:
        return Colors.red;
      case OfferStatus.finished:
        return Colors.blue;
    }
  }
}
