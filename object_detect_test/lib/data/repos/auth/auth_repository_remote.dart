import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:object_detect_test/data/repos/repositories.dart';

import '../../../domain/models/auth_model.dart';
import '../../../utils/result.dart';

// User type in this file refers to Firebase User not domain User

class AuthRepositoryRemote implements AuthRepository {

  AuthRepositoryRemote({required FirebaseAuth firebaseAuth})
    : firebaseAuthInstance = firebaseAuth;

  @override
  FirebaseAuth firebaseAuthInstance;

  @override
  Stream<Result<Auth?>> authStateChanges() {
    return firebaseAuthInstance.userChanges().map(
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
      await firebaseAuthInstance.signInWithCredential(credential);

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
    //   await firebaseAuthInstance.signInWithApple();
    //   return Success(null);
    // } catch (e) {
    //   return Failure('Failed to sign in with Apple: $e');
    // }
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
    return Success(Auth(id: user.uid, email: email, createdDate: created, isEmailVerified: user.emailVerified));
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
