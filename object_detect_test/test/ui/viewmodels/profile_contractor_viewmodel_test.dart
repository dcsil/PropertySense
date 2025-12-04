import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/contractor_details_model.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/profile_contractor_viewmodel.dart';
import 'package:object_detect_test/utils/result.dart';

import 'profile_contractor_viewmodel_test.mocks.dart';
import 'package:mockito/src/dummies.dart' as dummies;

@GenerateMocks([AuthRepository, UserRepository, ContractorListingRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Provide dummy values for Result types
  dummies.provideDummy<Result<void>>(Success<void>(null));

  group('ProfileContractorViewModel', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late MockContractorListingRepository mockContractorListingRepository;

    User _createTestUser({
      String givenName = 'John',
      String familyName = 'Doe',
      ContractorDetails? contractorDetails,
    }) {
      return User(
        id: 'user123',
        type: UserType.contractor,
        givenName: givenName,
        familyName: familyName,
        createdDate: DateTime(2024, 1, 1),
        location: Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        ),
        placemark: Placemark(),
        contractorDetails: contractorDetails ?? ContractorDetails(
          idPhotoUrl: '/path/to/id.jpg',
          companyName: 'Test Company',
          licenseNumber: 'LIC123',
        ),
      );
    }

    ProfileContractorViewModel _createViewModel({
      User? user,
      Set<ListingType>? listingTypeSet,
      double? radiusMeters,
      bool shouldFailUpdate = false,
    }) {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      mockContractorListingRepository = MockContractorListingRepository();

      if (user != null) {
        when(mockUserRepository.currentUser).thenReturn(user);
      } else {
        when(mockUserRepository.currentUser).thenReturn(null);
      }

      when(mockContractorListingRepository.listingTypeSet)
          .thenReturn(listingTypeSet ?? ListingType.values.toSet());
      when(mockContractorListingRepository.radiusMeters)
          .thenReturn(radiusMeters ?? 1000.0);

      if (shouldFailUpdate) {
        when(mockUserRepository.updateUserDocument(any))
            .thenThrow(Exception('Update failed'));
      } else {
        when(mockUserRepository.updateUserDocument(any))
            .thenAnswer((_) async => Success<void>(null));
      }

      when(mockContractorListingRepository.setListingTypeFilter(any))
          .thenReturn(Success<void>(null));
      when(mockContractorListingRepository.setRadiusMeters(any))
          .thenReturn(Success<void>(null));

      return ProfileContractorViewModel(
        mockAuthRepository,
        mockUserRepository,
        mockContractorListingRepository,
      );
    }

    group('Initialization', () {
      test('should initialize with correct default values', () {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        expect(viewModel.isLoading, false);
      });
    });

    group('Getters', () {
      test('should return givenName from currentUser', () {
        final user = _createTestUser(givenName: 'Jane');
        final viewModel = _createViewModel(user: user);

        expect(viewModel.givenName, 'Jane');
      });

      test('should return familyName from currentUser', () {
        final user = _createTestUser(familyName: 'Smith');
        final viewModel = _createViewModel(user: user);

        expect(viewModel.familyName, 'Smith');
      });

      test('should return contractorDetails from currentUser', () {
        final contractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/id2.jpg',
          companyName: 'New Company',
          licenseNumber: 'LIC456',
          approvalDate: Timestamp.now(),
        );
        final user = _createTestUser(contractorDetails: contractorDetails);
        final viewModel = _createViewModel(user: user);

        expect(viewModel.contractorDetails, isNotNull);
        expect(viewModel.contractorDetails?.companyName, 'New Company');
        expect(viewModel.contractorDetails?.licenseNumber, 'LIC456');
      });

      test('should return listingTypeSet from ContractorListingRepository', () {
        final user = _createTestUser();
        final listingTypes = {ListingType.roofing, ListingType.plumbing};
        final viewModel = _createViewModel(user: user, listingTypeSet: listingTypes);

        expect(viewModel.listingTypeSet, listingTypes);
      });

      test('should return radiusMeters from ContractorListingRepository', () {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user, radiusMeters: 5000.0);

        expect(viewModel.radiusMeters, 5000.0);
      });

      test('should return null for user-related getters when currentUser is null', () {
        final viewModel = _createViewModel(user: null);

        expect(viewModel.givenName, isNull);
        expect(viewModel.familyName, isNull);
        expect(viewModel.contractorDetails, isNull);
      });
    });

    group('setListingTypeFilter', () {
      test('should call setListingTypeFilter on repository successfully', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        final newTypes = {ListingType.roofing, ListingType.electrical};
        await viewModel.setListingTypeFilter(newTypes);

        verify(mockContractorListingRepository.setListingTypeFilter(newTypes)).called(1);
      });

      test('should notify listeners on success', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        await viewModel.setListingTypeFilter({ListingType.plumbing});

        expect(listenerCalled, true);
      });

      test('should handle setListingTypeFilter failure', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        when(mockContractorListingRepository.setListingTypeFilter(any))
            .thenReturn(Failure<void>('Failed to set filter'));

        await viewModel.setListingTypeFilter({ListingType.heating});

        verify(mockContractorListingRepository.setListingTypeFilter(any)).called(1);
      });
    });

    group('setRadiusMeters', () {
      test('should call setRadiusMeters on repository successfully', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        await viewModel.setRadiusMeters(2000.0);

        verify(mockContractorListingRepository.setRadiusMeters(2000.0)).called(1);
      });

      test('should notify listeners on success', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        await viewModel.setRadiusMeters(3000.0);

        expect(listenerCalled, true);
      });

      test('should handle setRadiusMeters failure', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        when(mockContractorListingRepository.setRadiusMeters(any))
            .thenReturn(Failure<void>('Failed to set radius'));

        await viewModel.setRadiusMeters(1500.0);

        verify(mockContractorListingRepository.setRadiusMeters(1500.0)).called(1);
      });
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        final newContractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/new/id.jpg',
          companyName: 'Updated Company',
          licenseNumber: 'LIC999',
        );

        await viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          contractorDetails: newContractorDetails,
        );

        expect(viewModel.isLoading, false);
        verify(mockUserRepository.updateUserDocument(any)).called(1);
      });

      test('should set isLoading to true during update', () async {
        final user = _createTestUser();
        mockAuthRepository = MockAuthRepository();
        mockUserRepository = MockUserRepository();
        mockContractorListingRepository = MockContractorListingRepository();
        when(mockUserRepository.currentUser).thenReturn(user);
        when(mockContractorListingRepository.listingTypeSet)
            .thenReturn(ListingType.values.toSet());
        when(mockContractorListingRepository.radiusMeters).thenReturn(1000.0);
        
        // Create delayed response to catch loading state
        when(mockUserRepository.updateUserDocument(any))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return Success<void>(null);
        });

        final viewModel = ProfileContractorViewModel(
          mockAuthRepository,
          mockUserRepository,
          mockContractorListingRepository,
        );

        final newContractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/id.jpg',
          companyName: 'Company',
          licenseNumber: 'LIC123',
        );

        final future = viewModel.updateProfile(
          givenName: 'New',
          familyName: 'Name',
          contractorDetails: newContractorDetails,
        );

        expect(viewModel.isLoading, true);
        await future;
        expect(viewModel.isLoading, false);
      });

      test('should create updated User with correct fields', () async {
        final user = _createTestUser(
          givenName: 'Old',
          familyName: 'Name',
        );
        final viewModel = _createViewModel(user: user);

        final newContractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/new/id.jpg',
          companyName: 'New Company Name',
          licenseNumber: 'NEWLIC999',
        );

        await viewModel.updateProfile(
          givenName: 'New',
          familyName: 'Updated',
          contractorDetails: newContractorDetails,
        );

        final captured = verify(mockUserRepository.updateUserDocument(captureAny)).captured;
        final updatedUser = captured[0] as User;

        expect(updatedUser.id, 'user123');
        expect(updatedUser.type, UserType.contractor);
        expect(updatedUser.givenName, 'New');
        expect(updatedUser.familyName, 'Updated');
        expect(updatedUser.contractorDetails?.companyName, 'New Company Name');
        expect(updatedUser.contractorDetails?.licenseNumber, 'NEWLIC999');
        expect(updatedUser.createdDate, user.createdDate);
      });

      test('should handle update failure', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user, shouldFailUpdate: true);

        final newContractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/id.jpg',
          companyName: 'Company',
          licenseNumber: 'LIC123',
        );

        await viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          contractorDetails: newContractorDetails,
        );

        expect(viewModel.isLoading, false);
      });

      test('should notify listeners when update starts and completes', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        final newContractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/id.jpg',
          companyName: 'Company',
          licenseNumber: 'LIC123',
        );

        await viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          contractorDetails: newContractorDetails,
        );

        expect(listenerCalled, true);
      });
    });

    group('signOut', () {
      test('should call signOut on AuthRepository', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => Success<void>(null));

        await viewModel.signOut();

        verify(mockAuthRepository.signOut()).called(1);
      });

      test('should handle signOut failure', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        when(mockAuthRepository.signOut())
            .thenAnswer((_) async => Failure<void>('Sign out failed'));

        await viewModel.signOut();

        verify(mockAuthRepository.signOut()).called(1);
      });
    });

    group('State Management', () {
      test('should maintain isLoading state correctly', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        expect(viewModel.isLoading, false);

        final newContractorDetails = ContractorDetails(
          idPhotoUrl: '/path/to/id.jpg',
          companyName: 'Company',
          licenseNumber: 'LIC123',
        );

        final future = viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          contractorDetails: newContractorDetails,
        );

        // During update, isLoading should be true (briefly)
        expect(viewModel.isLoading, true);
        
        await future;
        expect(viewModel.isLoading, false);
      });
    });
  });
}

