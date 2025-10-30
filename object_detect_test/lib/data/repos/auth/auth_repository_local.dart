import 'package:firebase_auth/firebase_auth.dart';
import 'package:object_detect_test/data/repos/repositories.dart';

import '../../../domain/models/auth_model.dart';
import '../../../utils/result.dart';

class AuthRepositoryLocal implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepositoryLocal({
    required FirebaseAuth firebaseAuth,
    String emulatorHost = 'localhost',
    int emulatorPort = 9099,
  }) : _firebaseAuth = firebaseAuth {_firebaseAuth.useAuthEmulator(emulatorHost, emulatorPort);}

  @override
  Stream<Result<Auth?>> authStateChanges() {
    return _firebaseAuth
        .authStateChanges()
        .map((User? user) => _mapFbUserToAuth(user));
  }

  @override
  Future<Result<void>> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
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
    final DateTime? created = user.metadata.creationTime;
    if (created == null) {
      return Failure('Could not map firebase user to domain Auth: creationTime is null');
    }

    return Success(Auth(userID: user.uid, createdDate: created));
  }
}