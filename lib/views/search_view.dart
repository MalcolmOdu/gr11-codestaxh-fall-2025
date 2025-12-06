import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/snippet_controller.dart';
import '../controllers/snippet_notifier.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github.dart';
import '../widgets/notification_bell.dart';
import 'package:codestaxh/app_router.dart';
import 'package:go_router/go_router.dart';



final languages = <String>[
  'Python', 'Java', 'Dart', 'C++', 'JavaScript', 'C#', 'C', 'PHP', 'HTML', 
  'CSS', 'TypeScript', 'Swift', 'Objective-C', 'SQL', 'R', 'Ruby', 'Go', 'Kotlin',
];

/// This class acts as a snippet list viewer, similar to snippet_view.dart, 
/// with advanced filtering options.
class SnippetSearchView extends ConsumerStatefulWidget {
  const SnippetSearchView({super.key});
  
  @override
  ConsumerState<SnippetSearchView> createState() => _SnippetSearchViewState();
}

class _SnippetSearchViewState extends ConsumerState<SnippetSearchView> {
  final searchBarController = TextEditingController();
  final authorController = TextEditingController();
  String? _selectedLanguage;
  
  final GlobalKey _filterExpansionKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = SnippetController(ref);
    final filteredSnippets = ref.watch(filteredSnippetsProvider);
    final filterType = ref.watch(snippetFilterProvider);
    
    // fetching all tags, determining most frequent for hot buttons. 
    final allSnippetsAsync = ref.watch(snippetProvider);
    final allSnippets = allSnippetsAsync.value ?? [];
    final Set<String> uniqueTags = {};
    for (var s in allSnippets) {
      uniqueTags.addAll(s.tags);
    }
    final List<String> allTagsList = uniqueTags.toList()..sort();
    final Map<String, int> tagCounts = {};
    for (var s in allSnippets) {
      for (var t in s.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    // Determining most freq tags to display
    final commonTags = tagCounts.keys.toList()
      ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));
    final topTags = commonTags.take(6).toList();

    // fetch global color theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(

      // app bar with profile button, notification bell, and back button to exit advanced search
      appBar: AppBar(
        title: const Text("Search Snippets"),
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            _resetAllFilters();
            context.pop();
          },
        ),
        actions: [
          const NotificationBell(),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              context.pushProfile();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [

          // Search bar, searches all text-based content of snipepts.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchBarController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search snippets...",
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                    onSubmitted: (value) {
                      ref.read(snippetSearchProvider.notifier).state = value;
                    },
                  ),
                ),
                // Clear text search
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Search',
                  onPressed: () {
                    ref.read(snippetSearchProvider.notifier).state = '';
                    searchBarController.clear();
                  },
                ),
              ],
            ),
          ),

          // Advanced filters, inside a dropdown menu, think of it like nested dropwdon menus.
          ExpansionTile(
            key: _filterExpansionKey,
            title: const Text("Advanced Filters", style: TextStyle(fontWeight: FontWeight.bold)),
            leading: const Icon(Icons.tune),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              
              // All/personal/team filtering
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("View", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('All'),
                      avatar: const Icon(Icons.apps, size: 16),
                      selected: filterType == SnippetFilterType.all,
                      onSelected: (_) => ref.read(snippetFilterProvider.notifier).state = SnippetFilterType.all,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Personal'),
                      avatar: const Icon(Icons.person, size: 16),
                      selected: filterType == SnippetFilterType.personal,
                      onSelected: (_) => ref.read(snippetFilterProvider.notifier).state = SnippetFilterType.personal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Team'),
                      avatar: const Icon(Icons.groups, size: 16),
                      selected: filterType == SnippetFilterType.team,
                      onSelected: (_) => ref.read(snippetFilterProvider.notifier).state = SnippetFilterType.team,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Language filter dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Language",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                value: _selectedLanguage,
                items: languages.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(lang),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedLanguage = value);
                },
              ),
              const SizedBox(height: 16),
              
              // Author search bar
              TextField(
                controller: authorController,
                decoration: InputDecoration(
                  labelText: "Author",
                  hintText: "Filter by author name...",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      ref.read(snippetAuthorFilterProvider.notifier).state = {};
                      authorController.clear();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tag filtering. Shows 6 most frequently used tags (from firebase).
              // Has a button that shows all tags in database.
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Tags", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // scrollable, 6 tags wont fit horizontally
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.list, size: 16),
                        label: const Text("All Tags"),
                        onPressed: () => _showAllTagsDialog(allTagsList),
                      ),
                      const SizedBox(width: 8),
                      // most common tags
                      ...topTags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Consumer(
                            builder: (context, ref, _) {
                              final selected = ref.watch(snippetTagFilterProvider).contains(tag);
                              return ChoiceChip(
                                label: Text(tag),
                                selected: selected,
                                selectedColor: colorScheme.primaryContainer,
                                onSelected: (_) {
                                  final tags = ref.read(snippetTagFilterProvider);
                                  final newSet = Set<String>.from(tags);
                                  if (selected) {
                                    newSet.remove(tag);
                                  } else {
                                    newSet.add(tag);
                                  }
                                  ref.read(snippetTagFilterProvider.notifier).state = newSet;
                                },
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sort-by buttons (recent, upvotes)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Sort By", style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SortButton(label: "Recent", type: SnippetSortType.recent),
                  const SizedBox(width: 8),
                  _SortButton(label: "Upvotes", type: SnippetSortType.upvote),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(snippetSortProvider.notifier).state = SnippetSortType.none;
                    }, 
                    child: const Text("Reset Sort")
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Clear all filters button, allows clearing without having to return to previous view.
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Clear All Filters"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red, 
                  ),
                  onPressed: _resetAllFilters,
                ),
              ),
              const SizedBox(height: 8),

              // Apply filters button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text("Apply Filters"),
                  onPressed: () {
                    ref.read(snippetSearchProvider.notifier).state = searchBarController.text;
                    if (authorController.text.isNotEmpty) {
                      ref.read(snippetAuthorFilterProvider.notifier).state = {authorController.text};
                    } else {
                      ref.read(snippetAuthorFilterProvider.notifier).state = {};
                    }
                    if (_selectedLanguage != null) {
                      ref.read(snippetLanguageFilterProvider.notifier).state = {_selectedLanguage!};
                    } else {
                      ref.read(snippetLanguageFilterProvider.notifier).state = {};
                    }
                    FocusScope.of(context).unfocus(); 
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
          const Divider(height: 1),

          // Listview displaying either results or test message if no results found.
          Expanded(
            child: filteredSnippets.isEmpty
              ? _buildEmptyState(context, filterType)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredSnippets.length,
                  itemBuilder: (context, i) {
                    final s = filteredSnippets[i];
                    final preview = s.code.split('\n').take(3).join('\n');
                    final user = ref.watch(authStateProvider).value;
                    final isUpvoted = user != null && s.upvotedBy.contains(user.uid);

                    return InkWell(
                      onTap: () => context.pushSnippetDetail(s.id),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      s.title,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  if (s.teamId != null)
                                    Chip(
                                      label: const Text("Team", style: TextStyle(fontSize: 10)),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      backgroundColor: colorScheme.secondaryContainer,
                                    )
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: HighlightView(
                                  preview,
                                  language: s.language.toLowerCase(),
                                  theme: githubTheme,
                                  padding: const EdgeInsets.all(12),
                                  textStyle: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text("By ${s.author}", style: TextStyle(color: Colors.grey.shade600)),
                                  const Spacer(),
                                  IconButton(
                                    icon: Icon(
                                      isUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                                      color: isUpvoted ? colorScheme.primary : null,
                                    ),
                                    onPressed: () => controller.upvoteSnippet(s.id),
                                  ),
                                  Text(s.upvote.toString()),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  // Helper method to clear filters
  void _resetAllFilters() {
    ref.invalidate(snippetFilterProvider);
    ref.invalidate(snippetTagFilterProvider);
    ref.invalidate(snippetSearchProvider);
    ref.invalidate(snippetLanguageFilterProvider);
    ref.invalidate(snippetAuthorFilterProvider);
    ref.invalidate(snippetSortProvider);
    
    // Clear text fields and selected language
    searchBarController.clear();
    authorController.clear();
    setState(() {
      _selectedLanguage = null;
    });
  }

  // Creates popup dialog to show all tags from database
  void _showAllTagsDialog(List<String> allTags) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter by Tags"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTags.map((tag) {
                  return Consumer(
                    builder: (context, ref, _) {
                       final selectedTags = ref.watch(snippetTagFilterProvider);
                       final isSelected = selectedTags.contains(tag);
                       return FilterChip(
                         label: Text(tag),
                         selected: isSelected,
                         onSelected: (selected) {
                           final newSet = Set<String>.from(selectedTags);
                           if (selected) {
                             newSet.add(tag);
                           } else {
                             newSet.remove(tag);
                           }
                           ref.read(snippetTagFilterProvider.notifier).state = newSet;
                         },
                       );
                    }
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Done"),
            )
          ],
        );
      },
    );
  }

  // Custom widget to display a message when no snippets are found with filters
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
    // layout builder prevents overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight, 
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.code_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
            ),
          ),
        );
      },
    );
  }
}

class _SortButton extends ConsumerWidget {
  final String label;
  final SnippetSortType type;

  const _SortButton({required this.label, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(snippetSortProvider);
    final isSelected = currentSort == type;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(snippetSortProvider.notifier).state = type;
      },
    );
  }
}