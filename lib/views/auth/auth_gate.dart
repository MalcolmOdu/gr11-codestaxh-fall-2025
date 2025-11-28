import 'package:codestaxh/views/web/web_dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/loading_widgets.dart';
import 'login_view.dart';
import '../../views/web/snippet_editor_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:codestaxh/views/snippet_view.dart';


// Allows detect platform, used to determine which screen to use (web vs mobile)
import 'package:flutter/foundation.dart';

// this widget shows login screen or main app based on auth state
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () =>
          Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme
                        .of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme
                        .of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Theme
                                .of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'codestaxh-icon.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Theme
                                    .of(context)
                                    .colorScheme
                                    .primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '</>',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Theme
                                        .of(context)
                                        .colorScheme
                                        .onPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Loading indicator
                    const PulsingDots(),

                    const SizedBox(height: 16),

                    Text(
                      'Loading CodeStaxh...',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                        color: Theme
                            .of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

      // Error state with retry
      error: (error, stack) =>
          Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme
                        .of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.1),
                    Theme
                        .of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme
                            .of(context)
                            .colorScheme
                            .error,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Oops! Something went wrong',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to connect to authentication service',
                        style: Theme
                            .of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                          color: Theme
                              .of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.invalidate(authStateProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

      // Success state - show login or main app
      data: (user) {
        if (user == null) {
          return const LoginView();
        }

        if (kIsWeb) {
          return const SnippetEditorView();
        }
        else {
          return const SnippetListView();
        }
      },
    );
  }
}