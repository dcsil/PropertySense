import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/ui/viewmodels/listing_swipe_viewmodel.dart';
import 'package:provider/provider.dart';

class ListingSwipeScreen extends StatelessWidget {
  const ListingSwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ListingSwipeViewModel(
        context.read<ContractorListingRepository>(),
        context.read<UserRepository>(),
      ),
      child: const ListingSwipeScreenContents(),
    );
  }
}

class ListingSwipeScreenContents extends StatelessWidget {
  const ListingSwipeScreenContents({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ListingSwipeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Jobs'),
      ),
      body: _buildSwipeBody(context, viewModel),
    );
  }

  Widget _buildSwipeBody(BuildContext context, ListingSwipeViewModel viewModel) {
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

    if (viewModel.listings.isEmpty) {
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
              'No listings nearby',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new opportunities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CardSwiper(
        cardsCount: viewModel.listings.length,
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          final listing = viewModel.listings[index];
          return _SwipeableListingCard(
            listing: listing,
            viewModel: viewModel,
          );
        },
        onSwipe: (previousIndex, currentIndex, direction) {
          final listing = viewModel.listings[previousIndex];
          
          if (direction == CardSwiperDirection.left) {
            viewModel.markListingAsSeen(listing.id);
            return true;
          } else if (direction == CardSwiperDirection.right) {
            viewModel.markListingAsSeen(listing.id);
            context.push('/send-offer/${listing.id}');
            return true;
          }
          
          return false;
        },
        isLoop: false,
        numberOfCardsDisplayed: min(3, viewModel.listings.length),
      ),
    );
  }
}

class _SwipeableListingCard extends StatelessWidget {
  final Listing listing;
  final ListingSwipeViewModel viewModel;

  const _SwipeableListingCard({
    required this.listing,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final distance = _calculateDistance(
      viewModel.currentLocation.latitude,
      viewModel.currentLocation.longitude,
      listing.location.latitude,
      listing.location.longitude,
    );

    return Hero(
      tag: 'listing-${listing.id}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/listing/${listing.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              Expanded(
                flex: 3,
                child: listing.imageUrls.isNotEmpty
                    ? Image.network(
                        listing.imageUrls.first,
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
                      )
                    : Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),

              // Content
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        listing.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${listing.price.toStringAsFixed(0)} · ${_formatDistance(distance)} from you',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}