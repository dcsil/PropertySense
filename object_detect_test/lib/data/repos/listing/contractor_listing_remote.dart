import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';

class ContractorListingRepositoryRemote extends ContractorListingRepository {

  LocationRepository _locationRepo;
  Map<String, Listing> _listingBuffer = {};
  Location _lastFetchedLocation = Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());

  ContractorListingRepositoryRemote(LocationRepository locationRepo) : _locationRepo = locationRepo;


  // Hopefully returns a stream of listings buffers based on location changes
  Future<Result<Stream<Map<String, Listing>>>> nearbyListingsBufferStream() async {
    final r = await _locationRepo.locationStream(); 
    Stream<Location> locationStream;
    switch (r) {
      case Failure():
        return r as Failure<Stream<Map<String, Listing>>>;
      case Success():
        locationStream = r.value;
    }
    return Success(locationStream.asyncMap((location) async {
      final distance = calculateDistance(
        _lastFetchedLocation.latitude,
        _lastFetchedLocation.longitude,
        location.latitude,
        location.longitude,
      );

      // not to overload firestore, only fetch new listings after 100m diff from last fetched spot.
      if (distance < 10) {
        return _listingBuffer;
      }
      _lastFetchedLocation = location;

      // get new listings from firestore
      final r = await _fetchListingsFromFirestore(location);
      if (r is Failure) {
        debugPrint('Error fetching listings: ${(r as Failure).message}');
        return _listingBuffer;
      }

      Set<String> newDismissedListings = {};
      final newListings = (r as Success<List<Listing>>).value;

      for (final listing in newListings) {
        if (dismissedListingIds.contains(listing.id)) {
          newDismissedListings.add(listing.id);
        }

        if (listingTypeSet.contains(listing.listingType)) {
          // print(listingTypeSet);
          _listingBuffer[listing.id] = listing;
        }
      }

      // Replace with a new Set copy
      dismissedListingIds = Set.from(newDismissedListings);
      cachedListings = _listingBuffer;
      return cachedListings;
    }));
  }

  void markListingAsDismissed(String listingId) {
    dismissedListingIds.add(listingId);
  }

  Result<void> setListingTypeFilter(Set<ListingType> listingTypes) {
    listingTypeSet = listingTypes;
    for (final listingId in cachedListings.keys.toList()) {
      final listing = cachedListings[listingId]!;
      if (!listingTypeSet.contains(listing.listingType)) {
        cachedListings.remove(listingId);
      }
    }
    return Success(null);
  }
  Result<void> setRadiusMeters(double radiusMeters) {
    this.radiusMeters = radiusMeters;
    for (final listingId in cachedListings.keys.toList()) {
      final listing = cachedListings[listingId]!;
      final distance = calculateDistance(
        _lastFetchedLocation.latitude,
        _lastFetchedLocation.longitude,
        listing.location.latitude,
        listing.location.longitude,
      );
      if (distance > radiusMeters) {
        cachedListings.remove(listingId);
      }
    }
    return Success(null);
  }
  /// Fetch listings from Firestore within a bounding box around the given location
  Future<Result<List<Listing>>> _fetchListingsFromFirestore(Location location) async {
    try {
      // Get radius from preferences and convert to degrees
      // double radiusInKm = listingQueryPreferences.radiusInKm;
      // Hardcoding to 100m
      // Use configured radius (km) from preferences
      // double radiusInKm = listingQueryPreferences.radiusInKm;

      // More accurate conversion using earth radius (meters)
      const double earthRadius = 6378137.0;
      double latRad = degreesToRadians(location.latitude);

      // Angular distance in degrees
      double latDelta = (radiusMeters / earthRadius) * (180 / pi);

      // Protect against cos(lat) == 0 near poles
      double cosLat = cos(latRad);
      if (cosLat.abs() < 1e-10) cosLat = 1e-10;
      double lonDelta = (radiusMeters / (earthRadius * cosLat)) * (180 / pi);

      double minLat = location.latitude - latDelta;
      double maxLat = location.latitude + latDelta;
      double minLon = location.longitude - lonDelta;
      double maxLon = location.longitude + lonDelta;

      // print(minLat);
      // print(minLon);
      // print(maxLat);
      // print(maxLon);

      // Query Firestore with bounding box filters
      // TODO: fix when querying from fiji (and intl date line) (someone can ddos us with this shit)
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('latitude', isGreaterThan: minLat)
          .where('latitude', isLessThan: maxLat)
          .where('longitude', isGreaterThan: minLon)
          .where('longitude', isLessThan: maxLon)
          .get();

      // Convert documents to Listing objects
      List<Listing> listings = querySnapshot.docs
          .map((doc) => Listing.fromFirestore(doc, null))
          .toList();

      return Success(listings);
    } catch (e) {
      return Failure('Failed to fetch listings: $e');
    }
  }

  /// Calculate distance between two coordinates in meters using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = degreesToRadians(lat2 - lat1);
    double dLon = degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(degreesToRadians(lat1)) * cos(degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}