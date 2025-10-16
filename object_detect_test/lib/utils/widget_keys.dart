import 'package:flutter/foundation.dart';

/// Centralized widget keys for testing and widget identification.
/// 
/// Usage in widgets:
///   Scaffold(key: WidgetKeys.loginPage, ...)
/// 
/// Usage in tests:
///   expect(find.byKey(WidgetKeys.loginPage), findsOneWidget);
class WidgetKeys {
  WidgetKeys._();

  // ==================== Pages ====================
  static const loginPage = Key('login_page');
  static const homePage = Key('home_page');

  // ==================== Login Screen ====================
  static const emailField = Key('email_field');
  static const passwordField = Key('password_field');
  static const loginButton = Key('login_button');
  static const forgotPasswordButton = Key('forgot_password_button');
  static const signUpButton = Key('sign_up_button');

  // ==================== Home Screen ====================
  static const logoutButton = Key('logout_button');
  static const welcomeText = Key('welcome_text');
  static const navigationDrawer = Key('navigation_drawer');

  // ==================== Common Components ====================
  static const loadingIndicator = Key('loading_indicator');
  static const errorMessage = Key('error_message');
  static const submitButton = Key('submit_button');
  static const cancelButton = Key('cancel_button');

  // ==================== Lists & Items ====================
  static Key listItem(String id) => Key('list_item_$id');
  static Key deleteButton(String id) => Key('delete_button_$id');
  static Key editButton(String id) => Key('edit_button_$id');
}