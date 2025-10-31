import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';

class UserRepositoryLocal implements UserRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepo;

  UserRepositoryLocal({
    required FirebaseFirestore firestore,
    required AuthRepository authRepo,
    String emulatorHost = 'localhost',
    int emulatorPort = 8080,
  }) : _firestore = firestore, _authRepo = authRepo {
    _firestore.useFirestoreEmulator(emulatorHost, emulatorPort);
  }

  @override
  Stream<Result<User?>> userStateChanges() {
    return _authRepo.authStateChanges().asyncMap((authResult) async {
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
      final doc = await _firestore.collection('users').doc(auth.id).get();

      // TODO this is when user is logged in but user document is missing
      // We should handle this safely. For not the behavior is just to log them out.
      if (!doc.exists || doc.data() == null) {
        await _authRepo.signOut();
        return Failure('Could not find user document for authenticated user ${auth.id}\n Please contact Support.');
      }

      final user = User.fromFirestore(doc, null);
      return Success(user);
    } catch (e) {
      return Failure('Failed to fetch user: $e');
    }
  }
}
