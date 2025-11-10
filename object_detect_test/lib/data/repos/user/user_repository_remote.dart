import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';

class UserRepositoryRemote implements UserRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;
  UserRepositoryRemote({required FirebaseFirestore firestore, required AuthRepository authRepo})
      : _firestore = firestore,
        _authRepo = authRepo;

  @override
  User? currentUser;

  @override
  Stream<Result<User?>> userStateChanges() {
    return _authRepo.authStateChanges().asyncMap((authResult) async {
      return switch (authResult) {
        Success(value: final auth) when auth == null => Success<User?>(currentUser = null),

        Success(value: final auth) => await fetchUser(auth!.id),

        Failure(message: final message) => Failure<User?>(
          'Auth error: $message',
        ),
      };
    });
  }

  @override
  Future<Result<void>> createUserDocument(User user) async {
    try {
      // This is same as put
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
      return Success(null);
    } catch (e) {
      return Failure('Failed to create user document: $e');
    }
  }


  @override
  Future<Result<User?>> fetchUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      // TODO this is when user is logged in but user document is missing
      // We should handle this safely. For not the behavior is just to log them out.
      if (!doc.exists || doc.data() == null) {
        await _authRepo.signOut();
        return Failure('Could not find user document for authenticated user $uid\n Please contact Support.');
      }

      final user = await User.fromFirestore(doc, null);
      currentUser = user;
      return Success(user);
    } catch (e) {
      print(e);
      return Failure('Failed to fetch user: $e');
    }
  }
}
