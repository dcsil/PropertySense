import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:object_detect_test/ui/views/contractor_home_screen.dart';
import 'package:object_detect_test/ui/views/create_listing_screen.dart';
import 'package:object_detect_test/ui/views/email_signup_screen.dart';
import 'package:object_detect_test/ui/views/listing_detail_contractor_screen.dart';
import 'package:object_detect_test/ui/views/listing_detail_screen.dart';
import 'package:object_detect_test/ui/views/listing_swipe_screen.dart';
import 'package:object_detect_test/ui/views/listings_screen.dart';
import 'package:object_detect_test/ui/views/login_screen.dart';
import 'package:object_detect_test/ui/views/registration_screen.dart';
import 'package:object_detect_test/ui/views/verify_email_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/camera',
      builder: (context, state) {
        return const CameraScreen();
      },
    ),
    GoRoute(
      path: '/listings',
      builder: (context, state) {
        return const ListingOverviewScreen();
      },
    ),
    GoRoute(
      path: '/listing-contractor/:id',
      pageBuilder: (context, state) {
        final listingId = state.pathParameters['id']!;
        final showOffer = state.uri.queryParameters['offer'] == 'true';
        return CustomTransitionPage(
          key: state.pageKey,
          child: ListingDetailContractorScreen(listingId: listingId, showOfferDialog: showOffer),
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
          child: ListingDetailScreen(listingId: listingId),
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
      path: '/contractor',
      builder: (context, state) {
        return const ListingSwipeScreen();
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