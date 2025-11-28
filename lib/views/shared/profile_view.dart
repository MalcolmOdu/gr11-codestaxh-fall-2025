import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme_provider.dart';
import '../../controllers/snippet_notifier.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/notification_bell.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final snippets = ref.watch(snippetProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Count user's snippets
    final userSnippets = snippets.where(
          (s) => s.author == user?.displayName || s.author == user?.email,
    ).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // Notifications
            actions: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: NotificationBell()
              )
            ],

            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar with Glow
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: user?.photoURL != null
                                ? NetworkImage(user!.photoURL!)
                                : null,
                            child: user?.photoURL == null
                                ? Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //Stats Card
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Email
                          Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  user?.email ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Provider Badge
                          _buildProviderBadge(context, user),

                          const Divider(height: 32),

                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStat(
                                context,
                                userSnippets.length.toString(),
                                'Snippets',
                                Icons.code,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              _buildStat(
                                context,
                                userSnippets.fold<int>(
                                  0,
                                      (sum, s) => sum + s.upvote,
                                ).toString(),
                                'Total Upvotes',
                                Icons.arrow_upward,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Settings Section
                  _buildSectionHeader(context, 'Appearance'),
                  const SizedBox(height: 12),

                  GlassCard(
                    child: Column(
                      children: [
                        // Theme Toggle
                        ListTile(
                          leading: Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                          title: const Text('Dark Mode'),
                          subtitle: const Text('Toggle between light and dark theme'),
                          trailing: Switch(
                            value: themeMode == ThemeMode.dark,
                            onChanged: (value) {
                              ref.read(themeModeProvider.notifier).toggleTheme();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Account Section
                  _buildSectionHeader(context, 'Account'),
                  const SizedBox(height: 12),

                  GlassCard(
                    child: Column(
                      children: [
                        // Sign Out
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () => _showSignOutDialog(context, ref),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Version Info
                  Center(
                    child: Text(
                      'CodeStaxh v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildProviderBadge(BuildContext context, User? user) {
    final providerId = user?.providerData.first.providerId;

    IconData icon;
    String label;

    switch (providerId) {
      case 'google.com':
        icon = Icons.login;
        label = 'Google Account';
        break;
      case 'github.com':
        icon = Icons.code;
        label = 'GitHub Account';
        break;
      case 'password':
        icon = Icons.email;
        label = 'Email Account';
        break;
      default:
        icon = Icons.person;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}