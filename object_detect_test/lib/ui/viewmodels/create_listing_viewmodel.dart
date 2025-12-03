import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class CreateListingViewModel extends ChangeNotifier {
  final ListingRepository _listingRepository;
  final UserRepository _userRepository;
  
  CreateListingViewModel(this._listingRepository, this._userRepository); 

  late String _userId = _userRepository.currentUser?.id ?? '';

  // State
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Listing fields
  ListingType? _listingType;
  List<XFile> _images = [];
  String _title = '';
  String _description = '';
  double? _price;
  late Location location = _userRepository.currentUser != null
      ? _userRepository.currentUser!.location
      : Location(latitude: 0, longitude: 0, timestamp: DateTime.now());

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  ListingType? get listingType => _listingType;
  List<XFile> get images => _images;
  String get title => _title;
  String get description => _description;
  double? get price => _price;

  bool get canProceed {
    switch (_currentStep) {
      case 0:
        return _listingType != null;
      case 1:
        return location.latitude != 0 && location.longitude != 0;
      case 2:
        return _images.isNotEmpty;
      case 3:
        return _title.isNotEmpty && _description.isNotEmpty;
      case 4:
        return true; // Price is optional
      default:
        return false;
    }
  }

  // Setters
  void setListingType(ListingType type) {
    _listingType = type;
    notifyListeners();
  }

  void setImages(List<XFile> images) {
    _images = images;
    notifyListeners();
  }

  void addImage(XFile image) {
    _images.add(image);
    notifyListeners();
  }

  void removeImage(int index) {
    _images.removeAt(index);
    notifyListeners();
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final image = _images.removeAt(oldIndex);
    _images.insert(newIndex, image);
    notifyListeners();
  }

  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void setDescription(String description) {
    _description = description;
    notifyListeners();
  }

  void setPrice(double? price) {
    _price = price;
    notifyListeners();
  }

  // Navigation
  void nextStep() {
    if (_currentStep < 4 && canProceed) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  // Process images with AI (placeholder)
  Future<void> processImages() async {
    _isLoading = true;
    notifyListeners();

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));

    // Set dummy values
    _title = 'Roofing Repair Needed';
    _description = 'The roof has some visible damage and needs professional repair. Multiple shingles are missing and there appears to be water damage.';
    _price = 150.0;

    _isLoading = false;
    notifyListeners();
  }

  // Create listing
  Future<bool> createListing() async {
  // Debug: print current state for troubleshooting
  debugPrint('CreateListingViewModel.createListing - state:');
  debugPrint('  currentStep: $_currentStep');
  debugPrint('  currentUid: $_userId');
  debugPrint('  isLoading: $_isLoading');
  debugPrint('  errorMessage: $_errorMessage');
  debugPrint('  listingType: $_listingType');
  debugPrint('  title: $_title');
  debugPrint('  description: $_description');
  debugPrint('  price: $_price');
  debugPrint('  images count: ${_images.length}');
  for (var i = 0; i < _images.length; i++) {
    final img = _images[i];
    debugPrint('    [$i] name=${img.name}, path=${img.path}');
  }
    if (_listingType == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload images first (you'll need to implement this in repository)
      final imageUrls = await _uploadImages();

      // Create listing object
      final listing = Listing(
        id: '', // Firestore will generate
        author: _userId,
        title: _title,
        description: _description,
        price: _price ?? 0.0,
        imageUrls: imageUrls,
        listingStatus: ListingStatus.draft,
        listingType: _listingType!,
        createdDate: Timestamp.now(),
        location: location,
      );

      final result = await _listingRepository.createListing(listing);
      if (result is Failure) {
        Toaster.showErrorFromFailure(result);
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create listing: $e';
      Toaster.showError(_errorMessage!);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<List<String>> _uploadImages() async {
    // TODO: Implement actual image upload to Firebase Storage
    // For now, return placeholder URLs
    return _images.map((img) => 'https://placeholder.com/${img.name}').toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}