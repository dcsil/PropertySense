import '../../domain/models/auth_model.dart';
import '../../domain/models/user_model.dart';
import '../../utils/result.dart';

abstract class AuthRepository {
    Stream<Result<Auth?>> authStateChanges();
    Future<Result<void>> signInWithEmail(String email, String password);
    Future<Result<void>> signInWithGoogle();
    Future<Result<void>> signInWithApple();
}

abstract class UserRepository {
    Stream<Result<User?>> userStateChanges();
}