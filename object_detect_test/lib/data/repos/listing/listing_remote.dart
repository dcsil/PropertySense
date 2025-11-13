import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';

class ListingRepositoryRemote implements ListingRepository {
  final FirebaseFirestore _firestore;
  ListingRepositoryRemote({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<Result<List<Listing>>> getListings(String uid) async {
    print(uid);
    try {
      final querySnapshot = await _firestore
        .collection('listings')
        .where('author', isEqualTo: uid)
        .get();

      final listings = querySnapshot.docs
        .map((doc) => Listing.fromFirestore(doc, null))
        .toList();

      return Success(listings);
    } catch (e) {
      print(e);
      return Failure('Failed to fetch listings for user: $e');
    }
  }

  @override
  Future<Result<Listing>> getListing(String listingId) async {
    try {
      final docRef = _firestore.collection('listings').doc(listingId);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return Failure('Listing not found');
      }

      final listing = Listing.fromFirestore(docSnapshot, null);
      return Success(listing);
    } catch (e) {
      return Failure('Failed to fetch listing: $e');
    }
  }

  @override
  Future<Result<void>> createListing(Listing listing) async {
    try {
      await _firestore.collection('listings').add(listing.toFirestore());
      return Success(null);
    } catch (e) {
      return Failure('Failed to create user document: $e');
    }
  }
  
  @override
  Future<Result<void>> deleteListing(String listingId) async {
    try {
      await _firestore.collection('listings').doc(listingId).delete();
      return Success(null);
    } catch (e) {
      return Failure('Failed to delete listing: $e');
    }
  }
  
  
  @override
  Future<Result<void>> updateListingStatus(String listingId, ListingStatus newStatus) async {
    try {
      _firestore
        .collection('listings')
        .doc(listingId)
        .update({'listingStatus': newStatus.index});

      return Success(null);
    } catch (e) {
      return Future.value(Failure('Failed to update listing status: $e'));
    }
  }
} 