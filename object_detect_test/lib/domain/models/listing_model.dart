import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/domain/models/user_model.dart';

enum ListingStatus {
  draft,
  pending,
  done
}

enum ListingType {
  roofing,
  exterior,
  structure,
  electrical,
  heating,
  cooling,
  insulation,
  plumbing,
  interior,
}

class Listing {
  final String id;
  final String author;
  final String title;
  final String description;
  final double price;
  final List<String> imageUrls;
  final ListingStatus listingStatus;
  final ListingType listingType;
  final Location location;
  final Timestamp createdDate;

  Listing({
    required this.id,
    required this.author,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.listingStatus,
    required this.listingType,
    required this.createdDate,
    required this.location,
  });

  // Convert from Firestore map to Listing
  static Listing fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final map = snapshot.data();
    return Listing(
      id: snapshot.id,
      author: map?['author'] as String? ?? '',
      title: map?['title'] as String? ?? '',
      description: map?['description'] as String? ?? '',
      price: (map?['price'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (map?['imageUrls'] as List<dynamic>?)
          ?.map((url) => url as String)
          .toList() ?? [],
      listingStatus: _listingStatusFromInt(map?['listingStatus'] as int? ?? 0),
      listingType: _listingTypeFromInt(map?['listingType'] as int? ?? 0),
      createdDate: map?['createdDate'] as Timestamp? ?? Timestamp.now(),
      // TODO: don't make location from geopoint under User
      location: (() {
        final geo = map?['location'] as GeoPoint?;
        return geo != null
        ? User.locationFromGeoPoint(geo)
        : Location(latitude: 0.0, longitude: 0.0, timestamp: Timestamp.now().toDate());
      })(),
    );
  }

  // Convert from Listing to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'author': author,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'listingStatus': listingStatus.index,
      'listingType': listingType.index,
      'createdDate': createdDate,
      'location': GeoPoint(location.latitude, location.longitude),
    };
  }

  static ListingStatus _listingStatusFromInt(int statusInt) {
    if (statusInt < 0 || statusInt >= ListingStatus.values.length) {
      return ListingStatus.draft;
    }
    return ListingStatus.values[statusInt];
  }

  static ListingType _listingTypeFromInt(int typeInt) {
    if (typeInt < 0 || typeInt >= ListingType.values.length) {
      return ListingType.roofing;
    }
    return ListingType.values[typeInt];
  }
}
