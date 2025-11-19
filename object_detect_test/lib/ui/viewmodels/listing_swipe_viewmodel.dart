import 'dart:async';

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
    _initialize();
  }

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<Listing>>? _bufferSubscription;

  List<Listing> get listings => _listingRepository.listingBuffer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Location get currentLocation => _listingRepository.currentContractorLocation;

  Future<void> _initialize() async {
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

      // Initial fetch
      await _listingRepository.getListingsWithinRadiusForBuffer();
      
      // Listen to buffer updates
      _bufferSubscription = _listingRepository.bufferStream.listen((updatedListings) {
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshListings() async {
    await _listingRepository.getListingsWithinRadiusForBuffer();
    notifyListeners();
  }

  void markListingAsSeen(String id) async {
    _listingRepository.markListingAsSeen(id);
  }

  @override
  void dispose() {
    _listingRepository.stopLocationUpdates();
    super.dispose();
  }
}