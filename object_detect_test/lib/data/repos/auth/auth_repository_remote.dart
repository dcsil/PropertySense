import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:object_detect_test/data/repos/repositories.dart';

import '../../../domain/models/auth_model.dart';
import '../../../utils/result.dart';

// User type in this file refers to Firebase User not domain User

class AuthRepositoryRemote implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  AuthRepositoryRemote({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  @override
  Stream<Result<Auth?>> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(
      (User? user) => _mapFbUserToAuth(user),
    );
  }

  @override
  Future<Result<void>> signInWithEmail(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
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
    try {
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      await FirebaseAuth.instance.signInWithCredential(credential);

      return Success(null);
    } catch (e) {
      return Failure('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<Result<void>> signInWithApple() async {
    // TODO
    return Failure('Sign in with Apple not implemented yet');
    // try {
    //   await _firebaseAuth.signInWithApple();
    //   return Success(null);
    // } catch (e) {
    //   return Failure('Failed to sign in with Apple: $e');
    // }
  }

  Result<Auth?> _mapFbUserToAuth(User? user) {
    if (user == null) return Success(null);
    final DateTime? created = user.metadata.creationTime;
    if (created == null) {
      return Failure(
        'Could not map firebase user to domain Auth: creationTime is null',
      );
    }

    return Success(Auth(userID: user.uid, createdDate: created));
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return Success(null);
    } catch (e) {
      return Failure('Failed to sign out: $e');
    }
  }
}
