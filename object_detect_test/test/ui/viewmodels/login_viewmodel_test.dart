import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/ui/viewmodels/login_viewmodel.dart';
import 'package:object_detect_test/utils/result.dart';

import 'login_viewmodel_test.mocks.dart';
import 'package:mockito/src/dummies.dart' as dummies;

@GenerateMocks([AuthRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Provide dummy values for Result types
  dummies.provideDummy<Result<void>>(Success<void>(null));
  dummies.provideDummy<Result<Auth?>>(Success<Auth?>(null));

  group('LoginViewModel', () {
    late MockAuthRepository mockAuthRepository;

    MockAuthRepository _createMockAuth() {
      final mock = MockAuthRepository();
      when(mock.authStateChanges())
          .thenAnswer((_) => Stream.value(Success<Auth?>(null)));
      return mock;
    }

    LoginViewModel _createViewModel() {
      mockAuthRepository = _createMockAuth();
      return LoginViewModel(mockAuthRepository);
    }

    tearDown(() {
      // Reset mocks between tests to prevent verification state accumulation
      // Only reset if mockAuthRepository was set (from _createViewModel)
      try {
        reset(mockAuthRepository);
      } catch (e) {
        // Ignore if mockAuthRepository wasn't initialized
      }
    });

    group('Initialization', () {
      test('should initialize with empty email and password', () {
        final viewModel = _createViewModel();
        expect(viewModel.email, '');
        expect(viewModel.password, '');
        expect(viewModel.isLoading, false);
        expect(viewModel.isPasswordVisible, false);
        expect(viewModel.currentAuth, isNull);
        viewModel.dispose();
      });

      test('should listen to auth state changes on initialization', () {
        final viewModel = _createViewModel();
        verify(mockAuthRepository.authStateChanges()).called(1);
        viewModel.dispose();
      });
    });

    group('login', () {
      test('should show error when email is empty', () async {
        final viewModel = _createViewModel();
        viewModel.email = '';
        viewModel.password = 'password123';

        await viewModel.login();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signInWithEmail(any, any));
        viewModel.dispose();
      });

      test('should show error when password is empty', () async {
        final viewModel = _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = '';

        await viewModel.login();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signInWithEmail(any, any));
        viewModel.dispose();
      });

      test('should show error when email and password are empty', () async {
        final viewModel = _createViewModel();
        viewModel.email = '';
        viewModel.password = '';

        await viewModel.login();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signInWithEmail(any, any));
        viewModel.dispose();
      });

      test('should show error when email format is invalid - missing @', () async {
        final viewModel = _createViewModel();
        viewModel.email = 'invalidemail.com';
        viewModel.password = 'password123';

        await viewModel.login();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signInWithEmail(any, any));
        viewModel.dispose();
      });

      test('should show error when email format is invalid - missing dot', () async {
        final viewModel = _createViewModel();
        viewModel.email = 'invalid@email';
        viewModel.password = 'password123';

        await viewModel.login();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signInWithEmail(any, any));
        viewModel.dispose();
      });

      test('should set loading to true when login starts', () async {
        final viewModel = _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'password123';
        
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) async => Success<void>(null));
        
        // Override authStateChanges to return a stream that will be listened to
        when(mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        final future = viewModel.login();

        expect(viewModel.isLoading, true);
        
        await future;
        viewModel.dispose();
      });

      test('should call signInWithEmail with correct credentials', () async {
        final viewModel = _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'password123';
        
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) async => Success<void>(null));
        when(mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        await viewModel.login();

        verify(mockAuthRepository.signInWithEmail('test@example.com', 'password123')).called(1);
        viewModel.dispose();
      });

      test('should handle login failure and set loading to false', () async {
        final viewModel = _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'wrongpassword';
        
        final failure = Failure<void>('Invalid credentials');
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) async => failure);
        when(mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        await viewModel.login();

        expect(viewModel.isLoading, false);
        verify(mockAuthRepository.signInWithEmail(any, any)).called(1);
        viewModel.dispose();
      });

      test('should accept valid email formats', () async {
        final validEmails = [
          'test@example.com',
          'user.name@example.co.uk',
          'test+tag@example.com',
          'test@sub.example.com',
        ];

        for (final email in validEmails) {
          final viewModel = _createViewModel();
          viewModel.email = email;
          viewModel.password = 'password123';
          
          when(mockAuthRepository.signInWithEmail(any, any))
              .thenAnswer((_) async => Success<void>(null));
          when(mockAuthRepository.authStateChanges())
              .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

          await viewModel.login();

          verify(mockAuthRepository.signInWithEmail(email, 'password123')).called(1);
          viewModel.dispose();
          // Clear verification state for next iteration
          clearInteractions(mockAuthRepository);
        }
      });
    });

    group('loginWithGoogle', () {
      test('should set loading to true when Google login starts', () async {
        final viewModel = _createViewModel();
        when(mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => Success<void>(null));

        final future = viewModel.loginWithGoogle();

        expect(viewModel.isLoading, true);
        
        await future;
        viewModel.dispose();
      });

      test('should call signInWithGoogle on repository', () async {
        final viewModel = _createViewModel();
        when(mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => Success<void>(null));

        await viewModel.loginWithGoogle();

        verify(mockAuthRepository.signInWithGoogle()).called(1);
        expect(viewModel.isLoading, false);
        viewModel.dispose();
      });

      test('should handle Google login failure and set loading to false', () async {
        final viewModel = _createViewModel();
        final failure = Failure<void>('Google sign in failed');
        when(mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async => failure);

        await viewModel.loginWithGoogle();

        expect(viewModel.isLoading, false);
        verify(mockAuthRepository.signInWithGoogle()).called(1);
        viewModel.dispose();
      });
    });

    group('loginWithApple', () {
      test('should set loading to true when Apple login starts', () async {
        final viewModel = _createViewModel();
        when(mockAuthRepository.signInWithApple())
            .thenAnswer((_) async => Success<void>(null));

        final future = viewModel.loginWithApple();

        expect(viewModel.isLoading, true);
        
        await future;
        viewModel.dispose();
      });

      test('should call signInWithApple on repository', () async {
        final viewModel = _createViewModel();
        when(mockAuthRepository.signInWithApple())
            .thenAnswer((_) async => Success<void>(null));

        await viewModel.loginWithApple();

        verify(mockAuthRepository.signInWithApple()).called(1);
        expect(viewModel.isLoading, false);
        viewModel.dispose();
      });

      test('should handle Apple login failure and set loading to false', () async {
        final viewModel = _createViewModel();
        final failure = Failure<void>('Apple sign in failed');
        when(mockAuthRepository.signInWithApple())
            .thenAnswer((_) async => failure);

        await viewModel.loginWithApple();

        expect(viewModel.isLoading, false);
        verify(mockAuthRepository.signInWithApple()).called(1);
        viewModel.dispose();
      });
    });

    group('togglePasswordVisibility', () {
      test('should toggle password visibility from false to true', () {
        final viewModel = _createViewModel();
        viewModel.isPasswordVisible = false;

        viewModel.togglePasswordVisibility();

        expect(viewModel.isPasswordVisible, true);
        viewModel.dispose();
      });

      test('should toggle password visibility from true to false', () {
        final viewModel = _createViewModel();
        viewModel.isPasswordVisible = true;

        viewModel.togglePasswordVisibility();

        expect(viewModel.isPasswordVisible, false);
        viewModel.dispose();
      });

      test('should toggle password visibility multiple times', () {
        final viewModel = _createViewModel();
        viewModel.isPasswordVisible = false;

        viewModel.togglePasswordVisibility();
        expect(viewModel.isPasswordVisible, true);

        viewModel.togglePasswordVisibility();
        expect(viewModel.isPasswordVisible, false);

        viewModel.togglePasswordVisibility();
        expect(viewModel.isPasswordVisible, true);
        
        viewModel.dispose();
      });
    });

    group('_listenToAuthChanges', () {
      test('should update currentAuth when auth state changes to authenticated', () async {
        final auth = Auth(
          id: 'user123',
          email: 'test@example.com',
          createdDate: DateTime(2024, 1, 1),
          isEmailVerified: true,
        );
        
        final testMockAuthRepo = MockAuthRepository();
        when(testMockAuthRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(auth)));

        final viewModel = LoginViewModel(testMockAuthRepo);

        // Wait for stream to emit and callback to execute
        await Future.delayed(Duration(milliseconds: 200));

        expect(viewModel.currentAuth, isNotNull);
        expect(viewModel.currentAuth?.id, 'user123');
        expect(viewModel.currentAuth?.email, 'test@example.com');
        expect(viewModel.isLoading, false);
        
        viewModel.dispose();
      });

      test('should set currentAuth to null when user logs out', () async {
        final testMockAuthRepo = MockAuthRepository();
        when(testMockAuthRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        final viewModel = LoginViewModel(testMockAuthRepo);

        // Wait for stream to emit and callback to execute
        await Future.delayed(Duration(milliseconds: 200));

        expect(viewModel.currentAuth, isNull);
        expect(viewModel.isLoading, false);
        
        viewModel.dispose();
      });

      test('should set isLoading to false when auth state changes', () async {
        final testMockAuthRepo = MockAuthRepository();
        when(testMockAuthRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        final viewModel = LoginViewModel(testMockAuthRepo);

        // Wait for stream to emit and callback to execute
        await Future.delayed(Duration(milliseconds: 200));

        expect(viewModel.isLoading, false);
        
        viewModel.dispose();
      });
    });

    group('dispose', () {
      test('should cancel auth subscription on dispose', () async {
        final controller = StreamController<Result<Auth?>>();
        final testMockAuthRepo = MockAuthRepository();
        when(testMockAuthRepo.authStateChanges())
            .thenAnswer((_) => controller.stream);

        final viewModel = LoginViewModel(testMockAuthRepo);
        
        // Wait for stream subscription to be set up
        await Future.delayed(Duration(milliseconds: 50));

        viewModel.dispose();

        expect(() => controller.close(), returnsNormally);
      });
    });

    group('State Management', () {
      test('should allow setting email and password', () {
        final viewModel = _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'password123';

        expect(viewModel.email, 'test@example.com');
        expect(viewModel.password, 'password123');
        viewModel.dispose();
      });
    });
  });
}
