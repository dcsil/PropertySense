import 'dart:async';

import 'package:flutter/material.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/auth_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/utils/toaster.dart';

class VerifyEmailViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool isLoading = false;
  Auth? currentAuth;
  
  // Timer for resend cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  
  // Timer for polling email verification status
  Timer? _pollTimer;

  StreamSubscription<Result<Auth?>>? _authSubscription;

  VerifyEmailViewModel(this._authRepository) {
    sendVerificationEmail();
    _listenToAuthChanges();
    _startPolling();
  }

  int get resendCooldown => _resendCooldown;
  bool get canResendEmail => _resendCooldown == 0 && !isLoading;

  void _listenToAuthChanges() {
    _authSubscription = _authRepository.authStateChanges().listen((result) {
      isLoading = false;
      switch (result) {
        case Success<Auth?>():
          currentAuth = result.value;
          notifyListeners();
          print(currentAuth?.isEmailVerified);
        case Failure():
          Toaster.showError(
            'Could not fetch user data: ${(result as Failure).message}',
          );
      }
    });
  }

  void _startPolling() {
    // Poll every 10 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      print('polled');
      await _authRepository.firebaseAuthInstance.currentUser!.reload();
    });
  }

  Future<void> sendVerificationEmail() async {
    if (!canResendEmail) {
      Toaster.showError('Please wait $_resendCooldown seconds before resending');
      return;
    }

    isLoading = true;
    notifyListeners();

    final result = await _authRepository.sendVerificationEmail();

    isLoading = false;
    if (result is Success) {
      Toaster.showSuccess('Verification email sent!');
      _startCooldown();
    } else if (result is Failure) {
      Toaster.showErrorFromFailure(result);
    }

    notifyListeners();
  }

  void _startCooldown() {
    _resendCooldown = 15;
    _cooldownTimer?.cancel();
    
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendCooldown--;
      
      if (_resendCooldown <= 0) {
        _resendCooldown = 0;
        timer.cancel();
      }
      
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}