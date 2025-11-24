import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingMapViewModel extends ChangeNotifier {

  Location currLocation = Location(latitude: 0, longitude: 0, timestamp: DateTime.now());
  Map<String, Listing> nearbyListings = {};
  List<Listing> listingPopupQ = [];

  bool isLoading = false;
  String? errorMessage;

  ListingMapViewModel(
    LocationRepository locationRepository,
    ContractorListingRepository listingRepository, 
    ) {
    streamLocation(locationRepository);
    streamListings(listingRepository);
  }

  void streamLocation(LocationRepository locationRepository) async {
    final r = await locationRepository.locationStream();
    switch (r) {
      case Failure():
        Toaster.showErrorFromFailure(r);
      case Success():
        Stream<Location> s = r.value;
        s.listen((location) {
          currLocation = location;
          notifyListeners();
        });
    }
  }

  void streamListings(ContractorListingRepository lr) {
    Result r = lr.nearbyListingsBufferStream();
    switch (r) {
      case Failure():
        Toaster.showErrorFromFailure(r);
      case Success():
        Stream<Map<String, Listing>> s = r.value; 

        s.listen((newListings) {
          for (final kv in newListings.entries){
            final id = kv.key;
            final l = kv.value;

            if (!nearbyListings.containsKey(id)) {
              listingPopupQ.add(l);
            }
            nearbyListings[id] = l;
          }
          isLoading = false;
          errorMessage = null;
          notifyListeners();
        });
    }
  }
}