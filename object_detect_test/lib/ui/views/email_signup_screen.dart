import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/ui/viewmodels/email_signup_viewmodel.dart';
import 'package:object_detect_test/utils/widget_keys.dart';
import 'package:provider/provider.dart';

class EmailSignupScreen extends StatelessWidget {
  const EmailSignupScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EmailSignupViewModel(
        context.read<AuthRepository>()
      ),
      child: EmailSignupScreenContent()
      
    );
}
}

class EmailSignupScreenContent extends StatelessWidget {

  const EmailSignupScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<EmailSignupViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.currentAuth != null) {
        context.go('/verify-email');
      }
    });

    return Scaffold(
      key: WidgetKeys.loginPage,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo or title
                  Icon(
                    Icons.home_work,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Property Sense',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up with your email and password.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Email field
                  TextFormField(
                    key: WidgetKeys.emailField,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,

                    onChanged: (value) => viewModel.email = value,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    key: WidgetKeys.passwordField,
                    obscureText: viewModel.isPasswordVisible ? false : true,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) => viewModel.password = value,
                    onFieldSubmitted: (_) => viewModel.signUpWithEmail(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          viewModel.isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: viewModel.togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  // Login button
                  FilledButton(
                    key: WidgetKeys.loginButton,
                    onPressed: viewModel.isLoading ? null : viewModel.signUpWithEmail,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: viewModel.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
