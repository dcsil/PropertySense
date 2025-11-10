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
    try {
      final querySnapshot = await _firestore
        .collection('listings')
        .where('authorId', isEqualTo: uid)
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
} 