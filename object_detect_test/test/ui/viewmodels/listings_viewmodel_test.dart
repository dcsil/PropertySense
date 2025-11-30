import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/listing_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/listings_viewmodel.dart';
import 'package:object_detect_test/utils/result.dart';

import 'listings_viewmodel_test.mocks.dart';
import 'package:mockito/src/dummies.dart' as dummies;

@GenerateMocks([ListingRepository, UserRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Provide dummy values for Result types
  dummies.provideDummy<Result<List<Listing>>>(Success<List<Listing>>([]));

  group('ListingsViewModel', () {
    late MockListingRepository mockListingRepository;
    late MockUserRepository mockUserRepository;

    User _createTestUser() {
      return User(
        id: 'user123',
        type: UserType.homeowner,
        givenName: 'John',
        familyName: 'Doe',
        createdDate: DateTime(2024, 1, 1),
        location: Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        ),
        placemark: Placemark(),
      );
    }

    Listing _createTestListing({
      required String id,
      required ListingStatus status,
      String author = 'user123',
    }) {
      return Listing(
        id: id,
        author: author,
        title: 'Test Listing $id',
        description: 'Test description',
        price: 100.0,
        imageUrls: [],
        listingStatus: status,
        listingType: ListingType.roofing,
        createdDate: Timestamp.now(),
        location: Location(
          latitude: 43.6532,
          longitude: -79.3832,
          timestamp: DateTime.now(),
        ),
      );
    }

    Future<ListingsViewModel> _createViewModel({
      User? user,
      List<Listing>? listings,
      bool shouldFail = false,
    }) async {
      mockListingRepository = MockListingRepository();
      mockUserRepository = MockUserRepository();

      // Setup UserRepository
      if (user != null) {
        when(mockUserRepository.currentUser).thenReturn(user);
      } else {
        when(mockUserRepository.currentUser).thenReturn(null);
      }

      // Setup ListingRepository
      if (shouldFail) {
        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async => Failure<List<Listing>>('Failed to fetch listings'));
      } else {
        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async => Success<List<Listing>>(listings ?? []));
      }

      final viewModel = ListingsViewModel(mockListingRepository, mockUserRepository);
      
      // Wait for async _loadListings to complete
      await Future.delayed(Duration(milliseconds: 100));
      
      return viewModel;
    }

    group('Initialization', () {
      test('should call _loadListings on initialization', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
        ];

        await _createViewModel(user: user, listings: listings);

        verify(mockListingRepository.getListings('user123')).called(1);
      });

      test('should initialize with empty filteredListings', () async {
        final user = _createTestUser();
        final viewModel = await _createViewModel(user: user, listings: []);

        expect(viewModel.filteredListings, isEmpty);
        expect(viewModel.isLoading, false);
        expect(viewModel.selectedFilter, isNull);
        expect(viewModel.errorMessage, isNull);
      });
    });

    group('Loading Listings', () {
      test('should load listings successfully', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
          _createTestListing(id: '3', status: ListingStatus.done),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);

        expect(viewModel.filteredListings.length, 3);
        expect(viewModel.isLoading, false);
        expect(viewModel.errorMessage, isNull);
        verify(mockListingRepository.getListings('user123')).called(1);
      });

      test('should set filteredListings to all listings when no filter is set', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);

        expect(viewModel.filteredListings.length, 2);
        expect(viewModel.selectedFilter, isNull);
      });

      test('should handle loading failure', () async {
        final user = _createTestUser();
        final viewModel = await _createViewModel(
          user: user,
          shouldFail: true,
        );

        // When loading fails, filteredListings should be empty
        expect(viewModel.filteredListings, isEmpty);
        expect(viewModel.isLoading, false);
      });

      test('should show error when currentUser is null', () async {
        final viewModel = await _createViewModel(user: null);

        // Should not call getListings when user is null
        verifyNever(mockListingRepository.getListings(any));
        expect(viewModel.isLoading, false);
      });

      test('should set isLoading to true during loading', () async {
        final user = _createTestUser();
        mockListingRepository = MockListingRepository();
        mockUserRepository = MockUserRepository();
        when(mockUserRepository.currentUser).thenReturn(user);
        
        // Create a delayed response to catch loading state
        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 50));
          return Success<List<Listing>>([]);
        });

        final viewModel = ListingsViewModel(mockListingRepository, mockUserRepository);
        
        // Check immediately after construction (should be loading)
        expect(viewModel.isLoading, true);
        
        // Wait for loading to complete
        await Future.delayed(Duration(milliseconds: 100));
        expect(viewModel.isLoading, false);
      });
    });

    group('Filtering', () {
      test('should filter listings by draft status', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
          _createTestListing(id: '3', status: ListingStatus.done),
          _createTestListing(id: '4', status: ListingStatus.draft),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        viewModel.setFilter(ListingStatus.draft);

        expect(viewModel.filteredListings.length, 2);
        expect(viewModel.selectedFilter, ListingStatus.draft);
        expect(viewModel.filteredListings.every((l) => l.listingStatus == ListingStatus.draft), true);
      });

      test('should filter listings by pending status', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
          _createTestListing(id: '3', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        viewModel.setFilter(ListingStatus.pending);

        expect(viewModel.filteredListings.length, 2);
        expect(viewModel.selectedFilter, ListingStatus.pending);
        expect(viewModel.filteredListings.every((l) => l.listingStatus == ListingStatus.pending), true);
      });

      test('should filter listings by done status', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.done),
          _createTestListing(id: '2', status: ListingStatus.pending),
          _createTestListing(id: '3', status: ListingStatus.done),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        viewModel.setFilter(ListingStatus.done);

        expect(viewModel.filteredListings.length, 2);
        expect(viewModel.selectedFilter, ListingStatus.done);
        expect(viewModel.filteredListings.every((l) => l.listingStatus == ListingStatus.done), true);
      });

      test('should clear filter when set to null', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        
        // Set filter first
        viewModel.setFilter(ListingStatus.draft);
        expect(viewModel.filteredListings.length, 1);
        
        // Clear filter
        viewModel.setFilter(null);
        expect(viewModel.filteredListings.length, 2);
        expect(viewModel.selectedFilter, isNull);
      });

      test('should update filteredListings when filter changes', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
          _createTestListing(id: '3', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        
        viewModel.setFilter(ListingStatus.draft);
        expect(viewModel.filteredListings.length, 1);
        
        viewModel.setFilter(ListingStatus.pending);
        expect(viewModel.filteredListings.length, 2);
      });
    });

    group('refreshListings', () {
      test('should reload listings when refreshListings is called', () async {
        final user = _createTestUser();
        final initialListings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
        ];
        final newListings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: initialListings);
        expect(viewModel.filteredListings.length, 1);

        // Update mock to return new listings
        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async => Success<List<Listing>>(newListings));

        await viewModel.refreshListings();

        expect(viewModel.filteredListings.length, 2);
        verify(mockListingRepository.getListings('user123')).called(2); // Once on init, once on refresh
      });

      test('should reapply filter after refresh', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        viewModel.setFilter(ListingStatus.pending);
        expect(viewModel.filteredListings.length, 1);

        final newListings = [
          _createTestListing(id: '1', status: ListingStatus.pending),
          _createTestListing(id: '2', status: ListingStatus.pending),
          _createTestListing(id: '3', status: ListingStatus.draft),
        ];

        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async => Success<List<Listing>>(newListings));

        await viewModel.refreshListings();

        // Filter should still be applied
        expect(viewModel.filteredListings.length, 2);
        expect(viewModel.selectedFilter, ListingStatus.pending);
        expect(viewModel.filteredListings.every((l) => l.listingStatus == ListingStatus.pending), true);
      });

      test('should handle refresh failure', () async {
        final user = _createTestUser();
        final viewModel = await _createViewModel(user: user, listings: []);

        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async => Failure<List<Listing>>('Refresh failed'));

        await viewModel.refreshListings();

        expect(viewModel.filteredListings, isEmpty);
        expect(viewModel.isLoading, false);
      });
    });

    group('Error Handling', () {
      test('should set errorMessage on exception', () async {
        final user = _createTestUser();
        mockListingRepository = MockListingRepository();
        mockUserRepository = MockUserRepository();
        when(mockUserRepository.currentUser).thenReturn(user);
        when(mockListingRepository.getListings(any))
            .thenThrow(Exception('Network error'));

        final viewModel = ListingsViewModel(mockListingRepository, mockUserRepository);
        await Future.delayed(Duration(milliseconds: 100));

        expect(viewModel.errorMessage, contains('Failed to load listings'));
        expect(viewModel.filteredListings, isEmpty);
        expect(viewModel.isLoading, false);
      });

      test('should clear errorMessage on successful reload', () async {
        final user = _createTestUser();
        mockListingRepository = MockListingRepository();
        mockUserRepository = MockUserRepository();
        when(mockUserRepository.currentUser).thenReturn(user);
        
        // First call throws exception
        when(mockListingRepository.getListings(any))
            .thenThrow(Exception('Network error'));

        final viewModel = ListingsViewModel(mockListingRepository, mockUserRepository);
        await Future.delayed(Duration(milliseconds: 100));

        expect(viewModel.errorMessage, isNotNull);

        // Second call succeeds
        final listings = [_createTestListing(id: '1', status: ListingStatus.draft)];
        when(mockListingRepository.getListings(any))
            .thenAnswer((_) async => Success<List<Listing>>(listings));

        await viewModel.refreshListings();

        expect(viewModel.errorMessage, isNull);
        expect(viewModel.filteredListings.length, 1);
      });
    });

    group('State Management', () {
      test('should notify listeners when filter changes', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);
        bool listenerCalled = false;

        viewModel.addListener(() {
          listenerCalled = true;
        });

        viewModel.setFilter(ListingStatus.draft);

        expect(listenerCalled, true);
      });

      test('should maintain state correctly', () async {
        final user = _createTestUser();
        final listings = [
          _createTestListing(id: '1', status: ListingStatus.draft),
          _createTestListing(id: '2', status: ListingStatus.pending),
        ];

        final viewModel = await _createViewModel(user: user, listings: listings);

        expect(viewModel.isLoading, false);
        expect(viewModel.selectedFilter, isNull);
        expect(viewModel.filteredListings.length, 2);

        viewModel.setFilter(ListingStatus.draft);

        expect(viewModel.isLoading, false);
        expect(viewModel.selectedFilter, ListingStatus.draft);
        expect(viewModel.filteredListings.length, 1);
      });
    });
  });
}

