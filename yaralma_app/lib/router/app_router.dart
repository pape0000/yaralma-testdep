import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/onboarding/faith_shield_screen.dart';
import '../screens/onboarding/value_agreement_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/holy_lock/holy_lock_screen.dart';

/// Route names and paths.
class AppRoutes {
  static const String valueAgreement = 'value-agreement';
  static const String faithShield = 'faith-shield';
  static const String home = 'home';
  static const String holyLock = 'holy-lock';

  static const String pathValueAgreement = '/onboarding/value-agreement';
  static const String pathFaithShield = '/onboarding/faith-shield';
  static const String pathHome = '/home';
  static const String pathHolyLock = '/holy-lock';
}

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: AppRoutes.pathValueAgreement,
    routes: [
      GoRoute(
        path: '/onboarding/:screen',
        builder: (context, state) {
          final screen = state.pathParameters['screen'];
          if (screen == AppRoutes.faithShield) {
            return const FaithShieldScreen();
          }
          return const ValueAgreementScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.pathHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.pathHolyLock,
        builder: (context, state) => const HolyLockScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    ),
  );
}
