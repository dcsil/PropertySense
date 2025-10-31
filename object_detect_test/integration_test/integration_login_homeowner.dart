import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/main_local.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:object_detect_test/utils/widget_keys.dart';
import 'package:provider/provider.dart';

// Integration test for login screen, view model and related repositories.
// Ensure that the firebase emulator is populated with relevant data e.g. firebase emulator:start --import=./emulator_data
// Integration flow:
// This test assumes that we're at the login screen at the start.
// 0. Log out to ensure any previous session is cleared
// 1. Launch app
// 2. Logout
// 3. Attempt to login with alice@homeowner.com account -> Should bring to homeowner home screen
// 4. Logout at the end

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test the login screen for homeowner login', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    BuildContext context = tester.element(find.byKey(WidgetKeys.mainApp));
    AuthRepository authRepo = Provider.of<AuthRepository>(context, listen: false);
    await authRepo.signOut();
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Assume we start at login screen
    expect(find.byKey(WidgetKeys.loginPage), findsOneWidget);

    // Now try logging in with alice homeowner
    await tester.enterText(
      find.byKey(WidgetKeys.emailField),
      'alice@homeowner.com',
    );
    await tester.enterText(find.byKey(WidgetKeys.passwordField), 'Hello123!');

    // This time press enter on password field to submit
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    // Should be on homeowner home page
    expect(find.byKey(WidgetKeys.homeOwnerHomePage), findsOneWidget);

    // Sign out at the end (for cases we run serialize multiple integration tests)
    // Also navigate back to login screen
    await authRepo.signOut();
    await Future.delayed(const Duration(seconds: 2));
    final homeContext  = tester.element(find.byKey(WidgetKeys.homeOwnerHomePage));
    homeContext.go('/');
    await tester.pumpAndSettle();
  });
}
