import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class ProfileHomeownerViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;
  
  bool _isLoading = false;
  
  ProfileHomeownerViewModel(this._authRepo, this._userRepo);

  bool get isLoading => _isLoading;
  String? get givenName => _userRepo.currentUser?.givenName;
  String? get familyName => _userRepo.currentUser?.familyName;
  HomeownerDetails? get homeownerDetails => _userRepo.currentUser?.homeownerDetails;

  Future<void> updateProfile({
    required String givenName,
    required String familyName,
    required HomeownerDetails homeownerDetails,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: Call repository method to update user profile
      // await _userRepo.updateProfile(givenName, familyName, homeownerDetails);
      
      // For now, just simulate a delay
      await Future.delayed(const Duration(milliseconds: 500));
      
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