import 'package:firebase_auth/firebase_auth.dart';
import 'package:object_detect_test/data/repos/repositories.dart';

import '../../../domain/models/auth_model.dart';
import '../../../utils/result.dart';

// User type in this file refers to Firebase User not domain User

class AuthRepositoryRemote implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  AuthRepositoryRemote({required FirebaseAuth firebaseAuth}) : _firebaseAuth = firebaseAuth;

  @override
  Stream<Result<Auth?>> authStateChanges() {
    return _firebaseAuth
        .authStateChanges()
        .map((User? user) => _mapFbUserToAuth(user));
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