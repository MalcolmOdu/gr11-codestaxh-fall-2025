import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/web/snippet_editor_view.dart';
import 'views/web/team_management_view.dart';
import 'views/web/web_dashboard_view.dart';
import 'views/snippet_view.dart';
import 'views/detailed_view.dart';
import 'views/auth/login_view.dart';
import 'views/shared/profile_view.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthNotifier extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _subscription;

  AuthNotifier() {
    _subscription = _auth.authStateChanges().listen((user) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
    }
}
final authNotifier = AuthNotifier();

final appRouter = GoRouter(
  initialLocation: '/',

  refreshListenable: authNotifier,
  //Redirect
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoginRoute = state.matchedLocation == '/login';
    final isWeb = kIsWeb;
    final homeRoute = isWeb ? '/dashboard' : '/snippets';

    if (user == null && !isLoginRoute) {
      return '/login';
    } else if (user != null && isLoginRoute) {
      return homeRoute;
    }

    if (!isWeb && state.matchedLocation == '/dashboard') {
      return '/snippets';
    }

    // if (isWeb && state.matchedLocation == '/snippets') {
    //   return '/dashboard';
    // }

    if (state.matchedLocation == '/'){
      return user != null ? homeRoute : '/login';
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginView(),
    ),

    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const WebDashboardView(),
    ),

    GoRoute(
      path: '/snippets',
      name: 'snippets',
      builder: (context, state) => const SnippetListView(),
    ),

    GoRoute(
      path: '/editor',
      name: 'editor',
      builder: (context, state) => const SnippetEditorView(),
    ),

    GoRoute(
      path: '/editor/:id',
      name: 'editor-edit',
      builder: (context, state) => SnippetEditorView(id: state.pathParameters['id']),
    ),

    GoRoute(
      path: '/snippet/:id',
      name: 'snippet-detail',
      builder: (context, state) => DetailedView(id: state.pathParameters['id']),
    ),

    GoRoute(
      path: '/teams',
      name: 'teams',
      builder: (context, state) => const TeamManagementView(),
    ),

    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileView(),
    ),
  ],

  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            '404 - Page Not Found',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Route: ${state.matchedLocation}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.home),
            label: const Text('Go to Dashboard'),
          ),
        ],
      )
    )
  )
);

extension NavigationHelpers on BuildContext {
  void goToDashboard() => go('/dashboard');
  void goToSnippets() => go('/snippets');
  void pushEditor({String? id}) {
    if (id == null) {
      push('/editor');
    } else {
      push('/editor/$id');
    }
  }
  void pushSnippetDetail(String id) => push('/snippet/$id');
  void pushTeams() => push('/teams');
  void pushProfile() => push('/profile');

  void signOutAndGoToLogin() => go('/login');
}