import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/models/editable_content.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/views/screens/auth_screen.dart';
import 'package:myapp/views/screens/main_screen.dart';
import 'package:myapp/views/screens/settings_screen.dart';
import 'package:myapp/views/screens/spaced_repetition_screen.dart';
import 'package:myapp/views/screens/summary_screen.dart';
import 'package:myapp/views/screens/quiz_screen.dart';
import 'package:myapp/views/screens/flashcards_screen.dart';
import 'package:myapp/views/screens/edit_content_screen.dart';
import 'package:myapp/views/screens/account_screen.dart';
import 'package:myapp/views/screens/preferences_screen.dart';
import 'package:myapp/views/screens/data_storage_screen.dart';
import 'package:myapp/views/screens/subscription_screen.dart';
import 'package:myapp/views/screens/privacy_about_screen.dart';
import 'package:myapp/views/screens/splash_screen.dart';
import 'package:myapp/views/screens/onboarding_screen.dart';
import 'package:myapp/views/screens/referral_screen.dart';
import 'package:myapp/views/screens/extraction_screen.dart';
import 'package:myapp/views/screens/results_screen.dart';

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
        path: '/subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'account',
            builder: (context, state) => const AccountScreen(),
          ),
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
      GoRoute(
        path: '/extraction',
        builder: (context, state) {
          final text = state.extra as String?;
          return ExtractionScreen(initialText: text);
        },
      ),
      GoRoute(
        path: '/results/:folderId',
        builder: (context, state) => ResultsScreen(
          folderId: state.pathParameters['folderId']!,
        ),
      ),
    ],
  );
}
