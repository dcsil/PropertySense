import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/contractor_details_model.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

// Registration view model for an authenticated user with no user document.
// For both users:
// 1. Enter name
// 2. Select user type (contractor or homeowner)
//  For homeowners:
// 3. Enter address
// 4. Enter address details (unit, etc)
// 5. Review profile and submit
// 6. Redirect to homeowner home page
//  For contractors:
// 3. Upload ID
// 5. Upload business license
// 6. Upload profile photo
// 7. Review profile and submit for review
// 8. Wait for approval page.

enum RegistrationStep {
  name,
  userType,
  address,
  addressDetails,
  identification,
  businessLicense,
  profilePhoto,
  reviewAndSubmitContractor,
  reviewAndSubmitHomeowner,
}

class RegistrationViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  RegistrationStep currentStep = RegistrationStep.name;

  String givenName = '';
  String familyName = '';
  UserType userType = UserType.homeowner;
  Location location = Location(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime.now(),
  );
  Placemark placemark = Placemark();
  // We set createdDetails later
  String profilePhotoUrl = '';

  // Contractor details
  String idPhotoUrl = '';
  String companyName = '';
  String licenseNumber = '';

  // Homeowner details
  UnitType unitType = UnitType.apartment;
  int unitNumber = 0;
  bool isRental = false;

  // We set approvalDate later

  bool isLoading = false;

  User? currentUser;
  StreamSubscription<Result<User?>>? _userSubscription;

  RegistrationViewModel(this._authRepository, this._userRepository) {
    _listenToUserChanges();
  }

  // TODO: Why am I even using streams? Can I just refactor to use provider watch and then re-render on do a callback on notifyListeners?
  void _listenToUserChanges() {
    _userSubscription = _userRepository.userStateChanges().listen((result) {
      // Set isLoading to false when user state changes are received
      isLoading = false;
      switch (result) {
        case Success<User?>():
          currentUser = result.value;
          notifyListeners();
        case Failure():
          Toaster.showError(
            'Could not fetch user data: ${(result as Failure).message}',
          );
      }
    });
  }

  void nextStep() {
    // Validate current step
    if (!_validateCurrentStep()) return;

    switch (currentStep) {
      case RegistrationStep.name:
        currentStep = RegistrationStep.userType;
      case RegistrationStep.userType:
        if (userType == UserType.homeowner) {
          currentStep = RegistrationStep.address;
        } else {
          currentStep = RegistrationStep.identification;
        }
      case RegistrationStep.address:
        currentStep = RegistrationStep.addressDetails;
      case RegistrationStep.addressDetails:
        currentStep = RegistrationStep.reviewAndSubmitHomeowner;
      case RegistrationStep.identification:
        currentStep = RegistrationStep.businessLicense;
      case RegistrationStep.businessLicense:
        currentStep = RegistrationStep.profilePhoto;
      case RegistrationStep.profilePhoto:
        currentStep = RegistrationStep.reviewAndSubmitContractor;
      case RegistrationStep.reviewAndSubmitContractor:
        throw UnimplementedError();
      case RegistrationStep.reviewAndSubmitHomeowner:
        throw UnimplementedError();
    }
    notifyListeners();
  }

  void previousStep() {
    switch (currentStep) {
      case RegistrationStep.userType:
        currentStep = RegistrationStep.name;
      case RegistrationStep.name:
        return; // First step
      case RegistrationStep.address:
        currentStep = RegistrationStep.userType;
      case RegistrationStep.addressDetails:
        currentStep = RegistrationStep.address;
      case RegistrationStep.identification:
        currentStep = RegistrationStep.userType;
      case RegistrationStep.businessLicense:
        currentStep = RegistrationStep.identification;
      case RegistrationStep.profilePhoto:
        currentStep = RegistrationStep.businessLicense;
      case RegistrationStep.reviewAndSubmitContractor:
        currentStep = RegistrationStep.profilePhoto;

      case RegistrationStep.reviewAndSubmitHomeowner:
        currentStep = RegistrationStep.addressDetails;
    }
    notifyListeners();
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case RegistrationStep.name:
        if (givenName.isEmpty || familyName.isEmpty) {
          Toaster.showError('Please enter your full name!');
          return false;
        }
      case RegistrationStep.address:
        // Validate that location is set
        if (location.latitude == 0 && location.longitude == 0) {
          Toaster.showError('Please enter a valid address!');
          return false;
        }
      case RegistrationStep.addressDetails:
      return true;
      // No validation needed
      case RegistrationStep.identification:
        if (idPhotoUrl.isEmpty) {
          Toaster.showError('Please upload your identification photo!');
          return false;
        }
      case RegistrationStep.businessLicense:
        if (companyName.isEmpty ||
            licenseNumber.isEmpty ||
            (location.latitude == 0 && location.longitude == 0)) {
          Toaster.showError(
            'Please ensure your business details are complete and valid!',
          );
          return false;
        }
      case RegistrationStep.profilePhoto:
        if (profilePhotoUrl.isEmpty) {
          Toaster.showError('Please upload your profile photo!');
          return false;
        }
      default:
        return true;
    }
    return true;
  }

  // Get auth UID from the auth repository
  // Verify that user details are all set
  // Create user document in firestore
  Future<void> register() async {
    if (!_validateCurrentStep()) return;

    isLoading = true;
    notifyListeners();

    HomeownerDetails homeownerDetails = HomeownerDetails(
      unitType: unitType,
      unitNumber: unitNumber,
      isRental: isRental,
    );

    ContractorDetails? contractorDetails;

    // Verify if user is contractor that details aren't null and instantiate object
    if (userType == UserType.contractor) {
      // TODO
      // This should never happen
      if (idPhotoUrl.isEmpty || companyName.isEmpty || licenseNumber.isEmpty) {
        isLoading = false;
        notifyListeners();
        Toaster.showError('Please complete all contractor details!');
        return;
      }
      contractorDetails = ContractorDetails(
        idPhotoUrl: idPhotoUrl,
        companyName: companyName,
        licenseNumber: licenseNumber,
      );
    }

    // TODO: Kind of hacky, maybe we can handle null better here?
    final currentLoggedInAuth = _authRepository.firebaseAuthInstance.currentUser;
    if (currentLoggedInAuth == null) {
      isLoading = false;
      notifyListeners();
      Toaster.showError('No authenticated user found!');
      return;
    }
    print('test');
    final uid = currentLoggedInAuth.uid;

    User user = User(
      // Get id lazily when we push to firestore
      id: uid,
      givenName: givenName,
      familyName: familyName,
      type: userType,
      // This datetime doesn't matter when we set to firestore it gets ignored
      location: location,
      placemark: placemark,
      createdDate: DateTime.now(),
      contractorDetails: contractorDetails,
      homeownerDetails: homeownerDetails,
      );
    
    print('test2');
    final result = await _userRepository.createUserDocument(user);
    if (result is Failure) {
      isLoading = false;
      notifyListeners();
      Toaster.showErrorFromFailure(result);
      return;
    }
    print('test3');
    final fetchUserResponse = await _userRepository.fetchUser(uid);
    if (fetchUserResponse is Failure) {
      print('test4');
      isLoading = false;
      notifyListeners();
      Toaster.showErrorFromFailure(fetchUserResponse as Failure);
      return;
    }
    isLoading = false;
    notifyListeners();
  }
}