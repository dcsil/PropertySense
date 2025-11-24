import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';
import 'package:object_detect_test/ui/viewmodels/listing_map_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListingMapScreen extends StatelessWidget {
  const ListingMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ListingMapViewModel(
        context.read<LocationRepository>(),
        context.read<ContractorListingRepository>(),
      ),
      child: const ListingMapScreenContent(),
    );
  }
}

class ListingMapScreenContent extends StatelessWidget {
  const ListingMapScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    ListingMapViewModel vm = context.watch<ListingMapViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
      ),
      body: Stack(
        children: [
          _buildMapBody(context, vm),
          // New listing popup - show the first item from the queue
          if (vm.listingPopupQ.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: _NewListingPopup(
                listing: vm.listingPopupQ.first,
                onDismiss: () => _showNextPopup(vm),
                onOfferCreated: (offer) async {
                  await _createOffer(context, vm, offer);
                  _showNextPopup(vm);
                },
                contractorId: 'contractor_id', // Replace with actual contractor ID from your auth/user system
              ),
            ),
        ],
      ),
    );
  }

  void _showNextPopup(ListingMapViewModel vm) {
    if (vm.listingPopupQ.isNotEmpty) {
      vm.addToAlreadyPoppedUp(vm.listingPopupQ.first.id);
      vm.listingPopupQ.removeAt(0);
    }
  }

  Future<void> _createOffer(BuildContext context, ListingMapViewModel vm, Offer offer) async {
    // TODO: Implement offer creation using your repository
    // await vm.createOffer(offer);
  }

  Widget _buildMapBody(BuildContext context, ListingMapViewModel viewModel) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(
          viewModel.currLocation.latitude,
          viewModel.currLocation.longitude,
        ),
        // Zoom ~15 shows roughly a ~1km radius on typical mobile screens
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.propertysense.app',
        ),
        
        // Current location marker
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(
                viewModel.currLocation.latitude,
                viewModel.currLocation.longitude,
              ),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            Marker(
              point: LatLng(
                viewModel.maxLoc == null ? 0.0 : viewModel.maxLoc!.latitude,
                viewModel.maxLoc == null ? 0.0 : viewModel.maxLoc!.longitude,
              ),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            Marker(
              point: LatLng(
                viewModel.minLoc == null ? 0.0 : viewModel.minLoc!.latitude,
                viewModel.minLoc == null ? 0.0 : viewModel.minLoc!.longitude,
              ),
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        
        // Listing markers
        MarkerLayer(
          markers: viewModel.nearbyListings.values.map((listing) {
            return Marker(
              point: LatLng(
                listing.location.latitude,
                listing.location.longitude,
              ),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => context.push('/listing-contractor/${listing.id}'),
                child: _ListingMarker(listing: listing),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ListingMarker extends StatelessWidget {
  final Listing listing;

  const _ListingMarker({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '\$${listing.price.toStringAsFixed(0)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          width: 0,
          height: 0,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 4,
                color: Colors.transparent,
              ),
              right: BorderSide(
                width: 4,
                color: Colors.transparent,
              ),
              top: BorderSide(
                width: 6,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewListingPopup extends StatefulWidget {
  final Listing listing;
  final VoidCallback onDismiss;
  final Function(Offer) onOfferCreated;
  final String contractorId;

  const _NewListingPopup({
    required this.listing,
    required this.onDismiss,
    required this.onOfferCreated,
    required this.contractorId,
  });

  @override
  State<_NewListingPopup> createState() => _NewListingPopupState();
}

class _NewListingPopupState extends State<_NewListingPopup> {
  bool _autoDismissActive = true;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss after 6 seconds unless cancelled
    Future.delayed(const Duration(seconds: 6)).then((_) {
      if (!mounted || !_autoDismissActive) return;
      widget.onDismiss();
    });
  }

  void _cancelAutoDismiss() {
    _autoDismissActive = false;
  }

  void _createQuickOffer(BuildContext context, double price) {
    // Prevent the auto-dismiss callback from firing after user action
    _cancelAutoDismiss();

    final offer = Offer(
      id: '',
      listingId: widget.listing.id,
      contractorId: widget.contractorId,
      offerPrice: price,
      offerDate: Timestamp.fromDate(DateTime.now()),
      message: 'Quick offer submitted via map view',
      status: OfferStatus.pending,
      createdDate: Timestamp.now(),
    );

    widget.onOfferCreated(offer);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer of \$${price.toStringAsFixed(0)} sent!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _autoDismissActive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final basePrice = listing.price;
    final lowerPrice = (basePrice * 0.9).round();
    final higherPrice = (basePrice * 1.1).round();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with dismiss button
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New Job Available!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _cancelAutoDismiss();
                      widget.onDismiss();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Image and title
            GestureDetector(
              onTap: () {
                _cancelAutoDismiss();
                widget.onDismiss();
                context.push('/listing-contractor/${listing.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: listing.imageUrls.isNotEmpty
                        ? Image.network(
                            listing.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              );
                            },
                          )
                        : Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                  ),

                  // Title
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Listed price: \$${basePrice.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Quick offer buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Offer:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _OfferButton(
                          price: lowerPrice.toDouble(),
                          onPressed: () => _createQuickOffer(context, lowerPrice.toDouble()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OfferButton(
                          price: basePrice,
                          onPressed: () => _createQuickOffer(context, basePrice),
                          isHighlighted: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OfferButton(
                          price: higherPrice.toDouble(),
                          onPressed: () => _createQuickOffer(context, higherPrice.toDouble()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferButton extends StatelessWidget {
  final double price;
  final VoidCallback onPressed;
  final bool isHighlighted;

  const _OfferButton({
    required this.price,
    required this.onPressed,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        side: BorderSide(
          color: isHighlighted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Text(
        '\$${price.toStringAsFixed(0)}',
        style: TextStyle(
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          color: isHighlighted
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : null,
        ),
      ),
    );
  }
}