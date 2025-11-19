import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:location/location.dart' as loc;

class ContractorListingRepositoryRemote extends ContractorListingRepository {
  final FirebaseFirestore _firestore;
  ContractorListingRepositoryRemote({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  late List<Listing> listingBuffer;

  Location _lastFetchedCenter = Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());

  @override
  late Location currentContractorLocation;

  // TODO get this from user data:
  @override
  late ListingQueryPreferences listingQueryPreferences = ListingQueryPreferences(radiusInKm: 1);

  // Track seen listings
  final Set<String> _seenListingIds = {};

  // Internal location service and subscription to keep contractor location up to date
  late loc.Location _locationService;
  StreamSubscription<loc.LocationData>? _locationSubscription;

  /// Initialize location once and start listening for continuous updates.
  Future<Result<void>> initializeLocation() async {
    final loc.Location location = loc.Location();

    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;
    loc.LocationData locationData;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return Failure('Location services are disabled.');
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) {
        return Failure('Location permissions are denied');
      }
    }

    locationData = await location.getLocation();
    currentContractorLocation = Location(
      latitude: locationData.latitude!,
      longitude: locationData.longitude!,
      timestamp: DateTime.now(),
    );
    print(currentContractorLocation);

    // Keep a reference to the location service so we can listen/cancel later
    _locationService = location;

    // Start listening for continuous location updates and update the currentContractorLocation
    _locationSubscription = _locationService.onLocationChanged.listen(
      (loc.LocationData currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          currentContractorLocation = Location(
            latitude: currentLocation.latitude!,
            longitude: currentLocation.longitude!,
            timestamp: DateTime.now(),
          );
          print("updated location: $currentContractorLocation");
          
          // Check if we should fetch new listings
          _checkAndFetchListings();
        }
      },
      onError: (e) {
        return Failure('Error listening to location updates: $e');
        // Swallow errors here; caller can re-run initializeLocation if needed
        // Consider logging if you have a logging mechanism
      },
    );

    return Success(null);
  }

  /// Stop listening to location updates and release resources.
  @override
  Future<void> stopLocationUpdates() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Check distance and fetch listings if needed
  Future<void> _checkAndFetchListings() async {
    double distance = _calculateDistance(
      _lastFetchedCenter.latitude,
      _lastFetchedCenter.longitude,
      currentContractorLocation.latitude,
      currentContractorLocation.longitude,
    );

    if (distance > 100) {
      final result = await _fetchListingsFromFirestore(currentContractorLocation);
      
      if (result is Success<List<Listing>>) {
        final List<Listing> fetchedListings = result.value;

        // Add only unseen listings to buffer
        for (final listing in fetchedListings) {
          if (!_seenListingIds.contains(listing.id)) {
            _seenListingIds.add(listing.id);
            listingBuffer.add(listing);
          }
        }

        // Update last fetched center
        _lastFetchedCenter = currentContractorLocation;
      }
    }
  }

  @override
  Future<Result<void>> getListingsWithinRadiusForBuffer() async {
    // Calculate distance between last fetched location and current location
    double distance = _calculateDistance(
      _lastFetchedCenter.latitude,
      _lastFetchedCenter.longitude,
      currentContractorLocation.latitude,
      currentContractorLocation.longitude,
    );

    // If distance is greater than 100 meters, fetch new listings
    if (distance > 100) {
      final result = await _fetchListingsFromFirestore(currentContractorLocation);
      
      if (result is Failure) {
        return result;
      }

      final List<Listing> fetchedListings = (result as Success<List<Listing>>).value;

      // Add only unseen listings to buffer
      for (final listing in fetchedListings) {
        if (!_seenListingIds.contains(listing.id)) {
          _seenListingIds.add(listing.id);
          listingBuffer.add(listing);
        }
      }

      // Update last fetched center
      _lastFetchedCenter = currentContractorLocation;
    }

    return Success(null);
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
      double radiusInKm = listingQueryPreferences.radiusInKm;
      double latDelta = radiusInKm / 111; // 1 degree latitude ≈ 111km
      double lonDelta = radiusInKm / (111 * cos(_degreesToRadians(location.latitude))); // 1 degree longitude varies by latitude

      double minLat = location.latitude - latDelta;
      double maxLat = location.latitude + latDelta;
      double minLon = location.longitude - lonDelta;
      double maxLon = location.longitude + lonDelta;

      // Query Firestore with bounding box filters
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await _firestore
          .collection('listings')
          .where('latitude', isGreaterThanOrEqualTo: minLat)
          .where('latitude', isLessThanOrEqualTo: maxLat)
          .where('longitude', isGreaterThanOrEqualTo: minLon)
          .where('longitude', isLessThanOrEqualTo: maxLon)
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