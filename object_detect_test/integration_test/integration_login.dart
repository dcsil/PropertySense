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
// 0. Log out to ensure any previous session is cleared
// 1. Launch app
// 2. Verify on login screen when not logged in
// 3. Attempt to login with invalid email/password -> verify error toast
// 4. Attempt to login with auth account with no firestore entry -> verify correct error toast
// 5. Attempt to login with bob@contractor.com account -> Should bring to contractor home screen
// 6. Logout at the end
// 7. Signout and navigate back to login screen

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test the login screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    BuildContext context = tester.element(find.byKey(WidgetKeys.mainApp));
    AuthRepository authRepo = Provider.of<AuthRepository>(context, listen: false);
    await authRepo.signOut();

    // wait for sign out to complete
    await Future.delayed(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Should end up on the login screen
    expect(find.byKey(WidgetKeys.loginPage), findsOneWidget);

    // Enter on email form
    await tester.enterText(
      find.byKey(WidgetKeys.emailField),
      'nonexistent@example.com',
    );
    // Enter password
    await tester.enterText(find.byKey(WidgetKeys.passwordField), 'Hello123!');
    // Tap login button
    await tester.tap(find.byKey(WidgetKeys.loginButton));
    await tester.pumpAndSettle();
    // Find snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Failed to sign in'), findsOneWidget);

    // wait for snackbar to go away
    await Future.delayed(const Duration(seconds: 3));

    // Clear
    await tester.enterText(find.byKey(WidgetKeys.emailField), '');
    await tester.enterText(find.byKey(WidgetKeys.passwordField), '');

    // Enter on email form
    await tester.enterText(
      find.byKey(WidgetKeys.emailField),
      'nofirestore@example.com',
    );
    // Enter password
    await tester.enterText(find.byKey(WidgetKeys.passwordField), 'Hello123!');
    // Tap login button
    await tester.tap(find.byKey(WidgetKeys.loginButton));
    await tester.pumpAndSettle();
    // Find snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    // Expect error toast saying Could not find user document for authenticated user ${auth.userID}\n Please contact Support.
    expect(
      find.textContaining(
        'Could not find user document for authenticated user',
      ),
      findsOneWidget,
    );
    // wait
    await tester.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 3));

    // Clear
    await tester.enterText(find.byKey(WidgetKeys.emailField), '');
    await tester.enterText(find.byKey(WidgetKeys.passwordField), '');

    // Now try with Bob contractor
    await tester.enterText(
      find.byKey(WidgetKeys.emailField),
      'bob@contractor.com',
    );
    await tester.enterText(find.byKey(WidgetKeys.passwordField), 'Hello123!');
    await tester.tap(find.byKey(WidgetKeys.loginButton));
    await tester.pumpAndSettle();
    // Should be on contractor home page
    expect(find.byKey(WidgetKeys.contractorHomePage), findsOneWidget);

    // Sign out at the end (for cases we run serialize multiple integration tests)
    await authRepo.signOut();
    await Future.delayed(const Duration(seconds: 2));
    final homeContext  = tester.element(find.byKey(WidgetKeys.contractorHomePage));
    homeContext.go('/');
    await tester.pumpAndSettle();
  });
}
