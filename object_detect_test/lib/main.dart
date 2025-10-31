import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:object_detect_test/data/repos/repositories.dart';
import 'package:object_detect_test/data/repos/auth/auth_repository_remote.dart';
import 'package:object_detect_test/data/repos/user/user_repository_remote.dart';
import 'package:object_detect_test/ui/viewmodels/login_viewmodel.dart';
import 'package:object_detect_test/utils/router.dart';
import 'package:object_detect_test/utils/toaster.dart';
import 'package:object_detect_test/utils/widget_keys.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  const seedColor = Colors.deepPurple;
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) =>
              AuthRepositoryRemote(firebaseAuth: fb_auth.FirebaseAuth.instance),
        ),
        Provider<UserRepository>(
          create: (context) => UserRepositoryRemote(
            firestore: FirebaseFirestore.instance,
            authRepo: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(
            context.read<AuthRepository>(),
            context.read<UserRepository>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        key: WidgetKeys.mainApp,
        routerConfig: router,
        scaffoldMessengerKey: Toaster.scaffoldMessengerKey,
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
      ),
    ),
  );
}
