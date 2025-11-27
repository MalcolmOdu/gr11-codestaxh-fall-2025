
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/snippet_controller.dart';
import '../controllers/snippet_notifier.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github.dart';
import 'package:codestaxh/views/detailed_view.dart';


class SnippetListView extends ConsumerWidget {
  const SnippetListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = SnippetController(ref);
    final filteredSnippets = ref.watch(filteredSnippetsProvider);
     

    

    return Scaffold(
      appBar: AppBar(
        title: const Text("Snippets"),
        toolbarHeight: 140,
        backgroundColor: Colors.lightBlue,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // SEARCH BAR
                SizedBox(
                  width: double.infinity,
                  
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: "Search snippets...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value){
                      ref.read(snippetSearchProvider.notifier).state = value;
                    }
                  ),
                ),

          const SizedBox(height: 12),

          // TAG FILTER, add filter implementation here 
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final lang in ["Python", "Java", "Dart", "C++"])
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

        ],
      ),
    ),
  ),
),

     
      body: Center(
        child: Column(
          children: [

            const SizedBox(height: 12),

            // ---------------- SNIPPETS LIST ----------------
            Expanded(
              child: filteredSnippets.isEmpty
                  ? const Center(
                      child: Text(
                        'No snippets yet. Create one on the web app.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredSnippets.length,
                      itemBuilder: (context, i) {
                        final s = filteredSnippets[i];

                        // 3-line code preview
                        final preview =
                            s.code.split('\n').take(3).join('\n');

                        return InkWell(
                          onTap: ()=> Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailedView(id: s.id),
                            ),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  // TITLE
                                  Text(
                                    s.title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 6),

                                  // LANGUAGE BADGE
                                  Chip(
                                    label: Text(s.language),
                                    backgroundColor:
                                        Colors.blue.shade100,
                                  ),

                                  const SizedBox(height: 6),

                                  // TAGS (first 2)
                                  Wrap(
                                    spacing: 6,
                                    children: s.tags.take(2).map((t) {
                                      return Chip(
                                        label: Text(t),
                                        backgroundColor:
                                            Colors.green,
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 10),

                                  // ---------------- CODE PREVIEW ----------------
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: HighlightView(
                                      preview,
                                      language: s.language.toLowerCase(),
                                      theme: githubTheme,
                                      padding: const EdgeInsets.all(12),
                                      textStyle:
                                          const TextStyle(fontSize: 12),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // FOOTER
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                controller.upvoteSnippet(
                                                    s.id),
                                            icon: const Icon(Icons
                                                .arrow_upward),
                                          ),
                                          Text(s.upvote.toString()),
                                        ],
                                      ),
                                      Text(
                                        s.author,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
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
            ),
          ],
        ),
      ),

      // TEMP floating button for testing
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.addSnippet(
            title: 'New Snippet',
            code: 'print("test, World!")',
            language: 'java',
            tags: ["Python", "Java"],
            author: 'User',
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
