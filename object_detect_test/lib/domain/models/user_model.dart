// https://firebase.google.com/docs/firestore/query-data/get-data
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/domain/models/contractor_details_model.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';

enum UserType { homeowner, contractor }

class User {
  final String id;
  final DateTime createdDate;
  final UserType type;
  final String givenName;
  final String familyName;
  // Assumes that address will always have a corresponding placemark (using geocoding package)
  // We're basically praying that the geocoding PlacemarkFromCoordinates will always return a valid placemark.(Not sure if this is true).
  // Only store geopoint in firestore, but we'll have placemark in memory for easy access to address components.
  final Location location; 
  final Placemark placemark;
  final ContractorDetails? contractorDetails;
  final HomeownerDetails? homeownerDetails;
  final String? profilePhotoUrl;

  User({
    required this.id,
    required this.type,
    required this.createdDate,
    required this.givenName,
    required this.familyName,
    // TODO: figure out how to construct from location
    required this.location,
    required this.placemark,
    this.contractorDetails,
    this.homeownerDetails,
    this.profilePhotoUrl = '',
  });

  // Convert from Firestore map to User
  static Future<User> fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
    ) async {
      final map = snapshot.data();
      return User(
        id: snapshot.id,
        givenName: map?['givenName'] as String,
        familyName: map?['familyName'] as String,
        type: _userTypeFromString(map?['type'] as int),
        createdDate: (map?['createdDate'] as Timestamp).toDate(),
        location: _locationFromGeoPoint(map?['location'] as GeoPoint),
        placemark: await _placemarkFromGeoPoint(map?['location'] as GeoPoint),
        contractorDetails: ContractorDetails.fromMap(map?['contractorDetails'] as Map<String, dynamic>?),
        homeownerDetails: HomeownerDetails.fromMap(map?['homeownerDetails'] as Map<String, dynamic>?),
        profilePhotoUrl: map?['profilePhotoUrl'] as String?,
      );
  }

  // Convert from User to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.index,
      'createdDate': Timestamp.fromDate(createdDate),
      'givenName': givenName,
      'familyName': familyName,
      'location': GeoPoint(location.latitude, location.longitude),
      // We don't store placemark in Firestore
      'contractorDetails': contractorDetails?.toFirestore(),
      'homeownerDetails': homeownerDetails?.toFirestore(),
      'profilePhotoUrl': profilePhotoUrl,
    };
  }

  static UserType _userTypeFromString(int userTypeInt) {
    switch (userTypeInt) {
      case 0:
        return UserType.homeowner;
      case 1:
        return UserType.contractor;
      default:
        throw Exception('Unknown user type: $userTypeInt');
    }
  }

  static Future<Placemark> placemarkFromGeoPoint(GeoPoint geoPoint) async {
    // TODO:
    // Pray that this always returns at least one placemark
    List<Placemark> placemarks = await placemarkFromCoordinates(geoPoint.latitude, geoPoint.longitude);
    return placemarks.first;
  }

  static Location locationFromGeoPoint(GeoPoint geoPoint) {
    return Location(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      timestamp: DateTime.now().toUtc(),
    );
  }
}
