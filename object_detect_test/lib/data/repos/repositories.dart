import '../../domain/models/auth_model.dart';
import '../../domain/models/user_model.dart';
import '../../utils/result.dart';

abstract class AuthRepository {
    Stream<Result<Auth?>> authStateChanges();
}

abstract class UserRepository {
    Stream<Result<User?>> userStateChanges();
}