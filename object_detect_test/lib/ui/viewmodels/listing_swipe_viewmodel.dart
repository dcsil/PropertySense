import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingSwipeViewModel extends ChangeNotifier {
  final ContractorListingRepository _listingRepository;
  final UserRepository _userRepository;
  
  ListingSwipeViewModel(this._listingRepository, this._userRepository) {
    _initializeLocationAndListings();
  }

  List<Listing> _listings = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _seenListingIds = {};

  List<Listing> get listings => _listings;
  int get currentIndex => _currentIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Location get currentLocation => _listingRepository.currentContractorLocation;
  Listing? get currentListing => 
      _listings.isNotEmpty && _currentIndex < _listings.length 
          ? _listings[_currentIndex] 
          : null;

  Future<void> _initializeLocationAndListings() async {
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


      final locationResult = await _listingRepository.initializeLocation();

      if (locationResult is Failure) {
        Toaster.showErrorFromFailure(locationResult as Failure);
        _errorMessage = 'Failed to initialize location';
        return;
      }

      await _loadListings();
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
      _listings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadListings() async {
    try {
      final listingResult = await _listingRepository.getListingsWithinRadiusForBuffer();
      if (listingResult is Failure) {
        Toaster.showErrorFromFailure(listingResult);
        return;
      }

      // Filter out already seen listings
      _listings = _listingRepository.listingBuffer
          .where((listing) => !_seenListingIds.contains(listing.id))
          .toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load listings: $e';
      _listings = [];
      notifyListeners();
    }
  }

  void markListingAsSeen(String listingId) {
    _seenListingIds.add(listingId);
  }

  Future<void> refreshListings() async {
    await _loadListings();
  }

  @override
  void dispose() {
    _listingRepository.stopLocationUpdates();
    super.dispose();
  }
}