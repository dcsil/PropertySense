import 'package:firebase_auth/firebase_auth.dart';
import 'package:object_detect_test/data/repos/repositories.dart';

import '../../../domain/models/auth_model.dart';
import '../../../utils/result.dart';

// User type in this file refers to Firebase User not domain User

class AuthRepositoryLocal implements AuthRepository {
  AuthRepositoryLocal({
    required FirebaseAuth firebaseAuth,
    String emulatorHost = 'localhost',
    int emulatorPort = 9099,
  }) : firebaseAuthInstance = firebaseAuth {
    firebaseAuthInstance.useAuthEmulator(emulatorHost, emulatorPort);
  }

  @override
  final FirebaseAuth firebaseAuthInstance;

  @override
  Stream<Result<Auth?>> authStateChanges() {
    return firebaseAuthInstance.authStateChanges().map(
      (User? user) => _mapFbUserToAuth(user),
    );
  }

  @override
  Future<Result<void>> signInWithEmail(String email, String password) async {
    try {
      await firebaseAuthInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Success(null);
    } catch (e) {
      return Failure('Failed to sign in with email and password: $e');
    }
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    return Failure('Sign in with Google not supported in local emulator');
  }

  @override
  Future<Result<void>> signInWithApple() async {
    return Failure('Sign in with Apple not supported in local emulator');
  }

  Result<Auth?> _mapFbUserToAuth(User? user) {
    if (user == null) return Success(null);
    final String? email = user.email;
    if (email == null) {
      return Failure(
        'Could not map firebase user to domain Auth: email is null',
      );
    }
    final DateTime? created = user.metadata.creationTime;
    if (created == null) {
      return Failure(
        'Could not map firebase user to domain Auth: creationTime is null',
      );
    }
    return Success(Auth(id: user.uid, email: email, createdDate: created));
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await firebaseAuthInstance.signOut();
      return Success(null);
    } catch (e) {
      return Failure('Failed to sign out: $e');
    }
  }

  @override
  Future<Result<void>> signUpWithEmail(String email, String password) async {
    try {
      await firebaseAuthInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return Success(null);
    } catch (e) {
      return Failure('Failed to sign up with email and password: $e');
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuthInstance.sendPasswordResetEmail(email: email);
      return Success(null);
    } catch (e) {
      return Failure('Failed to send password reset email: $e');
    }
  }

  @override
  Future<Result<void>> sendVerificationEmail() async {
    try {
      await firebaseAuthInstance.currentUser?.sendEmailVerification();
      return Success(null);
    } catch (e) {
      return Failure('Failed to send verification email: $e');
    }
  }
}
