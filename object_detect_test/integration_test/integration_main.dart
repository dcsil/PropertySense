import 'package:object_detect_test/main_local.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:object_detect_test/utils/widget_keys.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test the app', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Should end up on the login screen
    expect(find.byKey(WidgetKeys.loginPage), findsOneWidget);
    
    // Now interact with it
    await tester.tap(find.byKey(WidgetKeys.loginButton));
  });
}