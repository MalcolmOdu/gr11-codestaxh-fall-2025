import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/snippet_controller.dart';
import '../controllers/snippet_notifier.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github.dart';
import '../widgets/notification_bell.dart';
import 'package:codestaxh/app_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


class SnippetListView extends ConsumerStatefulWidget {
  const SnippetListView({super.key});

  @override
  ConsumerState<SnippetListView> createState() => _SnippetListViewState();
}

class _SnippetListViewState extends ConsumerState<SnippetListView>{
  late TextEditingController _searchController;

  @override
  void initState(){
    // Override constructor to allow searches from web dashboard to
    // autofill here
    super.initState();
    final initialSearch = ref.read(snippetSearchProvider);
    _searchController = TextEditingController(text: initialSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final controller = SnippetController(ref);
    final filteredSnippets = ref.watch(filteredSnippetsProvider);
    final filterType = ref.watch(snippetFilterProvider);
    final commonTags = ref.watch(sortedTagsProvider);

    //Global color scheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stashed Snippets!"),
        toolbarHeight: 200,
        automaticallyImplyLeading: !kIsWeb,
        actions: [
          // home button for web only
          if (kIsWeb)
            IconButton(
              tooltip: 'Dashboard',
              icon: const Icon(Icons.dashboard),
              onPressed: () => context.goToDashboard(),
            ),
          const NotificationBell(),
          const SizedBox(width: 8,),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              context.pushProfile();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // SEARCH BAR
                Row(
                  children: [
                  Expanded(
                  child:
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search snippets...",
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      // clear button
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(snippetSearchProvider.notifier).state ='';
                            setState((){});
                          }
                        )
                        : null,
                    ),
                    onChanged: (value){
                      ref.read(snippetSearchProvider.notifier).state = value;
                      setState(() {});
                    },
                  ),
                  ),
                  IconButton(
                    onPressed: () {
                      //resets filters when going to advanced search
                        ref.invalidate(snippetFilterProvider);
                        ref.invalidate(snippetTagFilterProvider);
                        context.pushSearch();},
                    icon: Icon(Icons.tune)
                    )
                  ]
                ),

          const SizedBox(height: 12),

          // TAG FILTER, add filter implementation here
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
              for (final lang in commonTags)
                Consumer(
                  builder: (context, ref, _) {
                    final selected = ref.watch(snippetTagFilterProvider).contains(lang);

                    return ChoiceChip(
                      label: Text(lang),
                      selected: selected,
                      selectedColor: Colors.blue.shade200,
                      onSelected: (_) {
                        final tags = ref.read(snippetTagFilterProvider.notifier).state;
                        print(tags);
                        final newSet = Set<String>.from(tags);

                        if (selected) {
                          newSet.remove(lang);
                        } else {
                          newSet.add(lang);
                        }

                        ref.read(snippetTagFilterProvider.notifier).state = newSet;
                      },
                    );
                  },
                ),
                  ],
                ),
              ),

                const SizedBox(height: 12),

                // TEAM FILTER
                Row(
                  children: [
                    Expanded(
                      child: _FilterChip(
                        label: 'All',
                        icon: Icons.apps,
                        isSelected: filterType == SnippetFilterType.all,
                        onSelected: () {
                          ref.read(snippetFilterProvider.notifier).state =
                              SnippetFilterType.all;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Personal',
                        icon: Icons.person,
                        isSelected: filterType == SnippetFilterType.personal,
                        onSelected: () {
                          ref.read(snippetFilterProvider.notifier).state =
                              SnippetFilterType.personal;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterChip(
                        label: 'Team',
                        icon: Icons.groups,
                        isSelected: filterType == SnippetFilterType.team,
                        onSelected: () {
                          ref.read(snippetFilterProvider.notifier).state =
                              SnippetFilterType.team;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

              ],
            ),
              ]
          ),
        ),
      ),
      ),

     //Change this code to stream builder
     // .orderBy sortKey => make sort button change this

      body: filteredSnippets.isEmpty
          ? _buildEmptyState(context, filterType)
          : ListView.builder(
        padding: const EdgeInsets.only(top: 12),
        itemCount: filteredSnippets.length,
        itemBuilder: (context, i) {
          final s = filteredSnippets[i];
          final preview = s.code.split('\n').take(3).join('\n');
          final user = FirebaseAuth.instance.currentUser;
          final isUpvoted = user != null && s.upvotedBy.contains(user.uid);

          return InkWell(
            onTap: () => context.pushSnippetDetail(s.id),
            child: Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE with team badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Team badge
                        if (s.teamId != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme
                                  .secondary
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups,
                                  size: 14,
                                  color: colorScheme
                                      .secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Team',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme
                                        .secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // LANGUAGE BADGE
                    Chip(
                      label: Text(s.language),
                      backgroundColor: colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),

                    const SizedBox(height: 6),

                    // TAGS (first 2)
                    if (s.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        children: s.tags.take(2).map((t) {
                          return Chip(
                            label: Text(t),
                            backgroundColor: colorScheme
                                .secondary
                                .withValues(alpha: 0.2),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 10),

                    // CODE PREVIEW
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: HighlightView(
                        preview,
                        language: s.language.toLowerCase(),
                        theme: githubTheme,
                        padding: const EdgeInsets.all(12),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // FOOTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => controller.upvoteSnippet(s.id),
                              icon: Icon(
                                isUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                                color: isUpvoted ? colorScheme.primary : null,
                              ),
                            ),
                            Text(
                              s.upvote.toString(),
                              style: TextStyle(
                                fontWeight: isUpvoted ? FontWeight.bold : FontWeight.normal,
                                color: isUpvoted ? colorScheme.primary : null,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          s.author,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, SnippetFilterType filterType) {
    String title;
    String message;

    switch (filterType) {
      case SnippetFilterType.all:
        title = 'No snippets found';
        message = 'Try adjusting your search or filters';
        break;
      case SnippetFilterType.personal:
        title = 'No personal snippets';
        message = 'Create your first personal snippet';
        break;
      case SnippetFilterType.team:
        title = 'No team snippets';
        message = 'Share a snippet with your team to see it here';
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}