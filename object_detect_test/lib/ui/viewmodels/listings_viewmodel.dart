import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingsViewModel extends ChangeNotifier {
  final ListingRepository _listingRepository;
  final UserRepository _userRepository;
  
  ListingsViewModel(this._listingRepository, this._userRepository) {
    _loadListings();
  }

  List<Listing> _allListings = [];
  List<Listing> _filteredListings = [];
  ListingStatus? _selectedFilter;
  bool _isLoading = false;
  String? _errorMessage;

  List<Listing> get filteredListings => _filteredListings;
  ListingStatus? get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadListings() async {
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

      final listingResult = await _listingRepository.getListings(_userRepository.currentUser!.id);
      if (listingResult is Failure) {
        Toaster.showErrorFromFailure(listingResult as Failure);
      }

      _allListings = (listingResult as Success).value;
      _applyFilter();
    } catch (e) {
      _errorMessage = 'Failed to load listings: $e';
      _filteredListings = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(ListingStatus? status) {
    _selectedFilter = status;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredListings = List.from(_allListings);
    } else {
      _filteredListings = _allListings
          .where((listing) => listing.listingStatus == _selectedFilter)
          .toList();
    }
  }

  Future<void> refreshListings() async {
    await _loadListings();
  }
}