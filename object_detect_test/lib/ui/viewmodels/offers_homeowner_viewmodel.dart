import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class OffersHomeownerViewModel extends ChangeNotifier {
  final ListingRepository _listingRepository;
  final UserRepository _userRepository;

  OffersHomeownerViewModel(this._listingRepository, this._userRepository) {
    _loadOffers();
  }

  List<Offer> _allOffers = [];
  List<Offer> _filteredOffers = [];
  Map<String, Listing> _listingIdMap = {};
  OfferStatus? _selectedFilter;
  bool _isLoading = false;
  String? _errorMessage;

  List<Offer> get filteredOffers => _filteredOffers;
  Map<String, Listing> get listingIdMap => _listingIdMap;
  OfferStatus? get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_userRepository.currentUser == null) {
        Toaster.showError(
          'Could not get offers: please try logging out and back in',
        );
        return;
      }

      final offersResult = await _listingRepository.getOffersForHomeowner(
        _userRepository.currentUser!.id,
      );

      if (offersResult is Failure) {
        Toaster.showErrorFromFailure(offersResult as Failure);
        _errorMessage = (offersResult as Failure).message;
        return;
      }

      _allOffers = (offersResult as Success<List<Offer>>).value;

      // Get all unique listing IDs and fetch listings
      final listingsResult = await _listingRepository.getListingsFromOffers(_allOffers);
      if (listingsResult is Success) {
        _listingIdMap = (listingsResult as Success<Map<String, Listing>>).value;
      }

      _applyFilter();
    } catch (e) {
      _errorMessage = 'Failed to load offers: $e';
      _filteredOffers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(OfferStatus? status) {
    _selectedFilter = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredOffers = List.from(_allOffers);
    } else if (_selectedFilter == OfferStatus.rejected) {
      // "History" includes both rejected and finished
      _filteredOffers = _allOffers
          .where((offer) =>
              offer.status == OfferStatus.rejected ||
              offer.status == OfferStatus.finished)
          .toList();
    } else {
      _filteredOffers = _allOffers
          .where((offer) => offer.status == _selectedFilter)
          .toList();
    }
  }

  Future<void> refreshOffers() async {
    await _loadOffers();
  }

  Future<void> acceptOffer(String offerId, String listingId) async {
    try {
      final result = await _listingRepository.acceptOffer(offerId, listingId);
      if (result is Failure) {
        Toaster.showErrorFromFailure(result as Failure);
      } else {
        Toaster.showSuccess('Offer accepted!');
        await refreshOffers();
      }
    } catch (e) {
      Toaster.showError('Failed to accept offer: $e');
    }
  }

  Future<void> completeAppointment(String offerId, String listingId) async {
    try {
      final result = await _listingRepository.completeAppointment(offerId, listingId);
      if (result is Failure) {
        Toaster.showErrorFromFailure(result as Failure);
      } else {
        Toaster.showSuccess('Appointment completed!');
        await refreshOffers();
      }
    } catch (e) {
      Toaster.showError('Failed to complete appointment: $e');
    }
  }
}