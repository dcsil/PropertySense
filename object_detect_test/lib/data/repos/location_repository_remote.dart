import 'package:geocoding/geocoding.dart';
// live location package as ll
import 'package:location/location.dart' as ll;
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/utils/result.dart';

class LocationRepositoryRemote extends LocationRepository {

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
      return Location(
        latitude: data.latitude!,
        longitude: data.longitude!,
        timestamp: DateTime.now(),
      );
    }));
  }
}
