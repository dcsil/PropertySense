import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingSwipeViewModel extends ChangeNotifier {

  Location currLocation = Location(latitude: 0, longitude: 0, timestamp: DateTime.now());
  List<Listing> nearbyListings = [];

  StreamSubscription<Location>? _locationSubscription;
  StreamSubscription<Map<String, Listing>>? _listingSubscription;

  // TODO: I really don't want to keep the listingrepository ref here but I need it for markDismissed();
  ContractorListingRepository? _lr;

  ListingSwipeViewModel(
    LocationRepository locationRepository,
    ContractorListingRepository listingRepository, 
    ) {
    _lr = listingRepository;
    streamLocation(locationRepository);
    streamListings(listingRepository);
  }

  void streamLocation(LocationRepository locationRepository) async {
    currLocation = locationRepository.cachedLocation;
    notifyListeners();
    final r = await locationRepository.locationStream();
    switch (r) {
      case Failure():
        Toaster.showErrorFromFailure(r);
      case Success():
        Stream<Location> s = r.value;
        _locationSubscription = s.listen((location) {
          currLocation = location;
          notifyListeners();
        });
    }
  }

  void streamListings(ContractorListingRepository lr) async {
    nearbyListings = processNewListings(lr.cachedListings);
    notifyListeners();
    Result r = await lr.nearbyListingsBufferStream();
    switch (r) {
      case Failure():
        Toaster.showErrorFromFailure(r);
      case Success():
        Stream<Map<String, Listing>> s = r.value; 

        _listingSubscription = s.listen((newListings) {
          nearbyListings = processNewListings(newListings);
          notifyListeners();
        });
    }
  }

  void markListingAsDismissed(String listingId) async {
    _lr!.markListingAsDismissed(listingId);
    nearbyListings.remove(listingId);
    notifyListeners();
  }

  List<Listing> processNewListings(Map<String, Listing> newListings) {
    Map<String, Listing> updatedListings = {};
    for (final kv in newListings.entries){
      final id = kv.key;
      final l = kv.value;
      if (!_lr!.dismissedListingIds.contains(id)) {
        updatedListings[id] = l;
      }
    }
    return updatedListings.values.toList();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _listingSubscription?.cancel();
    super.dispose();
  }
}