import 'package:integration_test/integration_test.dart';
import 'integration_login.dart' as login;
import 'integration_login_homeowner.dart' as login_homeowner;

// Runs all integration tests
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  login.main();
  login_homeowner.main();
}