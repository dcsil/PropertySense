import 'dart:async';

import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  
  bool isLoading = false;

  bool isPasswordVisible = false;

  String email = '';
  String password = '';

  User? currentUser;
  
  StreamSubscription<Result<User?>>? _userSubscription;
  
  LoginViewModel(this._authRepository, this._userRepository) {
    _listenToUserChanges();
  }
  
  void _listenToUserChanges() {
    _userSubscription = _userRepository.userStateChanges().listen((result) {
      if (result is Success) {
        currentUser = (result as Success).value;
        notifyListeners(); // ← Triggers view to check navigation
      } else if (result is Failure) {
        currentUser = null;
        Toaster.showError((result as Failure).message);
        notifyListeners();
      }
    });
  }
  
  // We're not doing navigation in the viewmodel. View will be listening and then on login success it will navigate.
  Future<void> login() async {
    print(email);
    print(password);
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
    
    final result = await _authRepository.signInWithEmail(email, password);
    
    isLoading = false;
    notifyListeners();
    
    if (result is Failure) {
      Toaster.showErrorFromFailure(result);
    }
  }

  Future<void> loginWithGoogle() async {
    isLoading = true;
    notifyListeners();

    final result = await _authRepository.signInWithGoogle();

    isLoading = false;
    notifyListeners();
    
    if (result is Failure) {
      Toaster.showErrorFromFailure(result);
    }
  }

  Future<void> loginWithApple() async {
    isLoading = true;
    notifyListeners();

    final result = await _authRepository.signInWithApple();

    isLoading = false;
    notifyListeners();

    if (result is Failure) {
      Toaster.showErrorFromFailure(result);
    }
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }
  
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }
}