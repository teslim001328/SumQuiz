import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sumquiz/models/editable_content.dart';
import 'package:sumquiz/services/auth_service.dart';
import 'package:sumquiz/views/screens/auth_screen.dart';
import 'package:sumquiz/views/screens/main_screen.dart';
import 'package:sumquiz/views/screens/settings_screen.dart';
import 'package:sumquiz/views/screens/spaced_repetition_screen.dart';
import 'package:sumquiz/views/screens/summary_screen.dart';
import 'package:sumquiz/views/screens/quiz_screen.dart';
import 'package:sumquiz/views/screens/flashcards_screen.dart';
import 'package:sumquiz/views/screens/edit_content_screen.dart';
import 'package:sumquiz/views/screens/preferences_screen.dart';
import 'package:sumquiz/views/screens/data_storage_screen.dart';
import 'package:sumquiz/views/screens/subscription_screen.dart';
import 'package:sumquiz/views/screens/privacy_about_screen.dart';
import 'package:sumquiz/views/screens/splash_screen.dart';
import 'package:sumquiz/views/screens/onboarding_screen.dart';
import 'package:sumquiz/views/screens/referral_screen.dart';
import 'package:sumquiz/views/screens/account_profile_screen.dart';
import 'package:sumquiz/views/screens/create_content_screen.dart';
import 'package:sumquiz/views/screens/extraction_view_screen.dart';
import 'package:sumquiz/views/screens/results_view_screen.dart';

// GoRouterRefreshStream class
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/splash', // Set initial location to splash
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges),
    redirect: (context, state) {
      final user = authService.currentUser;
      final loggingIn = state.matchedLocation == '/auth';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Allow onboarding screen to be shown
      if (isOnboarding) {
        return null;
      }

      // If on splash, don't redirect yet. The splash screen will handle it.
      if (isSplash) {
        return null;
      }

      if (user == null) {
        // If not logged in and not on auth screen, redirect to auth
        return loggingIn ? null : '/auth';
      }

      // If logged in and on auth screen, redirect to home
      if (loggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/account-profile',
        builder: (context, state) => const AccountProfileScreen(),
      ),
      GoRoute(
        path: '/create-content',
        builder: (context, state) => const CreateContentScreen(),
      ),
      GoRoute(
        path: '/extraction-view',
        builder: (context, state) =>
            ExtractionViewScreen(initialText: state.extra as String?),
      ),
      GoRoute(
        path: '/results-view/:folderId',
        builder: (context, state) =>
            ResultsViewScreen(folderId: state.pathParameters['folderId']!),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'preferences',
            builder: (context, state) => const PreferencesScreen(),
          ),
          GoRoute(
            path: 'data-storage',
            builder: (context, state) => const DataStorageScreen(),
          ),
          GoRoute(
            path: 'privacy-about',
            builder: (context, state) => const PrivacyAboutScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/spaced-repetition',
        builder: (context, state) => const SpacedRepetitionScreen(),
      ),
      GoRoute(
        path: '/summary',
        builder: (context, state) => const SummaryScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/flashcards',
        builder: (context, state) => const FlashcardsScreen(),
      ),
      GoRoute(
        path: '/edit-content',
        builder: (context, state) {
          if (state.extra is EditableContent) {
            return EditContentScreen(content: state.extra as EditableContent);
          } else {
            // Handle the case where the extra data is not of the expected type
            // For example, navigate to an error screen or back to the previous screen
            return const Scaffold(
              body: Center(
                child: Text('Error: Invalid content data'),
              ),
            );
          }
        },
      ),
    ],
  );
}
