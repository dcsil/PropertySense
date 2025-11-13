import 'package:flutter/material.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ListingDetailViewModel extends ChangeNotifier {
  final ListingRepository _listingRepository;
  final String listingId;

  ListingDetailViewModel(this._listingRepository, this.listingId) {
    _loadListing();
  }

  Listing? _listing;
  bool _isLoading = false;
  String? _errorMessage;

  Listing? get listing => _listing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadListing() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _listingRepository.getListing(listingId);

    if (result is Failure) {
      _errorMessage = 'Failed to load listing: ${(result as Failure).message}';
      Toaster.showErrorFromFailure(result as Failure);
    } else {
      _listing = (result as Success).value;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshListing() async {
    await _loadListing();
  }

  Future<void> deleteListing() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _listingRepository.deleteListing(listingId);
    } catch (e) {
      _errorMessage = 'Failed to delete listing: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateListingStatus(ListingStatus newStatus) async {
    if (_listing == null) return;

    _isLoading = true;
    notifyListeners();

    await _listingRepository.updateListingStatus(listingId, newStatus);
    final result = await _listingRepository.getListing(listingId);
    if (result is Failure) {
      _errorMessage =
          'Failed to refresh listing after status update: ${(result as Failure).message}';
      Toaster.showErrorFromFailure(result as Failure);
    } else {
      _listing = (result as Success).value;
    }
    _isLoading = false;
    notifyListeners();
  }
}
