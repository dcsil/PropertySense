import 'package:go_router/go_router.dart';
import 'package:object_detect_test/ui/views/camera_screen.dart';
import 'package:object_detect_test/ui/views/contractor_home_screen.dart';
import 'package:object_detect_test/ui/views/create_listing_screen.dart';
import 'package:object_detect_test/ui/views/email_signup_screen.dart';
import 'package:object_detect_test/ui/views/homeowner_home_screen.dart';
import 'package:object_detect_test/ui/views/listing_detail_screen.dart';
import 'package:object_detect_test/ui/views/listings_screen.dart';
import 'package:object_detect_test/ui/views/login_screen.dart';
import 'package:object_detect_test/ui/views/registration_screen.dart';
import 'package:object_detect_test/ui/views/verify_email_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/listings',
      builder: (context, state) {
        return const ListingOverviewScreen();
      },
    ),
    GoRoute(
      path: '/listing/:id',
      builder: (context, state) {
        final listingId = state.pathParameters['id']!;
        return ListingDetailScreen(listingId: listingId);
      },
    ),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) {
        return const CreateListingScreen();
      },
    ),
    GoRoute(
      path: '/contractor',
      builder: (context, state) {
        return const ContractorHomeScreen();
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) {
        return const RegistrationScreen();
      },
    ),
    GoRoute(
      path: '/email-signup',
      builder: (context, state) {
        return const EmailSignupScreen();
      },
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        return const VerifyEmailScreen();
      },
    ),
  ],
);
