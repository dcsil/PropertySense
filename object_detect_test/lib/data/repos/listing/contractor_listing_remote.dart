import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/location_repository_remote.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';

class ContractorListingRepositoryRemote extends ContractorListingRepository {

  LocationRepository _locationRepo;
  Map<String, Listing> _listingBuffer = {};
  Set<String> _seenListings = {};
  Location _lastFetchedLocation = Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());

  ContractorListingRepositoryRemote(LocationRepository locationRepo) : _locationRepo = locationRepo;


  // Hopefully returns a stream of listings buffers based on location changes
  Result<Stream<Map<String, Listing>>> nearbyListingsBufferStream() {
    final r = _locationRepo.locationStream(); 
    if (r is Failure) {
      return r as Failure<Stream<Map<String, Listing>>>;
    }
    final locationStream = (r as Success<Stream<Location>>).value;

    return Success(locationStream.asyncMap((location) async {
      final distance = _calculateDistance(
        _lastFetchedLocation.latitude,
        _lastFetchedLocation.longitude,
        location.latitude,
        location.longitude,
      );

      // not to overload firestore, only fetch new listings after 100m diff from last fetched spot.
      if (distance < 100) {
        return _listingBuffer;
      }
      _lastFetchedLocation = location;

      // get new listings from firestore
      final r = await _fetchListingsFromFirestore(location);
      if (r is Failure) {
        debugPrint('Error fetching listings: ${(r as Failure).message}');
        return _listingBuffer;
      }

      final newListings = (r as Success<List<Listing>>).value;
      final seenListingsToBeKept = <String>{};

      for (final listing in newListings) {
        if (_seenListings.contains(listing.id)) {
          seenListingsToBeKept.add(listing.id);
        }
        _listingBuffer[listing.id] = listing;
      }

      _seenListings = seenListingsToBeKept;
      return _listingBuffer;
    }));
  }

  void markListingAsSeen(String listingId) async {
    _listingBuffer.remove(listingId);
    _seenListings.add(listingId);
  }

  /// Calculate distance between two coordinates in meters using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // meters
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Fetch listings from Firestore within a bounding box around the given location
  Future<Result<List<Listing>>> _fetchListingsFromFirestore(Location location) async {
    try {
      // Get radius from preferences and convert to degrees
      // double radiusInKm = listingQueryPreferences.radiusInKm;
      // Hardcoding to 100m
      // Use configured radius (km) from preferences
      // double radiusInKm = listingQueryPreferences.radiusInKm;
      double radiusInKm = 1;
      double radiusMeters = radiusInKm * 1000;

      // More accurate conversion using earth radius (meters)
      const double earthRadius = 6378137.0;
      double latRad = _degreesToRadians(location.latitude);

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

      print(minLat);
      print(minLon);
      print(maxLat);
      print(maxLon);

      // Query Firestore with bounding box filters
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('location', isGreaterThanOrEqualTo: new GeoPoint(minLat, minLon))
          .where('location', isLessThanOrEqualTo: new GeoPoint(maxLat, maxLon))
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
}