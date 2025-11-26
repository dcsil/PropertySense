import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';

import '../../domain/models/auth_model.dart';
import '../../domain/models/user_model.dart';
import '../../utils/result.dart';

// A repository's sole responsibility is to manage application data. 
// A repository is the source of truth for a single type of application data, 
// and it should be the only place where that data type is mutated. 

abstract class AuthRepository {
    fb_auth.FirebaseAuth get firebaseAuthInstance;
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
    Future<Result<void>> updateUserDocument(User user);
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
  Future<Result<List<Offer>>> getOffersForContractor(String uid);
  Future<Result<Map<String, Listing>>> getListingsFromOffers(List<Offer> offers);
}

abstract class LocationRepository {
  Location cachedLocation = Location(latitude: 0.0, longitude: 0.0, timestamp: DateTime.now());
  // FOR DEBUGGING PURPOSES ONLY
  Location? minLoc;
  Location? maxLoc;

  Future<Result<Stream<Location>>> locationStream();
}

abstract class ContractorListingRepository {
  // Returns stream of listings buffers
  Map<String, Listing> cachedListings = {};
  // fuck man I tried to keep this in the viewmodels but the widgets were being bad boys
  // and did not stay persistent (dispose call everytime we just switch pages ffs)
  // so here we are putting the seenListings back in the fucking data sources
  Set<String> dismissedListingIds = {};
  Future<Result<Stream<Map<String, Listing>>>> nearbyListingsBufferStream();
  void markListingAsDismissed(String listingId);
}