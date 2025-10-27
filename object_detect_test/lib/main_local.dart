import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object_detect_test/data/repos/auth/auth_repository_local.dart';
import 'package:object_detect_test/data/repos/user/user_repository_local.dart';
import 'package:object_detect_test/utils/toaster.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/domain/models/user_model.dart';
import 'package:object_detect_test/utils/result.dart';
import 'package:object_detect_test/ui/views/login_screen.dart';
import 'package:object_detect_test/ui/views/homeowner_home_screen.dart';
import 'package:object_detect_test/ui/views/contractor_home_screen.dart';

void main() async {
  // Preserve native splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Firebase while native splash is showing
  await Firebase.initializeApp();

  const seedColor = Colors.deepPurple;

  final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  runApp(
    MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Property Sense',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: MultiProvider(
        providers: [
          Provider<AuthRepository>(
            create: (_) => AuthRepositoryLocal(
              firebaseAuth: fb_auth.FirebaseAuth.instance,
            ),
          ),
          Provider<UserRepository>(
            create: (context) => UserRepositoryLocal(
              firestore: FirebaseFirestore.instance,
              authRepo: context.read<AuthRepository>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final userRepo = context.read<UserRepository>();

            return StreamBuilder<Result<User?>>(
              stream: userRepo.userStateChanges(),
              builder: (context, snapshot) {
                // Keep splash while waiting for auth state
                if (!snapshot.hasData ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final userResult = snapshot.data!;

                // Handle failure - remove splash and show login
                if (userResult is Failure) {
                  // Exit splash screen and go to login screen
                  print('User state failure: ${(userResult as Failure).message}');
                  FlutterNativeSplash.remove();
                  return const LoginScreen();
                }

                // Success - get the user
                final user = (userResult as Success<User?>).value;

                // Remove splash screen when ready to show content
                FlutterNativeSplash.remove();

                // Route based on user state
                if (user == null) return const LoginScreen();
                // if (!user.isOnboarded) return const OnboardingPage();
                if (user.type == UserType.homeowner) return const HomeScreen();
                if (user.type == UserType.contractor) return const ContractorHomeScreen();
                // Fallback
                return LoginScreen();
              },
            );
          },
        ),
      ),
    ),
  );
}
