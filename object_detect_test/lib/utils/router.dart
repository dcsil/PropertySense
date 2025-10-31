import 'package:go_router/go_router.dart';
import 'package:object_detect_test/ui/views/contractor_home_screen.dart';
import 'package:object_detect_test/ui/views/homeowner_home_screen.dart';
import 'package:object_detect_test/ui/views/login_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomeOwnerHomeScreen();
      },
    ),
    GoRoute(
      path: '/contractor',
      builder: (context, state) {
        return const ContractorHomeScreen();
      },
    ),
  ],
);