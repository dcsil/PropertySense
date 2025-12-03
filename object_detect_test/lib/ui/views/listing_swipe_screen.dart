import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/listing/contractor_listing_remote.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/ui/viewmodels/listing_swipe_viewmodel.dart';
import 'package:provider/provider.dart';

class ListingSwipeScreen extends StatelessWidget {
  const ListingSwipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('build ListingSwipeScreen');
    return ChangeNotifierProvider(
      create: (context) => ListingSwipeViewModel(
        context.read<LocationRepository>(),
        context.read<ContractorListingRepository>(),
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
    // Get unseen listings as a list
    final unseenListings = viewModel.nearbyListings;

    if (unseenListings.isEmpty) {
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
        cardsCount: unseenListings.length,
        cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
          final listing = unseenListings[index];
          return _SwipeableListingCard(
            listing: listing,
            viewModel: viewModel,
          );
        },
        onSwipe: (previousIndex, currentIndex, direction) {
          final listing = unseenListings[previousIndex];
          
          if (direction == CardSwiperDirection.left) {
            viewModel.markListingAsDismissed(listing.id);
            return true;
          } else if (direction == CardSwiperDirection.right) {
            viewModel.markListingAsDismissed(listing.id);
            context.push('/listing-contractor/${listing.id}?offer=true');
            return true;
          }
          
          return false;
        },
        isLoop: false,
        numberOfCardsDisplayed: min(3, unseenListings.length),
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
    final distance = ContractorListingRepositoryRemote.calculateDistance(
      viewModel.currLocation.latitude,
      viewModel.currLocation.longitude,
      listing.location.latitude,
      listing.location.longitude,
    );
    print(distance);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listing-contractor/${listing.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image with Hero
            Expanded(
              flex: 3,
              child: Hero(
                tag: 'listing-image-${listing.id}',
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
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }
}