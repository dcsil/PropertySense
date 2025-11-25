import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/offer_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class OffersViewModel extends ChangeNotifier {
  final ListingRepository _listingRepository;
  final UserRepository _userRepository;

  OffersViewModel(this._listingRepository, this._userRepository) {
    _loadOffers();
  }

  List<Offer> _allOffers = [];
  List<Offer> _filteredOffers = [];
  OfferStatus? _selectedFilter;
  bool _isLoading = false;
  String? _errorMessage;

  List<Offer> get filteredOffers => _filteredOffers;
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
          'Could not get offers for user: please try logging out and back in',
        );
        return;
      }

      final offerResult = await _listingRepository.getOffersForContractor(
        _userRepository.currentUser!.id,
      );
      
      if (offerResult is Failure) {
        final f = offerResult as Failure;
        Toaster.showErrorFromFailure(f);
        _errorMessage = f.message;
        _filteredOffers = [];
      } else {
        _allOffers = (offerResult as Success<List<Offer>>).value;
        _applyFilter();
      }
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
      // "History" filter includes both rejected and finished
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
}