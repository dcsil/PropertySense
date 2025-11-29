import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
        when(mockUser.emailVerified).thenReturn(true);
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
    when(mockUser.emailVerified).thenReturn(false);
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
        when(mockUser1.emailVerified).thenReturn(true);

        when(mockUser2.uid).thenReturn(testUserId2);
        when(mockUser2.metadata).thenReturn(mockMetadata2);
        when(mockMetadata2.creationTime).thenReturn(testCreationTime2);
        when(mockUser2.emailVerified).thenReturn(true);

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
        when(mockUser.emailVerified).thenReturn(true);
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
    when(mockUser.emailVerified).thenReturn(false);
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

    group('signInWithEmail', () {
      test('should return Success when sign in succeeds', () async {
        // Arrange
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => MockUserCredential());

        // Act
        final result = await authRepository.signInWithEmail(
          'test@example.com',
          'password123',
        );

        // Assert
        expect(result, isA<Success<void>>());
        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should return Failure when sign in fails', () async {
        // Arrange
        final exception = FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found',
        );
        when(mockFirebaseAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        // Act
        final result = await authRepository.signInWithEmail(
          'test@example.com',
          'wrongpassword',
        );

        // Assert
        expect(result, isA<Failure>());
        expect((result as Failure).message, contains('Failed to sign in with email and password'));
        verify(mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'wrongpassword',
        )).called(1);
      });
    });

    group('signInWithApple', () {
      test('should return Failure as not implemented', () async {
        // Act
        final result = await authRepository.signInWithApple();

        // Assert
        expect(result, isA<Failure>());
        expect((result as Failure).message, 'Sign in with Apple not implemented yet');
      });
    });

    group('signOut', () {
      test('should return Success when sign out succeeds', () async {
        // Arrange
        when(mockFirebaseAuth.signOut()).thenAnswer((_) async => Future.value());

        // Act
        final result = await authRepository.signOut();

        // Assert
        expect(result, isA<Success<void>>());
        verify(mockFirebaseAuth.signOut()).called(1);
      });

      test('should return Failure when sign out fails', () async {
        // Arrange
        final exception = Exception('Sign out failed');
        when(mockFirebaseAuth.signOut()).thenThrow(exception);

        // Act
        final result = await authRepository.signOut();

        // Assert
        expect(result, isA<Failure>());
        expect((result as Failure).message, contains('Failed to sign out'));
        verify(mockFirebaseAuth.signOut()).called(1);
      });
    });

    group('signUpWithEmail', () {
      test('should return Success when sign up succeeds', () async {
        // Arrange
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => MockUserCredential());

        // Act
        final result = await authRepository.signUpWithEmail(
          'newuser@example.com',
          'password123',
        );

        // Assert
        expect(result, isA<Success<void>>());
        verify(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should return Failure when sign up fails', () async {
        // Arrange
        final exception = FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email already in use',
        );
        when(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        // Act
        final result = await authRepository.signUpWithEmail(
          'existing@example.com',
          'password123',
        );

        // Assert
        expect(result, isA<Failure>());
        expect((result as Failure).message, contains('Failed to sign up with email and password'));
        verify(mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'existing@example.com',
          password: 'password123',
        )).called(1);
      });
    });

    group('sendPasswordResetEmail', () {
      test('should return Success when password reset email is sent', () async {
        // Arrange
        when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await authRepository.sendPasswordResetEmail('user@example.com');

        // Assert
        expect(result, isA<Success<void>>());
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: 'user@example.com')).called(1);
      });

      test('should return Failure when password reset email fails', () async {
        // Arrange
        final exception = FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found',
        );
        when(mockFirebaseAuth.sendPasswordResetEmail(email: anyNamed('email')))
            .thenThrow(exception);

        // Act
        final result = await authRepository.sendPasswordResetEmail('nonexistent@example.com');

        // Assert
        expect(result, isA<Failure>());
        expect((result as Failure).message, contains('Failed to send password reset email'));
        verify(mockFirebaseAuth.sendPasswordResetEmail(email: 'nonexistent@example.com')).called(1);
      });
    });

    group('sendVerificationEmail', () {
      late MockUser mockCurrentUser;

      setUp(() {
        mockCurrentUser = MockUser();
      });

      test('should return Success when verification email is sent', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockCurrentUser);
        when(mockCurrentUser.sendEmailVerification())
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await authRepository.sendVerificationEmail();

        // Assert
        expect(result, isA<Success<void>>());
        verify(mockCurrentUser.sendEmailVerification()).called(1);
      });

      test('should return Success when no current user (null)', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(null);

        // Act
        final result = await authRepository.sendVerificationEmail();

        // Assert
        expect(result, isA<Success<void>>());
        verifyNever(mockCurrentUser.sendEmailVerification());
      });

      test('should return Failure when verification email fails', () async {
        // Arrange
        when(mockFirebaseAuth.currentUser).thenReturn(mockCurrentUser);
        final exception = Exception('Failed to send email');
        when(mockCurrentUser.sendEmailVerification()).thenThrow(exception);

        // Act
        final result = await authRepository.sendVerificationEmail();

        // Assert
        expect(result, isA<Failure>());
        expect((result as Failure).message, contains('Failed to send verification email'));
        verify(mockCurrentUser.sendEmailVerification()).called(1);
      });
    });
  });
}

// Helper mock class for UserCredential
class MockUserCredential extends Mock implements UserCredential {}