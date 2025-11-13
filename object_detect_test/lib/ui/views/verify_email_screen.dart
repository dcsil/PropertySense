import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/ui/viewmodels/verify_email_viewmodel.dart';
import 'package:provider/provider.dart';

class VerifyEmailScreen extends StatelessWidget { 
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VerifyEmailViewModel(
        context.read<AuthRepository>(),
      ),
      child: const VerifyEmailScreenContent(),
    );
  }
}

class VerifyEmailScreenContent extends StatelessWidget {
  const VerifyEmailScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<VerifyEmailViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.currentAuth != null && viewModel.currentAuth!.isEmailVerified) {
        context.go('/register');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Verification Email Sent!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Please check your inbox',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive it? ",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (viewModel.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    TextButton(
                      onPressed: viewModel.canResendEmail
                          ? () => viewModel.sendVerificationEmail()
                          : null,
                      child: Text(
                        viewModel.resendCooldown > 0
                            ? 'Resend in ${viewModel.resendCooldown}s'
                            : 'Resend',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}