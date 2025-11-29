import 'dart:math';

import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as ll;
import 'package:object_detect_test/data/repos/listing/contractor_listing_remote.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/utils/result.dart';

class LocationRepositoryRemote extends LocationRepository {
  @override
  Future<Result<Stream<Location>>> locationStream() async {
    ll.Location ls = ll.Location();

    if (!await ls.serviceEnabled() && !await ls.requestService()) {
      return Failure('Location services are disabled.');
    }

    if (await ls.hasPermission() == ll.PermissionStatus.denied &&
        await ls.requestPermission() != ll.PermissionStatus.granted) {
      return Failure('Location permissions are denied');
    }

    return Success(ls.onLocationChanged.map((ll.LocationData data) {
      cachedLocation = Location(
        latitude: data.latitude!,
        longitude: data.longitude!,
        timestamp: DateTime.now(),
      );

      double radiusInKm = 2;
      double radiusMeters = radiusInKm * 1000;

      // More accurate conversion using earth radius (meters)
      const double earthRadius = 6378137.0;
      double latRad = ContractorListingRepositoryRemote.degreesToRadians(cachedLocation.latitude);

      // Angular distance in degrees
      double latDelta = (radiusMeters / earthRadius) * (180 / pi);

      // Protect against cos(lat) == 0 near poles
      double cosLat = cos(latRad);
      if (cosLat.abs() < 1e-10) cosLat = 1e-10;
      double lonDelta = (radiusMeters / (earthRadius * cosLat)) * (180 / pi);

      minLoc = new Location(
        latitude: cachedLocation.latitude - latDelta,
        longitude: cachedLocation.longitude - lonDelta,
        timestamp: DateTime.now(),
      );
      maxLoc = new Location(
        latitude: cachedLocation.latitude + latDelta,
        longitude: cachedLocation.longitude + lonDelta,
        timestamp: DateTime.now(),
      );
      return cachedLocation;
    }));
  }
}
