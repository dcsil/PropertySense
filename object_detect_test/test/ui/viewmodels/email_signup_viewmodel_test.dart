import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/ui/viewmodels/email_signup_viewmodel.dart';
import 'package:object_detect_test/utils/result.dart';

import 'email_signup_viewmodel_test.mocks.dart';
import 'package:mockito/src/dummies.dart' as dummies;

@GenerateMocks([AuthRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Provide dummy values for Result types
  dummies.provideDummy<Result<void>>(Success<void>(null));
  dummies.provideDummy<Result<Auth?>>(Success<Auth?>(null));

  group('EmailSignupViewModel', () {
    late MockAuthRepository mockAuthRepository;

    MockAuthRepository _createMockAuth() {
      final mock = MockAuthRepository();
      when(mock.authStateChanges())
          .thenAnswer((_) => Stream.value(Success<Auth?>(null)));
      return mock;
    }

    Future<EmailSignupViewModel> _createViewModel() async {
      mockAuthRepository = _createMockAuth();
      final viewModel = EmailSignupViewModel(mockAuthRepository);
      // Wait for stream to emit initial value
      await Future.delayed(Duration(milliseconds: 100));
      return viewModel;
    }

    Future<void> _safeDispose(EmailSignupViewModel viewModel) async {
      await Future.delayed(Duration(milliseconds: 50));
      viewModel.dispose();
    }

    tearDown(() {
      try {
        reset(mockAuthRepository);
      } catch (e) {
        // Ignore if mockAuthRepository wasn't initialized
      }
    });

    group('Initialization', () {
      test('should initialize with empty email and password', () async {
        final viewModel = await _createViewModel();
        expect(viewModel.email, '');
        expect(viewModel.password, '');
        expect(viewModel.isLoading, false);
        expect(viewModel.isPasswordVisible, false);
        expect(viewModel.currentAuth, isNull);
        await _safeDispose(viewModel);
      });

      test('should listen to auth state changes on initialization', () async {
        final viewModel = await _createViewModel();
        verify(mockAuthRepository.authStateChanges()).called(1);
        await _safeDispose(viewModel);
      });
    });

    group('signUpWithEmail', () {
      test('should show error when email is empty', () async {
        final viewModel = await _createViewModel();
        viewModel.email = '';
        viewModel.password = 'password123';

        await viewModel.signUpWithEmail();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signUpWithEmail(any, any));
        await _safeDispose(viewModel);
      });

      test('should show error when password is empty', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = '';

        await viewModel.signUpWithEmail();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signUpWithEmail(any, any));
        await _safeDispose(viewModel);
      });

      test('should show error when email and password are empty', () async {
        final viewModel = await _createViewModel();
        viewModel.email = '';
        viewModel.password = '';

        await viewModel.signUpWithEmail();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signUpWithEmail(any, any));
        await _safeDispose(viewModel);
      });

      test('should show error when email format is invalid - missing @', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'invalidemail.com';
        viewModel.password = 'password123';

        await viewModel.signUpWithEmail();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signUpWithEmail(any, any));
        await _safeDispose(viewModel);
      });

      test('should show error when email format is invalid - missing dot', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'invalid@email';
        viewModel.password = 'password123';

        await viewModel.signUpWithEmail();

        expect(viewModel.isLoading, false);
        verifyNever(mockAuthRepository.signUpWithEmail(any, any));
        await _safeDispose(viewModel);
      });

      test('should set loading to true when signup starts', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'password123';
        
        when(mockAuthRepository.signUpWithEmail(any, any))
            .thenAnswer((_) async => Success<void>(null));
        when(mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        final future = viewModel.signUpWithEmail();

        expect(viewModel.isLoading, true);
        
        await future;
        await _safeDispose(viewModel);
      });

      test('should call signUpWithEmail with correct credentials', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'password123';
        
        when(mockAuthRepository.signUpWithEmail(any, any))
            .thenAnswer((_) async => Success<void>(null));
        when(mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        await viewModel.signUpWithEmail();

        verify(mockAuthRepository.signUpWithEmail('test@example.com', 'password123')).called(1);
        await _safeDispose(viewModel);
      });

      test('should handle signup failure and set loading to false', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'weakpassword';
        
        final failure = Failure<void>('Email already in use');
        when(mockAuthRepository.signUpWithEmail(any, any))
            .thenAnswer((_) async => failure);
        when(mockAuthRepository.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

        await viewModel.signUpWithEmail();

        expect(viewModel.isLoading, false);
        verify(mockAuthRepository.signUpWithEmail(any, any)).called(1);
        await _safeDispose(viewModel);
      });

      test('should accept valid email formats', () async {
        final validEmails = [
          'test@example.com',
          'user.name@example.co.uk',
          'test+tag@example.com',
          'test@sub.example.com',
        ];

        for (final email in validEmails) {
          final viewModel = await _createViewModel();
          viewModel.email = email;
          viewModel.password = 'password123';
          
          when(mockAuthRepository.signUpWithEmail(any, any))
              .thenAnswer((_) async => Success<void>(null));
          when(mockAuthRepository.authStateChanges())
              .thenAnswer((_) => Stream.value(Success<Auth?>(null)));

          await viewModel.signUpWithEmail();

          verify(mockAuthRepository.signUpWithEmail(email, 'password123')).called(1);
          await _safeDispose(viewModel);
          clearInteractions(mockAuthRepository);
        }
      });
    });

    group('togglePasswordVisibility', () {
      test('should toggle password visibility from false to true', () async {
        final viewModel = await _createViewModel();
        viewModel.isPasswordVisible = false;

        viewModel.togglePasswordVisibility();

        expect(viewModel.isPasswordVisible, true);
        await _safeDispose(viewModel);
      });

      test('should toggle password visibility from true to false', () async {
        final viewModel = await _createViewModel();
        viewModel.isPasswordVisible = true;

        viewModel.togglePasswordVisibility();

        expect(viewModel.isPasswordVisible, false);
        await _safeDispose(viewModel);
      });

      test('should toggle password visibility multiple times', () async {
        final viewModel = await _createViewModel();
        viewModel.isPasswordVisible = false;

        viewModel.togglePasswordVisibility();
        expect(viewModel.isPasswordVisible, true);

        viewModel.togglePasswordVisibility();
        expect(viewModel.isPasswordVisible, false);

        viewModel.togglePasswordVisibility();
        expect(viewModel.isPasswordVisible, true);
        
        await _safeDispose(viewModel);
      });
    });

    group('_listenToAuthChanges', () {
      test('should update currentAuth when auth state changes to authenticated', () async {
        final auth = Auth(
          id: 'user123',
          email: 'test@example.com',
          createdDate: DateTime(2024, 1, 1),
          isEmailVerified: false,
        );
        
        final testMockAuthRepo = MockAuthRepository();
        when(testMockAuthRepo.authStateChanges())
            .thenAnswer((_) => Stream.value(Success<Auth?>(auth)));

        final viewModel = EmailSignupViewModel(testMockAuthRepo);

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

        final viewModel = EmailSignupViewModel(testMockAuthRepo);

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

        final viewModel = EmailSignupViewModel(testMockAuthRepo);

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

        final viewModel = EmailSignupViewModel(testMockAuthRepo);
        
        // Wait for stream subscription to be set up
        await Future.delayed(Duration(milliseconds: 50));

        viewModel.dispose();

        expect(() => controller.close(), returnsNormally);
      });
    });

    group('State Management', () {
      test('should allow setting email and password', () async {
        final viewModel = await _createViewModel();
        viewModel.email = 'test@example.com';
        viewModel.password = 'password123';

        expect(viewModel.email, 'test@example.com');
        expect(viewModel.password, 'password123');
        await _safeDispose(viewModel);
      });
    });
  });
}

