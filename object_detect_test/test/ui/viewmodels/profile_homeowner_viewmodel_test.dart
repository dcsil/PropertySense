import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/homeowner_details_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/profile_homeowner_viewmodel.dart';
import 'package:object_detect_test/utils/result.dart';

import 'profile_homeowner_viewmodel_test.mocks.dart';
import 'package:mockito/src/dummies.dart' as dummies;

@GenerateMocks([AuthRepository, UserRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Provide dummy values for Result types
  dummies.provideDummy<Result<void>>(Success<void>(null));

  group('ProfileHomeownerViewModel', () {
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;

    User _createTestUser({
      String givenName = 'John',
      String familyName = 'Doe',
      HomeownerDetails? homeownerDetails,
    }) {
      return User(
        id: 'user123',
        type: UserType.homeowner,
        givenName: givenName,
        familyName: familyName,
        createdDate: DateTime(2024, 1, 1),
        location: Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        ),
        placemark: Placemark(),
        homeownerDetails: homeownerDetails ?? HomeownerDetails(
          unitType: UnitType.apartment,
          unitNumber: 101,
          isRental: false,
        ),
      );
    }

    ProfileHomeownerViewModel _createViewModel({
      User? user,
      bool shouldFailUpdate = false,
    }) {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();

      if (user != null) {
        when(mockUserRepository.currentUser).thenReturn(user);
      } else {
        when(mockUserRepository.currentUser).thenReturn(null);
      }

      if (shouldFailUpdate) {
        when(mockUserRepository.updateUserDocument(any))
            .thenThrow(Exception('Update failed'));
      } else {
        when(mockUserRepository.updateUserDocument(any))
            .thenAnswer((_) async => Success<void>(null));
      }

      return ProfileHomeownerViewModel(mockAuthRepository, mockUserRepository);
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

      test('should return homeownerDetails from currentUser', () {
        final homeownerDetails = HomeownerDetails(
          unitType: UnitType.singleFamily,
          unitNumber: 123,
          isRental: true,
        );
        final user = _createTestUser(homeownerDetails: homeownerDetails);
        final viewModel = _createViewModel(user: user);

        expect(viewModel.homeownerDetails, isNotNull);
        expect(viewModel.homeownerDetails?.unitType, UnitType.singleFamily);
        expect(viewModel.homeownerDetails?.unitNumber, 123);
        expect(viewModel.homeownerDetails?.isRental, true);
      });

      test('should return null for getters when currentUser is null', () {
        final viewModel = _createViewModel(user: null);

        expect(viewModel.givenName, isNull);
        expect(viewModel.familyName, isNull);
        expect(viewModel.homeownerDetails, isNull);
      });
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user);

        final newHomeownerDetails = HomeownerDetails(
          unitType: UnitType.townhouse,
          unitNumber: 456,
          isRental: true,
        );

        await viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          homeownerDetails: newHomeownerDetails,
        );

        expect(viewModel.isLoading, false);
        verify(mockUserRepository.updateUserDocument(any)).called(1);
      });

      test('should set isLoading to true during update', () async {
        final user = _createTestUser();
        mockAuthRepository = MockAuthRepository();
        mockUserRepository = MockUserRepository();
        when(mockUserRepository.currentUser).thenReturn(user);
        
        // Create delayed response to catch loading state
        when(mockUserRepository.updateUserDocument(any))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return Success<void>(null);
        });

        final viewModel = ProfileHomeownerViewModel(mockAuthRepository, mockUserRepository);

        final newHomeownerDetails = HomeownerDetails(
          unitType: UnitType.apartment,
          unitNumber: 789,
          isRental: false,
        );

        final future = viewModel.updateProfile(
          givenName: 'New',
          familyName: 'Name',
          homeownerDetails: newHomeownerDetails,
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

        final newHomeownerDetails = HomeownerDetails(
          unitType: UnitType.condo,
          unitNumber: 999,
          isRental: true,
        );

        await viewModel.updateProfile(
          givenName: 'New',
          familyName: 'Updated',
          homeownerDetails: newHomeownerDetails,
        );

        final captured = verify(mockUserRepository.updateUserDocument(captureAny)).captured;
        final updatedUser = captured[0] as User;

        expect(updatedUser.id, 'user123');
        expect(updatedUser.type, UserType.homeowner);
        expect(updatedUser.givenName, 'New');
        expect(updatedUser.familyName, 'Updated');
        expect(updatedUser.homeownerDetails?.unitType, UnitType.condo);
        expect(updatedUser.homeownerDetails?.unitNumber, 999);
        expect(updatedUser.homeownerDetails?.isRental, true);
        expect(updatedUser.createdDate, user.createdDate);
      });

      test('should handle update failure', () async {
        final user = _createTestUser();
        final viewModel = _createViewModel(user: user, shouldFailUpdate: true);

        final newHomeownerDetails = HomeownerDetails(
          unitType: UnitType.apartment,
          unitNumber: 123,
          isRental: false,
        );

        await viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          homeownerDetails: newHomeownerDetails,
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

        final newHomeownerDetails = HomeownerDetails(
          unitType: UnitType.apartment,
          unitNumber: 123,
          isRental: false,
        );

        await viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          homeownerDetails: newHomeownerDetails,
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

        final newHomeownerDetails = HomeownerDetails(
          unitType: UnitType.apartment,
          unitNumber: 123,
          isRental: false,
        );

        final future = viewModel.updateProfile(
          givenName: 'Jane',
          familyName: 'Smith',
          homeownerDetails: newHomeownerDetails,
        );

        // During update, isLoading should be true (briefly)
        expect(viewModel.isLoading, true);
        
        await future;
        expect(viewModel.isLoading, false);
      });

      test('should update getters when currentUser changes', () {
        final user1 = _createTestUser(givenName: 'John', familyName: 'Doe');
        final viewModel = _createViewModel(user: user1);

        expect(viewModel.givenName, 'John');
        expect(viewModel.familyName, 'Doe');

        final user2 = _createTestUser(givenName: 'Jane', familyName: 'Smith');
        when(mockUserRepository.currentUser).thenReturn(user2);

        expect(viewModel.givenName, 'Jane');
        expect(viewModel.familyName, 'Smith');
      });
    });
  });
}

