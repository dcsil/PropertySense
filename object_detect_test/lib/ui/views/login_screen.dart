import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/ui/viewmodels/login_viewmodel.dart';
import 'package:object_detect_test/utils/widget_keys.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.currentAuth != null) {
        context.go('/register');
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
                    'Sign in to continue',
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
                    onFieldSubmitted: (_) => viewModel.login(),
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
                  const SizedBox(height: 8),

                  // Forgot password link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      // Navigate to forgot password screen
                      onPressed: () {
                        Navigator.of(context).pushNamed('/forgot-password');
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login button
                  FilledButton(
                    key: WidgetKeys.loginButton,
                    onPressed: viewModel.isLoading ? null : viewModel.login,
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
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 24),

                  // Divider with "or"
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google sign-in button
                  OutlinedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : viewModel.loginWithGoogle,
                    icon: Image.asset(
                      'assets/google_logo.png', // You'll need to add this
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.g_mobiledata, size: 24);
                      },
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apple sign-in button
                  OutlinedButton.icon(
                    onPressed: viewModel.isLoading
                        ? null
                        : viewModel.loginWithApple,
                    icon: const Icon(Icons.apple, size: 24),
                    label: const Text('Continue with Apple'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to sign up page
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sign up coming soon'),
                            ),
                          );
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
