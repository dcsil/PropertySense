import 'package:go_router/go_router.dart';
import 'package:object_detect_test/ui/views/create_listing_screen.dart';
import 'package:object_detect_test/ui/views/email_signup_screen.dart';
import 'package:object_detect_test/ui/views/listing_detail_contractor_screen.dart';
import 'package:object_detect_test/ui/views/listing_detail_screen.dart';
import 'package:object_detect_test/ui/views/listing_map_screen.dart';
import 'package:object_detect_test/ui/views/listing_swipe_screen.dart';
import 'package:object_detect_test/ui/views/listings_screen.dart';
import 'package:object_detect_test/ui/views/login_screen.dart';
import 'package:object_detect_test/ui/views/offers_homeowner_screen.dart';
import 'package:object_detect_test/ui/views/offers_overview_screen.dart';
import 'package:object_detect_test/ui/views/profile_contractor_screen.dart';
import 'package:object_detect_test/ui/views/profile_homeowner_screen.dart';
import 'package:object_detect_test/ui/views/registration_screen.dart';
import 'package:object_detect_test/ui/views/scaffold_nav_bar.dart';
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
      path: '/listings-swipe',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 0,
            child: const ListingSwipeScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/listings',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 0,
            child: const ListingOverviewScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/listing-contractor/:id',
      pageBuilder: (context, state) {
        final listingId = state.pathParameters['id']!;
        final showOffer = state.uri.queryParameters['offer'] == 'true';
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 0,
            child: ListingDetailContractorScreen(
              listingId: listingId,
              showOfferDialog: showOffer,
            ),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/listing/:id',
      pageBuilder: (context, state) {
        final listingId = state.pathParameters['id']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 0,
            child: ListingDetailScreen(listingId: listingId),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/create-listing',
      builder: (context, state) {
        return const CreateListingScreen();
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
    GoRoute(
      path: '/listings-map',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 1,
            child: const ListingMapScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/profile-homeowner',
      builder: (context, state) {
        return const ProfileHomeownerScreen();
      },
    ),
    GoRoute(
      path: '/profile-contractor',
      builder: (context, state) {
        return const ProfileContractorScreen();
      },
    ),
    GoRoute(
      path: '/inbox-contractor',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 2,
            child: const OffersOverviewScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
    GoRoute(
      path: '/inbox-homeowner',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(
            currentIndex: 2,
            child: const OffersHomeownerScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child;
          },
        );
      },
    ),
  ],
);
