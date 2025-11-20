import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';

import '../../domain/models/auth_model.dart';
import '../../domain/models/user_model.dart';
import '../../utils/result.dart';

abstract class AuthRepository {
    late fb_auth.FirebaseAuth firebaseAuthInstance;
    Stream<Result<Auth?>> authStateChanges();
    Future<Result<void>> signInWithEmail(String email, String password);
    Future<Result<void>> signInWithGoogle();
    Future<Result<void>> signInWithApple();
    Future<Result<void>> signOut();
    Future<Result<void>> signUpWithEmail(String email, String password);
    Future<Result<void>> sendPasswordResetEmail(String email);
    Future<Result<void>> sendVerificationEmail();
}

abstract class UserRepository {
    User? currentUser;
    Stream<Result<User?>> userStateChanges();
    Future<Result<User?>> fetchUser(String uid);
    Future<Result<void>> createUserDocument(User user);
}

abstract class ListingRepository {
  // TODO: cache listings
  // For homeowners 
  Future<Result<List<Listing>>> getListings(String uid);
  Future<Result<void>> createListing(Listing listing);
  Future<Result<Listing>> getListing(String listingId);
  Future<Result<void>> deleteListing(String listingId);
  Future<Result<void>> updateListingStatus(String listingId, ListingStatus newStatus);
  Future<Result<void>> createListingOffer(String listingId, String contractorId, Offer offer);
}

abstract class ContractorListingRepository {
  // For contractors
  // Storing query preferences client side
  // Future<Result<List<Listing>>> getListingsFromSearchQuery(String query);
  late List<Listing> listingBuffer;
  late Set<String> seenListings;
  late Location currentContractorLocation; 
  late Stream<List<Listing>> bufferStream;
  Future<Result<void>> initializeLocation();
  Future<void> stopLocationUpdates();
  late ListingQueryPreferences listingQueryPreferences;
  Future<Result<void>> getListingsWithinRadiusForBuffer();
  void markListingAsSeen(String id);
}