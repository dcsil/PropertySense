import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/auth/auth_repository_remote.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/utils/result.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User, UserMetadata])
void main() {
  late AuthRepositoryRemote authRepository;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockUserMetadata mockUserMetadata;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockUserMetadata = MockUserMetadata();
    authRepository = AuthRepositoryRemote(firebaseAuth: mockFirebaseAuth);
  });

  group('AuthRepositoryRemote', () {
    group('authStateChanges', () {
      test('should emit Success with null when user is null', () async {
        // Arrange
        when(mockFirebaseAuth.userChanges())
            .thenAnswer((_) => Stream.value(null));

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        await expectLater(
          stream,
          emits(
            predicate<Result<Auth?>>((result) {
              return result is Success<Auth?> && result.value == null;
            }),
          ),
        );
      });

      test('should emit Success with Auth when user is valid', () async {
        // Arrange
        final testUserId = 'test-user-id';
        final testCreationTime = DateTime(2024, 1, 1);

        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.uid).thenReturn(testUserId);
        when(mockUser.metadata).thenReturn(mockUserMetadata);
        when(mockUserMetadata.creationTime).thenReturn(testCreationTime);
        when(mockFirebaseAuth.userChanges())
            .thenAnswer((_) => Stream.value(mockUser));

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        await expectLater(
          stream,
          emits(
            predicate<Result<Auth?>>((result) {
              if (result is! Success<Auth?>) return false;
              final auth = result.value;
              return auth != null &&
                  auth.id == testUserId &&
                  auth.createdDate == testCreationTime;
            }),
          ),
        );
      });

      test('should emit Failure when creationTime is null', () async {
        // Arrange
        final testUserId = 'test-user-id';

    when(mockUser.uid).thenReturn(testUserId);
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.metadata).thenReturn(mockUserMetadata);
    when(mockUserMetadata.creationTime).thenReturn(null);
    when(mockFirebaseAuth.userChanges())
      .thenAnswer((_) => Stream.value(mockUser));

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        await expectLater(
          stream,
          emits(
            predicate<Result<Auth?>>((result) {
              return result is Failure &&
                  (result as Failure).message.contains('Could not map firebase user to domain Auth');
            }),
          ),
        );
      });

      test('should emit multiple states when auth state changes multiple times',
          () async {
        // Arrange
        final testUserId1 = 'user-1';
        final testUserId2 = 'user-2';
        final testCreationTime1 = DateTime(2024, 1, 1);
        final testCreationTime2 = DateTime(2024, 2, 1);

        final mockUser1 = MockUser();
        final mockUser2 = MockUser();
        final mockMetadata1 = MockUserMetadata();
        final mockMetadata2 = MockUserMetadata();

        when(mockUser1.uid).thenReturn(testUserId1);
        when(mockUser1.metadata).thenReturn(mockMetadata1);
        when(mockMetadata1.creationTime).thenReturn(testCreationTime1);

        when(mockUser2.uid).thenReturn(testUserId2);
        when(mockUser2.metadata).thenReturn(mockMetadata2);
        when(mockMetadata2.creationTime).thenReturn(testCreationTime2);

        when(mockUser1.email).thenReturn('user1@example.com');
        when(mockUser2.email).thenReturn('user2@example.com');

        when(mockFirebaseAuth.userChanges()).thenAnswer(
          (_) => Stream.fromIterable([mockUser1, null, mockUser2]),
        );

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        await expectLater(
          stream,
          emitsInOrder([
            // First user
            predicate<Result<Auth?>>((result) {
              if (result is! Success<Auth?>) return false;
              final auth = result.value;
              return auth != null &&
                  auth.id == testUserId1 &&
                  auth.createdDate == testCreationTime1;
            }),
            // Logged out
            predicate<Result<Auth?>>((result) {
              return result is Success<Auth?> && result.value == null;
            }),
            // Second user
            predicate<Result<Auth?>>((result) {
              if (result is! Success<Auth?>) return false;
              final auth = result.value;
              return auth != null &&
                  auth.id == testUserId2 &&
                  auth.createdDate == testCreationTime2;
            }),
          ]),
        );
      });

      test('should handle stream errors gracefully', () async {
        // Arrange
        final testError = Exception('Firebase error');
    when(mockFirebaseAuth.userChanges())
      .thenAnswer((_) => Stream.error(testError));

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        await expectLater(
          stream,
          emitsError(testError),
        );
      });
    });

    group('_mapFbUserToAuth', () {
      test('should return Success with null for null user', () {
        // This is tested indirectly through authStateChanges,
        // but we can verify the behavior
        when(mockFirebaseAuth.userChanges())
            .thenAnswer((_) => Stream.value(null));

        final stream = authRepository.authStateChanges();

        expectLater(
          stream,
          emits(isA<Success<Auth?>>()),
        );
      });

      test('should return Success with Auth for valid user', () async {
        // Arrange
        final testUserId = 'test-id';
        final testCreationTime = DateTime(2024, 1, 1);

        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.uid).thenReturn(testUserId);
        when(mockUser.metadata).thenReturn(mockUserMetadata);
        when(mockUserMetadata.creationTime).thenReturn(testCreationTime);
        when(mockFirebaseAuth.userChanges())
            .thenAnswer((_) => Stream.value(mockUser));

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        final result = await stream.first;
        expect(result, isA<Success<Auth?>>());
        expect((result as Success<Auth?>).value?.id, testUserId);
        expect(result.value?.createdDate, testCreationTime);
      });

      test('should return Failure when creationTime is null', () async {
        // Arrange
    when(mockUser.uid).thenReturn('test-id');
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.metadata).thenReturn(mockUserMetadata);
    when(mockUserMetadata.creationTime).thenReturn(null);
    when(mockFirebaseAuth.userChanges())
      .thenAnswer((_) => Stream.value(mockUser));

        // Act
        final stream = authRepository.authStateChanges();

        // Assert
        final result = await stream.first;
        expect(result, isA<Failure>());
        expect(
          (result as Failure).message,
          contains('Could not map firebase user to domain Auth'),
        );
      });
    });
  });
}