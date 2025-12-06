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
import 'views/search_view.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'views/notifications_view.dart';
import 'views/welcome_screen.dart';

/// This class is responsible for all navigation within the app. It incorporates
/// firebase_auth to ensure views accessible only by members can only be accessed 
/// by members.
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
  initialLocation: '/welcome',

  refreshListenable: authNotifier,
  //Redirects
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoginRoute = state.matchedLocation == '/login';
    final isWeb = kIsWeb;
    final homeRoute = isWeb ? '/dashboard' : '/snippets';

    // If user not signed in and route leads beyond signin screens, redirect to singin.
    if (user == null && !isLoginRoute) {
      return '/login';
    } else if (user != null && isLoginRoute) {
      return homeRoute;
    }

    // If user is not using webapp and routes to webapp dashboard, route to snippets view.
    if (!isWeb && state.matchedLocation == '/dashboard') {
      return '/snippets';
    }

    // Don't reroute if root directory or welcome screen.
    if (state.matchedLocation == '/' || state.matchedLocation == '/welcome'){
      return null;
    }

    return null;
  },

  // All routes
  routes: [
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),

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
    //created new route for search view
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SnippetSearchView(),
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

    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsView(),
    ),
  ],

  // Simple error builder in case page not found.
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
            // Dashboard for non-webapp users handled implicitly by rerouting.
            onPressed: () => context.go('/dashboard'),
            icon: const Icon(Icons.home),
            label: const Text('Go to Dashboard'),
          ),
        ],
      )
    )
  )
);

// Collection of public methods to simplify routing implementation in other files.
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
  void pushSearch() => push('/search');

  void signOutAndGoToLogin() => go('/login');
}