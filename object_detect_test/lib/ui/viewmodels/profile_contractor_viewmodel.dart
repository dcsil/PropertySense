import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/contractor_details_model.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ProfileContractorViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  final ContractorListingRepository _contractorListingRepo;
  
  bool _isLoading = false;
  
  ProfileContractorViewModel(this._authRepo, this._userRepo, this._contractorListingRepo);

  bool get isLoading => _isLoading;
  Set<ListingType> get listingTypeSet => _contractorListingRepo.listingTypeSet;
  double get radiusMeters => _contractorListingRepo.radiusMeters;

  String? get givenName => _userRepo.currentUser?.givenName;
  String? get familyName => _userRepo.currentUser?.familyName;
  ContractorDetails? get contractorDetails => _userRepo.currentUser?.contractorDetails;

  Future<void> setListingTypeFilter(Set<ListingType> types) async {
    final r = await _contractorListingRepo.setListingTypeFilter(types);
    if (r is Failure) {
      Toaster.showErrorFromFailure(r);
    } else {
      notifyListeners();
    }
  }
  
  Future<void> setRadiusMeters(double newRadiusMeters) async {
    final r = await _contractorListingRepo.setRadiusMeters(newRadiusMeters);
    if (r is Failure) {
      Toaster.showErrorFromFailure(r);
    } else {
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String givenName,
    required String familyName,
    required ContractorDetails contractorDetails,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      User currUser = _userRepo.currentUser!;
      User updatedUser = User(
        id: currUser.id,
        type: currUser.type,
        givenName: givenName,
        familyName: familyName,
        contractorDetails: contractorDetails,
        createdDate: currUser.createdDate,
        location: currUser.location,
        placemark: currUser.placemark,
      );
      await _userRepo.updateUserDocument(updatedUser);
    } catch (e) {
      Toaster.showError('Failed to update profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final r = await _authRepo.signOut();
    if (r is Failure) {
      Toaster.showErrorFromFailure(r);
    }
  }
}