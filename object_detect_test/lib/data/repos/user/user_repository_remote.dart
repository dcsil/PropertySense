import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';

class UserRepositoryRemote implements UserRepository {
  final FirebaseFirestore firestore;
  final AuthRepository authRepo;
  UserRepositoryRemote({required this.firestore, required this.authRepo});

  @override
  Stream<Result<User?>> userStateChanges() {
    return authRepo.authStateChanges().asyncMap((authResult) async {
      return switch (authResult) {
        Success(value: final auth) when auth == null => Success<User?>(null),

        Success(value: final auth) => await _fetchUser(auth!),

        Failure(message: final message) => Failure<User?>(
          'Auth error: $message',
        ),
      };
    });
  }

  Future<Result<User?>> _fetchUser(Auth auth) async {
    try {
      final doc = await firestore.collection('users').doc(auth.userID).get();

      if (!doc.exists) {
        return Success(null);
      }

      final data = doc.data();
      if (data == null) {
        return Failure('Could not find user ${auth.userID} in firestore');
      }

      final user = User.fromFirestore(doc, null);
      return Success(user);
    } catch (e) {
      return Failure('Failed to fetch user: $e');
    }
  }
}
