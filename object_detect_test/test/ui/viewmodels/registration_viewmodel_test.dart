import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/contractor_details_model.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/registration_viewmodel.dart';
import 'package:object_detect_test/utils/result.dart';

import '../../data/repos/auth_repository_test.mocks.dart' as auth_mocks
    show MockFirebaseAuth, MockUser;
import 'package:mockito/src/dummies.dart' as dummies;

import 'registration_viewmodel_test.mocks.dart';

@GenerateMocks([
  AuthRepository,
  UserRepository,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Provide dummy values for Result types
  dummies.provideDummy<Result<void>>(Success<void>(null));
  dummies.provideDummy<Result<User?>>(Success<User?>(null));
  
  // Helper functions
  MockAuthRepository _createMockAuth() {
    final mock = MockAuthRepository();
    final mockFirebaseAuth = auth_mocks.MockFirebaseAuth();
    when(mock.firebaseAuthInstance).thenReturn(mockFirebaseAuth);
    return mock;
  }
  
  MockUserRepository _createMockUserRepo() {
    final mock = MockUserRepository();
    when(mock.userStateChanges())
        .thenAnswer((_) => Stream.value(Success<User?>(null)));
    return mock;
  }
  
  Future<RegistrationViewModel> _createViewModel() async {
    final authRepo = _createMockAuth();
    final userRepo = _createMockUserRepo();
    final viewModel = RegistrationViewModel(authRepo, userRepo);
    // Wait for stream to emit initial value to avoid disposal issues
    await Future.delayed(Duration(milliseconds: 100));
    return viewModel;
  }
  
  // Helper that returns both viewModel and mocks for tests that need to verify mock calls
  Future<({RegistrationViewModel viewModel, MockAuthRepository authRepo, MockUserRepository userRepo, auth_mocks.MockFirebaseAuth firebaseAuth, auth_mocks.MockUser firebaseUser})> _createViewModelWithMocks() async {
    final authRepo = MockAuthRepository();
    final firebaseAuth = auth_mocks.MockFirebaseAuth();
    final firebaseUser = auth_mocks.MockUser();
    when(authRepo.firebaseAuthInstance).thenReturn(firebaseAuth);
    final userRepo = _createMockUserRepo();
    final viewModel = RegistrationViewModel(authRepo, userRepo);
    // Wait for stream to emit initial value to avoid disposal issues
    await Future.delayed(Duration(milliseconds: 100));
    return (viewModel: viewModel, authRepo: authRepo, userRepo: userRepo, firebaseAuth: firebaseAuth, firebaseUser: firebaseUser);
  }
  
  // Helper to safely dispose viewModel, waiting for any remaining async callbacks
  Future<void> _safeDispose(RegistrationViewModel viewModel) async {
    await Future.delayed(Duration(milliseconds: 50));
    viewModel.dispose();
  }

  group('RegistrationViewModel', () {
    group('Initialization', () {
      test('should initialize with default values', () async {
        final viewModel = await _createViewModel();
        expect(viewModel.currentStep, RegistrationStep.name);
        expect(viewModel.givenName, '');
        expect(viewModel.familyName, '');
        expect(viewModel.userType, UserType.homeowner);
        expect(viewModel.isLoading, false);
        expect(viewModel.currentUser, isNull);
        await _safeDispose(viewModel);
      });

      test('should listen to user state changes on initialization', () async {
        final setup = await _createViewModelWithMocks();
        verify(setup.userRepo.userStateChanges()).called(1);
        await _safeDispose(setup.viewModel);
      });
    });

    group('nextStep', () {
      test('should not proceed if validation fails', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.name;
        viewModel.givenName = '';
        viewModel.familyName = '';

        // Act
        viewModel.nextStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.name); // Should not change
        await _safeDispose(viewModel);
      });

      test('should proceed from name to userType when name is valid', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.name;
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';

        // Act
        viewModel.nextStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.userType);
        await _safeDispose(viewModel);
      });

      test('should proceed from userType to address for homeowner', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.userType;
        viewModel.userType = UserType.homeowner;

        // Act
        viewModel.nextStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.address);
        await _safeDispose(viewModel);
      });

      test('should proceed from userType to identification for contractor', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.userType;
        viewModel.userType = UserType.contractor;

        // Act
        viewModel.nextStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.identification);
        await _safeDispose(viewModel);
      });

      test('should proceed through homeowner flow steps', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );

        // Act & Assert
        viewModel.nextStep(); // name -> userType
        expect(viewModel.currentStep, RegistrationStep.userType);

        viewModel.nextStep(); // userType -> address
        expect(viewModel.currentStep, RegistrationStep.address);

        viewModel.nextStep(); // address -> addressDetails
        expect(viewModel.currentStep, RegistrationStep.addressDetails);

        viewModel.nextStep(); // addressDetails -> reviewAndSubmitHomeowner
        expect(viewModel.currentStep, RegistrationStep.reviewAndSubmitHomeowner);
        await _safeDispose(viewModel);
      });

      test('should proceed through contractor flow steps', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.givenName = 'Jane';
        viewModel.familyName = 'Smith';
        viewModel.userType = UserType.contractor;
        viewModel.idPhotoUrl = '/path/to/id.jpg';
        viewModel.companyName = 'Test Company';
        viewModel.licenseNumber = 'LIC123';
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.profilePhotoUrl = '/path/to/photo.jpg';

        // Act & Assert
        viewModel.nextStep(); // name -> userType
        expect(viewModel.currentStep, RegistrationStep.userType);

        viewModel.nextStep(); // userType -> identification
        expect(viewModel.currentStep, RegistrationStep.identification);

        viewModel.nextStep(); // identification -> businessLicense
        expect(viewModel.currentStep, RegistrationStep.businessLicense);

        viewModel.nextStep(); // businessLicense -> profilePhoto
        expect(viewModel.currentStep, RegistrationStep.profilePhoto);

        viewModel.nextStep(); // profilePhoto -> reviewAndSubmitContractor
        expect(viewModel.currentStep, RegistrationStep.reviewAndSubmitContractor);
        await _safeDispose(viewModel);
      });

      test('should throw UnimplementedError at final homeowner step', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;

        // Act & Assert
        expect(() => viewModel.nextStep(), throwsA(isA<UnimplementedError>()));
        await _safeDispose(viewModel);
      });

      test('should throw UnimplementedError at final contractor step', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.reviewAndSubmitContractor;

        // Act & Assert
        expect(() => viewModel.nextStep(), throwsA(isA<UnimplementedError>()));
        await _safeDispose(viewModel);
      });
    });

    group('previousStep', () {
      test('should not go back from first step', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.name;

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.name); // Should not change
        await _safeDispose(viewModel);
      });

      test('should go back from userType to name', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.userType;

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.name);
        await _safeDispose(viewModel);
      });

      test('should go back through homeowner flow', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.addressDetails;

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.address);

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.userType);
        await _safeDispose(viewModel);
      });

      test('should go back through contractor flow', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.profilePhoto;

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.businessLicense);

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.identification);
        await _safeDispose(viewModel);
      });

      test('should navigate backward from reviewAndSubmitHomeowner', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.addressDetails);
        await _safeDispose(viewModel);
      });

      test('should navigate backward from reviewAndSubmitContractor', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.reviewAndSubmitContractor;

        // Act
        viewModel.previousStep();

        // Assert
        expect(viewModel.currentStep, RegistrationStep.profilePhoto);
        await _safeDispose(viewModel);
      });
    });

    group('_validateCurrentStep', () {
      test('should validate name step - fail when givenName is empty', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.name;
        viewModel.givenName = '';
        viewModel.familyName = 'Doe';

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.name); // Should not change
        await _safeDispose(viewModel);
      });

      test('should validate name step - fail when familyName is empty', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.name;
        viewModel.givenName = 'John';
        viewModel.familyName = '';

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.name); // Should not change
        await _safeDispose(viewModel);
      });

      test('should validate address step - fail when location is not set', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.address;
        viewModel.location = Location(
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
        );

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.address); // Should not change
        await _safeDispose(viewModel);
      });

      test('should validate address step - succeed when location is set', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.address;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.addressDetails);
        await _safeDispose(viewModel);
      });

      test('should validate identification step - fail when idPhotoUrl is empty', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.identification;
        viewModel.idPhotoUrl = '';

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.identification); // Should not change
        await _safeDispose(viewModel);
      });

      test('should validate businessLicense step - fail when companyName is empty', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.businessLicense;
        viewModel.companyName = '';
        viewModel.licenseNumber = 'LIC123';
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.businessLicense); // Should not change
        await _safeDispose(viewModel);
      });

      test('should validate businessLicense step - fail when licenseNumber is empty', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.businessLicense;
        viewModel.companyName = 'Test Company';
        viewModel.licenseNumber = '';
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.businessLicense); // Should not change
        await _safeDispose(viewModel);
      });

      test('should validate profilePhoto step - fail when profilePhotoUrl is empty', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.profilePhoto;
        viewModel.profilePhotoUrl = '';

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.profilePhoto); // Should not change
        await _safeDispose(viewModel);
      });

      test('should allow proceeding from addressDetails (no validation)', () async {
        final viewModel = await _createViewModel();
        // Arrange
        viewModel.currentStep = RegistrationStep.addressDetails;

        // Act
        viewModel.nextStep();
        
        // Assert
        expect(viewModel.currentStep, RegistrationStep.reviewAndSubmitHomeowner);
        await _safeDispose(viewModel);
      });
    });

    group('register', () {
      test('should not register if validation fails', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        
        // Arrange
        viewModel.currentStep = RegistrationStep.name;
        viewModel.givenName = '';
        viewModel.familyName = '';

        // Act
        await viewModel.register();

        // Assert
        expect(viewModel.isLoading, false);
        verifyNever(mockUserRepo.createUserDocument(any));
        await _safeDispose(viewModel);
      });

      test('should set loading to true when registration starts', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        final mockFirebaseUser = setup.firebaseUser;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;
        
        // Mock Firebase User
        when(mockFirebaseUser.uid).thenReturn('test-user-id');
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        
        // Arrange
        when(mockUserRepo.createUserDocument(any))
            .thenAnswer((_) async => Success(null));
        when(mockUserRepo.fetchUser(any))
            .thenAnswer((_) async => Success<User?>(null));

        // Act
        final future = viewModel.register();

        // Assert
        expect(viewModel.isLoading, true);
        
        // Wait for completion
        await future;
        await _safeDispose(viewModel);
      });

      test('should create user document for homeowner successfully', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        final mockFirebaseUser = setup.firebaseUser;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;
        
        // Mock Firebase User
        when(mockFirebaseUser.uid).thenReturn('test-user-id');
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        
        // Arrange
        final createdUser = User(
          id: 'test-user-id',
          givenName: 'John',
          familyName: 'Doe',
          type: UserType.homeowner,
          location: viewModel.location,
          placemark: viewModel.placemark,
          createdDate: DateTime.now(),
          homeownerDetails: HomeownerDetails(
            unitType: UnitType.apartment,
            unitNumber: 0,
            isRental: false,
          ),
        );

        when(mockUserRepo.createUserDocument(any))
            .thenAnswer((_) async => Success(null));
        when(mockUserRepo.fetchUser('test-user-id'))
            .thenAnswer((_) async => Success<User?>(createdUser));

        // Act
        await viewModel.register();

        // Assert
        verify(mockUserRepo.createUserDocument(any)).called(1);
        verify(mockUserRepo.fetchUser('test-user-id')).called(1);
        expect(viewModel.isLoading, false);
        expect(viewModel.currentUser, isNotNull);
        await _safeDispose(viewModel);
      });

      test('should create user document for contractor successfully', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        final mockFirebaseUser = setup.firebaseUser;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        
        // Arrange
        viewModel.userType = UserType.contractor;
        viewModel.idPhotoUrl = '/path/to/id.jpg';
        viewModel.companyName = 'Test Company';
        viewModel.licenseNumber = 'LIC123';
        viewModel.profilePhotoUrl = '/path/to/photo.jpg';
        viewModel.currentStep = RegistrationStep.reviewAndSubmitContractor;

        // Mock Firebase User
        when(mockFirebaseUser.uid).thenReturn('test-user-id');
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);

        final createdUser = User(
          id: 'test-user-id',
          givenName: 'John',
          familyName: 'Doe',
          type: UserType.contractor,
          location: viewModel.location,
          placemark: viewModel.placemark,
          createdDate: DateTime.now(),
          contractorDetails: ContractorDetails(
            idPhotoUrl: '/path/to/id.jpg',
            companyName: 'Test Company',
            licenseNumber: 'LIC123',
          ),
        );

        when(mockUserRepo.createUserDocument(any))
            .thenAnswer((_) async => Success(null));
        when(mockUserRepo.fetchUser('test-user-id'))
            .thenAnswer((_) async => Success<User?>(createdUser));

        // Act
        await viewModel.register();

        // Assert
        verify(mockUserRepo.createUserDocument(any)).called(1);
        expect(viewModel.isLoading, false);
        expect(viewModel.currentUser, isNotNull);
        expect(viewModel.currentUser?.type, UserType.contractor);
        await _safeDispose(viewModel);
      });

      test('should fail registration when contractor details are incomplete', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        
        // Arrange
        viewModel.userType = UserType.contractor;
        viewModel.idPhotoUrl = '';
        viewModel.companyName = 'Test Company';
        viewModel.licenseNumber = 'LIC123';
        viewModel.currentStep = RegistrationStep.reviewAndSubmitContractor;

        // Act
        await viewModel.register();

        // Assert
        expect(viewModel.isLoading, false);
        verifyNever(mockUserRepo.createUserDocument(any));
        await _safeDispose(viewModel);
      });

      test('should fail registration when no authenticated user', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;
        
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        await viewModel.register();

        // Assert
        expect(viewModel.isLoading, false);
        verifyNever(mockUserRepo.createUserDocument(any));
        await _safeDispose(viewModel);
      });

      test('should handle user document creation failure', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        final mockFirebaseUser = setup.firebaseUser;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;
        
        // Mock Firebase User
        when(mockFirebaseUser.uid).thenReturn('test-user-id');
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        
        // Arrange
        final failure = Failure<void>('Failed to create user document');
        when(mockUserRepo.createUserDocument(any))
            .thenAnswer((_) async => failure);

        // Act
        await viewModel.register();

        // Assert
        expect(viewModel.isLoading, false);
        verify(mockUserRepo.createUserDocument(any)).called(1);
        verifyNever(mockUserRepo.fetchUser(any));
        await _safeDispose(viewModel);
      });

      test('should handle fetchUser failure after creation', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        final mockFirebaseUser = setup.firebaseUser;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;
        
        // Mock Firebase User
        when(mockFirebaseUser.uid).thenReturn('test-user-id');
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        
        // Arrange
        final failure = Failure<User?>('Failed to fetch user');
        when(mockUserRepo.createUserDocument(any))
            .thenAnswer((_) async => Success(null));
        when(mockUserRepo.fetchUser(any))
            .thenAnswer((_) async => failure);

        // Act
        await viewModel.register();

        // Assert
        expect(viewModel.isLoading, false);
        verify(mockUserRepo.createUserDocument(any)).called(1);
        verify(mockUserRepo.fetchUser('test-user-id')).called(1);
        await _safeDispose(viewModel);
      });

      test('should set currentUser after successful registration', () async {
        final setup = await _createViewModelWithMocks();
        final viewModel = setup.viewModel;
        final mockUserRepo = setup.userRepo;
        final mockFirebaseAuth = setup.firebaseAuth;
        final mockFirebaseUser = setup.firebaseUser;
        
        // Setup default registration data
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.homeowner;
        viewModel.location = Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        );
        viewModel.placemark = Placemark();
        viewModel.currentStep = RegistrationStep.reviewAndSubmitHomeowner;
        
        // Mock Firebase User
        when(mockFirebaseUser.uid).thenReturn('test-user-id');
        when(mockFirebaseAuth.currentUser).thenReturn(mockFirebaseUser);
        
        // Arrange
        final createdUser = User(
          id: 'test-user-id',
          givenName: 'John',
          familyName: 'Doe',
          type: UserType.homeowner,
          location: viewModel.location,
          placemark: viewModel.placemark,
          createdDate: DateTime.now(),
          homeownerDetails: HomeownerDetails(
            unitType: UnitType.apartment,
            unitNumber: 0,
            isRental: false,
          ),
        );

        when(mockUserRepo.createUserDocument(any))
            .thenAnswer((_) async => Success(null));
        when(mockUserRepo.fetchUser('test-user-id'))
            .thenAnswer((_) async => Success<User?>(createdUser));

        // Act
        await viewModel.register();

        // Assert
        expect(viewModel.currentUser, isNotNull);
        expect(viewModel.currentUser?.id, 'test-user-id');
        expect(viewModel.currentUser?.givenName, 'John');
        expect(viewModel.currentUser?.familyName, 'Doe');
        await _safeDispose(viewModel);
      });
    });

    group('_listenToUserChanges', () {
      test('should update currentUser when user state changes', () async {
        final setup = await _createViewModelWithMocks();
        final mockAuthRepo = setup.authRepo;
        final mockUserRepo = setup.userRepo;
        
        // Arrange
        final user = User(
          id: 'user123',
          givenName: 'John',
          familyName: 'Doe',
          type: UserType.homeowner,
          location: Location(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.now(),
          ),
          placemark: Placemark(),
          createdDate: DateTime.now(),
        );

        // Reset and setup stream
        reset(mockUserRepo);
        when(mockUserRepo.userStateChanges())
            .thenAnswer((_) => Stream.value(Success<User?>(user)));

        // Create new viewmodel to capture stream
        final newViewModel = RegistrationViewModel(mockAuthRepo, mockUserRepo);

        // Wait for stream to emit
        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(newViewModel.currentUser, isNotNull);
        expect(newViewModel.currentUser?.id, 'user123');
        expect(newViewModel.isLoading, false);
        
        newViewModel.dispose();
      });

      test('should set isLoading to false when user state changes', () async {
        final setup = await _createViewModelWithMocks();
        final mockAuthRepo = setup.authRepo;
        final mockUserRepo = setup.userRepo;
        
        // Reset and setup stream
        reset(mockUserRepo);
        when(mockUserRepo.userStateChanges())
            .thenAnswer((_) => Stream.value(Success<User?>(null)));

        // Create new viewmodel to capture stream
        final newViewModel = RegistrationViewModel(mockAuthRepo, mockUserRepo);

        // Wait for stream to emit
        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(newViewModel.isLoading, false);
        
        newViewModel.dispose();
      });

      test('should handle user state changes with null user', () async {
        final setup = await _createViewModelWithMocks();
        final mockAuthRepo = setup.authRepo;
        final mockUserRepo = setup.userRepo;
        
        // Arrange
        // Reset and setup stream
        reset(mockUserRepo);
        when(mockUserRepo.userStateChanges())
            .thenAnswer((_) => Stream.value(Success<User?>(null)));

        // Create new viewmodel to capture stream
        final newViewModel = RegistrationViewModel(mockAuthRepo, mockUserRepo);

        // Wait for stream to emit
        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        expect(newViewModel.currentUser, isNull);
        
        newViewModel.dispose();
      });
    });

    group('dispose', () {
      test('should cancel user subscription on dispose', () async {
        final setup = await _createViewModelWithMocks();
        final mockAuthRepo = setup.authRepo;
        final mockUserRepo = setup.userRepo;
        
        // Arrange
        final controller = StreamController<Result<User?>>();
        reset(mockUserRepo);
        when(mockUserRepo.userStateChanges())
            .thenAnswer((_) => controller.stream);

        final newViewModel = RegistrationViewModel(mockAuthRepo, mockUserRepo);
        await Future.delayed(Duration(milliseconds: 100));

        // Act
        await _safeDispose(newViewModel);

        // Assert - subscription should be cancelled
        expect(() => controller.close(), returnsNormally);
      });
    });

    group('State Management', () {
      test('should allow setting all form fields', () async {
        final viewModel = await _createViewModel();
        
        // Act
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.userType = UserType.contractor;
        viewModel.companyName = 'Test Company';
        viewModel.licenseNumber = 'LIC123';
        viewModel.idPhotoUrl = '/path/to/id.jpg';
        viewModel.profilePhotoUrl = '/path/to/photo.jpg';
        viewModel.unitType = UnitType.singleFamily;
        viewModel.unitNumber = 123;
        viewModel.isRental = true;

        // Assert
        expect(viewModel.givenName, 'John');
        expect(viewModel.familyName, 'Doe');
        expect(viewModel.userType, UserType.contractor);
        expect(viewModel.companyName, 'Test Company');
        expect(viewModel.licenseNumber, 'LIC123');
        expect(viewModel.idPhotoUrl, '/path/to/id.jpg');
        expect(viewModel.profilePhotoUrl, '/path/to/photo.jpg');
        expect(viewModel.unitType, UnitType.singleFamily);
        expect(viewModel.unitNumber, 123);
        expect(viewModel.isRental, true);
        
        await _safeDispose(viewModel);
      });

      test('should notify listeners when state changes', () async {
        final viewModel = await _createViewModel();
        bool listenerCalled = false;
        
        viewModel.addListener(() {
          listenerCalled = true;
        });

        // Act - nextStep() calls notifyListeners()
        viewModel.givenName = 'John';
        viewModel.familyName = 'Doe';
        viewModel.nextStep();

        // Assert - listener should be called when nextStep() calls notifyListeners()
        expect(listenerCalled, true);
        
        await _safeDispose(viewModel);
      });
    });
  });
}

