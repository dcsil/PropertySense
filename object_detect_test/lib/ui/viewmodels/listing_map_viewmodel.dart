import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingMapViewModel extends ChangeNotifier {
  Location currLocation = Location(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime.now(),
  );
  Location? minLoc;
  Location? maxLoc;
  Map<String, Listing> nearbyListings = {};
  List<Listing> listingPopupQ = [];
  Set<String> alreadyPoppedupListings = {};

  StreamSubscription<Location>? _locationSubscription;
  StreamSubscription<Map<String, Listing>>? _listingSubscription;

  ListingMapViewModel(
    LocationRepository locationRepository,
    ContractorListingRepository listingRepository,
  ) {
    streamLocation(locationRepository);
    streamListings(listingRepository);
  }

  void streamLocation(LocationRepository locationRepository) async {
    currLocation = locationRepository.cachedLocation;
    final r = await locationRepository.locationStream();
    switch (r) {
      case Failure():
        Toaster.showErrorFromFailure(r);
      case Success():
        Stream<Location> s = r.value;
        _locationSubscription = s.listen((location) {
          currLocation = location;
          // FOR DEBUGGING
          minLoc = locationRepository.minLoc;
          maxLoc = locationRepository.maxLoc;
          notifyListeners();
        });
    }
  }

  void streamListings(ContractorListingRepository lr) async {
    processNewListings(lr.cachedListings, lr.dismissedListingIds);
    Result r = await lr.nearbyListingsBufferStream();
    switch (r) {
      case Failure():
        Toaster.showErrorFromFailure(r);
      case Success():
        Stream<Map<String, Listing>> s = r.value;

        _listingSubscription = s.listen((newListings) {
          processNewListings(newListings, lr.dismissedListingIds);
          notifyListeners();
        });
    }
  }

  void processNewListings(Map<String, Listing> newListings, Set<String> dismissedIds) {
    Map<String, Listing> updatedListings = {};
    Set<String> newAlreadyPoppedupListings = {};

    for (final kv in newListings.entries){
      final id = kv.key;
      final l = kv.value;
      updatedListings[id] = l;

      if (alreadyPoppedupListings.contains(id)) {
        newAlreadyPoppedupListings.add(id);
      }

      if (!dismissedIds.contains(id) && !alreadyPoppedupListings.contains(id)) {
        listingPopupQ.add(l);
      }
    }
    alreadyPoppedupListings = Set.from(newAlreadyPoppedupListings);
    nearbyListings = updatedListings;
  }

  void addToAlreadyPoppedUp(String listingId) async {
    alreadyPoppedupListings.add(listingId);
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _listingSubscription?.cancel();
    super.dispose();
  }
}
