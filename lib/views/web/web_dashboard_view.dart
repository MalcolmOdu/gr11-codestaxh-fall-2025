import 'package:codestaxh/models/snippet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/snippet_notifier.dart';
import '../snippet_view.dart';
import 'snippet_editor_view.dart';
import '../shared/profile_view.dart';
import '../detailed_view.dart';

/// TODO
///   tag color generator- could make simple random color generator that creates colors
///     and maps them to new tags entered. Can be used to make tags in activity list more distinct.
///   abandon colors declared here, use dark theme
///   stats from wireframe pics
///   route to team view
///   repalce placeholder pfps with actual ones in activity list
///   make code snippet wrap around if too large for container

class WebDashboardView extends ConsumerWidget {
  const WebDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final snippets = ref.watch(snippetProvider);

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 20, horizontal: 40),
        child: Column(
          children: [
            _buildNavBar(context, user),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Welcome Section (top of screen)
                      Text(
                        // Forced username since must be signed in to access view.
                        'Welcome back, ${user!.displayName!.split(' ')[0]}!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w500,

                        ),
                      ),
                      const SizedBox(height: 32),

                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        // Searchbar input field
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search snippets by title, tags, language, or author...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          onSubmitted: (value) {
                              ref.read(snippetSearchProvider.notifier).state = value;
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SnippetListView()));
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // Cards for add snippet, browse library, and manage teams
                      Row(
                        children: [
                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.add,
                              color: Colors.blueAccent,
                              title: 'Add Snippet',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SnippetEditorView()));
                              },
                            ),
                          ),
                          const SizedBox(width: 60),

                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.folder_open,
                              color: Colors.green,
                              title: 'Browse Library',
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const SnippetListView()));
                              },
                            ),
                          ),
                          const SizedBox(width: 60),

                          Expanded(
                            child: _QuickActionCard(
                              icon: Icons.people_outline,
                              color: Colors.purpleAccent,
                              title: 'Manage Teams',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('not implemented yet')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Recent activity feed
                      const Text(
                        'Recent Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // Case- no snippets available
                      if (snippets.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Nothing to see here.")))
                      else
                        // NOTE should add button at bottom of listview "More" that loads in 10 more
                        // separated instead of builders, easily handles making diff cards distinct.
                        ListView.separated(
                          shrinkWrap: true,
                          //physics: const NeverScrollableScrollPhysics(),
                          itemCount: snippets.take(10).length, // Show 10 most recent
                          separatorBuilder: (context, index) => Divider(height: 1, color: const Color.fromARGB(255, 90, 90, 90)),
                          itemBuilder: (context, index) {
                            final snippet = snippets[index];
                            return _ActivityListItem(snippet: snippet, user: user);
                          },
                        ),
                      
                      // Bottom spacing
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  
  // Helper widget, creates nav bar and includes user profile icon and view profile button
  Widget _buildNavBar(BuildContext context, User? user) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.blue,
        border: Border(bottom: BorderSide(color: const Color.fromARGB(255, 90, 90, 90))),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            // App name
            const Text(
              'Codestaxh',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Profile button
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileView()));
              },
              child: Row(
                children: [
                  Text(
                    'My Profile',
                  ),
                  const SizedBox(width: 20),

                  // Profile icon (from profile_view.dart)
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
                        radius: 30,
                        backgroundColor: Color.fromARGB(255, 20, 0, 110),
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
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


/// Simple class for a custom widget used only in web dashboard to display quick actions.
/// Is a stateful widget to allow hovering animation (not yet implemented)
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,

        // Outer container, used for hover animation
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 120,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 195, 217, 255),
            borderRadius: BorderRadius.circular(16),
            // Updates on hover state change
            border: Border.all(
              color: _isHovered ? Colors.purple : Color.fromARGB(255, 195, 217, 255),
              width: 2
            ),
          ),

          // Text/icon contents
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Icon (translucent background)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),

              // Action title (e.g. create snippet, browse livrary)
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Custom widget that used only here for displaying recent activity in feed.
class _ActivityListItem extends StatelessWidget {
  
  final Snippet snippet; // Using dynamic to access snippet properties easily
  final User? user;

  const _ActivityListItem({required this.snippet, required this.user});

  @override
  Widget build(BuildContext context) {

    // Used to display "You" if activity is from user
    final bool isCurrentUser = snippet.author == user?.displayName || snippet.author == user?.email;
    final String authorName = isCurrentUser ? "You" : snippet.author;

    return InkWell(
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (_) => DetailedView(id: snippet.id)));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TEMP displays simple pfp placeholder, to be replaced with actual pfps.
            // Simple color circle with first char of poster's name
            CircleAvatar(
              radius: 18,
              backgroundColor: _getColorForName(snippet.author),
              child: Text(
                snippet.author.isNotEmpty ? snippet.author[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 16),
            
            // Activity content (poster, tags, title, code)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Displays username and tags at the top of the widget.
                  // RichText instead of Row since using only text.
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14),
                      children: [
                        // Author
                        TextSpan(
                          text: authorName, 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        // Spacing
                        TextSpan(
                          text: '  ', 
                          style: const TextStyle(color: Colors.grey)
                        ),

                         // Tags (if applicable)
                        if (snippet.tags.isNotEmpty)
                          WidgetSpan(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 141, 141, 141),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black45, width: 2)
                              ),
                              child: Text(
                                snippet.tags.first,
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 31, 31, 31),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Snippet Title
                  Text(
                    snippet.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Code snippet
                  Text(
                    snippet.code.replaceAll('\n', ' '),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TEMP just generates colors for pfps in activity screen. to be replaced with actual pfps
  Color _getColorForName(String text) {
    if (text.isEmpty) return Colors.blue;
    final int hash = text.codeUnits.fold(0, (prev, curr) => prev + curr);
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
    ];
    return colors[hash % colors.length];
  }
}