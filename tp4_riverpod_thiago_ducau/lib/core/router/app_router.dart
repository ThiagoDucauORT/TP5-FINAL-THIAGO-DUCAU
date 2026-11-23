import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../screens/detail_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';

// El router se crea de forma diferida: Firebase ya debe estar inicializado
// antes de acceder a FirebaseAuth.instance.
GoRouter? _router;

GoRouter get appRouter => _router ??= _createRouter();

GoRouter _createRouter() {
  final authRefresh = _AuthRefresh();

  return GoRouter(
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final signedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthPage =
          state.matchedLocation == '/' || state.matchedLocation == '/register';

      if (!signedIn && !isAuthPage) return '/';
      if (signedIn && isAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (context, state) =>
            DetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
