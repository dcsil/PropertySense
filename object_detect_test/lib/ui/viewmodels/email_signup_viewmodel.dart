import 'dart:async';

import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class EmailSignupViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool isLoading = false;

  bool isPasswordVisible = false;

  String email = '';
  String password = '';

  Auth? currentAuth;

  StreamSubscription<Result<Auth?>>? _authSubscription;

  EmailSignupViewModel(this._authRepository) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = _authRepository.authStateChanges().listen((result) {
      // Set isLoading to false when user state changes are received
      isLoading = false;
      switch (result) {
        case Success<Auth?>():
          currentAuth = result.value;
          notifyListeners();
        case Failure():
          Toaster.showError(
            'Could not fetch user data: ${(result as Failure).message}',
          );
      }
    });
  }

  // We're not doing navigation in the viewmodel. View will be listening and then on login success it will navigate.
  Future<void> signUpWithEmail() async {
    if (email.isEmpty || password.isEmpty) {
      Toaster.showError('Please enter email and password');
      return;
    }

    if (!_isValidEmail(email)) {
      Toaster.showError('Invalid email format$email');
      return;
    }

    isLoading = true;
    notifyListeners();

    final result = await _authRepository.signUpWithEmail(email, password);

    // We set isLoading to false when user changes are received so that we keep loading until user state change is populated.

    // If result is failure then we can set loading false right away.
    if (result is Failure) {
      Toaster.showErrorFromFailure(result);
      if (isLoading) {
        isLoading = false;
      }
    }

    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }
}
