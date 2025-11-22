import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingMapViewModel extends ChangeNotifier {
  final ContractorListingRepository _listingRepository;
  final UserRepository _userRepository;
  
  StreamSubscription<List<Listing>>? _bufferSubscription;
  
  ListingMapViewModel(this._listingRepository, this._userRepository) {
    initialize();
  }

  bool _isLoading = false;
  String? _errorMessage;
  Listing? _newListing;
  int _previousListingCount = 0;

  List<Listing> get listings => _listingRepository.listingBuffer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Location get currentLocation => _listingRepository.currentContractorLocation;
  Listing? get newListing => _newListing;
  String get currentUserId => _userRepository.currentUser?.id ?? '';

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_userRepository.currentUser == null) {
        Toaster.showError(
          'Could not get listings for user: please try logging out and back in',
        );
        return;
      }

      if (!_listingRepository.isInitialized) {
        final locationResult = await _listingRepository.initializeLocation();
        if (locationResult is Failure) {
          Toaster.showErrorFromFailure(locationResult as Failure);
          _errorMessage = 'Failed to initialize location';
          return;
        }
      }

      // Initial fetch
      await _listingRepository.getListingsWithinRadiusForBuffer();
      _previousListingCount = _listingRepository.listingBuffer.length;
      
      // Listen to buffer updates
      _bufferSubscription = _listingRepository.bufferStream.listen((updatedListings) {
        // Check if a new listing was added
        if (updatedListings.length > _previousListingCount) {
          // Show the newest listing
          _newListing = updatedListings.last;
        }
        _previousListingCount = updatedListings.length;
        notifyListeners();
      });

      // notify when we get new location
      _listingRepository.locationService.onLocationChanged.listen((locationData) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void dismissNewListing() {
    _newListing = null;
    notifyListeners();
  }

  Future<void> createOffer(Offer offer) async {
    print('Creating offer: ${offer.offerPrice}');
  }

  Future<void> refreshListings() async {
    await _listingRepository.getListingsWithinRadiusForBuffer();
    notifyListeners();
  }

  @override
  void dispose() {
    // _bufferSubscription?.cancel();
    // Because when we get off the page this calls and we don't want that
    // _listingRepository.stopLocationUpdates();
    super.dispose();
  }
}