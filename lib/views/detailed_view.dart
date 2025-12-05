import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/snippet_controller.dart';
import 'package:codestaxh/controllers/snippet_notifier.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github-dark.dart';
import 'package:flutter/services.dart';
import '../widgets/notification_bell.dart';
import 'package:codestaxh/ai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailedView extends ConsumerStatefulWidget {
  final String? id;
  const DetailedView({super.key, this.id});
  @override
  ConsumerState<DetailedView> createState() => _DetailedViewState();
}

class _DetailedViewState extends ConsumerState<DetailedView> {
  bool _isExplaining = false;
  String? _aiExplanation;

  @override
  Widget build(BuildContext context) {
    final snippetsAsync = ref.watch(snippetProvider);
    final snippets = snippetsAsync.value ?? [];

    final snippetIndex = snippets.indexWhere((s) => s.id == widget.id);
    if (snippetIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text("Snippet Not Found")),
        body: const Center(
          child: Text("The requested snippet could not be found."),
        ),
      );
    }
    final snippet = snippets[snippetIndex];
    final controller = SnippetController(ref);

    final user = FirebaseAuth.instance.currentUser;
    final isUpvoted = user != null && snippet.upvotedBy.contains(user.uid);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
        appBar: AppBar(
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 36),
              child: NotificationBell(),
            )
          ],
          toolbarHeight: 80,
          title: const Text("Code Snippet"),
        ),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snippet.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Chip(
                          label: Text(snippet.language),
                        ),
                        const SizedBox(height: 6),
                        Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondary,
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                          ),
                                          child: Row(children: [
                                            Text(
                                              "Code",
                                              style: TextStyle(
                                                color: colorScheme.onSecondary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                                icon: Icon(Icons.copy,
                                                    color: colorScheme.onSecondary,
                                                    size: 20),
                                                onPressed: () {
                                                  Clipboard.setData(
                                                      ClipboardData(text: snippet.code));
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(content: Text(
                                                        "Code copied to clipboard!")),
                                                  );
                                                }),
                                          ])),
                                      const SizedBox(height: 8.0),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: HighlightView(
                                          snippet.code,
                                          language: snippet.language.toLowerCase(),
                                          theme: githubDarkTheme,
                                          padding: const EdgeInsets.all(12),
                                          textStyle: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ])),
                        const SizedBox(
                          height: 8.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Description",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface),
                                ),
                                const Spacer(),
                                  TextButton.icon(
                                    onPressed: _isExplaining
                                        ? null
                                        : () => _explainCode(snippet),
                                    icon: _isExplaining
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.auto_awesome, size: 18),
                                    label: Text(_isExplaining
                                        ? 'Thinking...'
                                        : 'AI Description'),
                                    style: TextButton.styleFrom(
                                      backgroundColor:
                                          colorScheme.primary.withAlpha(25),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _aiExplanation ??
                                  snippet.description ??
                                  "No description. Click 'AI Description' to generate it.",
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface.withAlpha(204),
                                fontStyle: (_aiExplanation == null &&
                                        (snippet.description == null || snippet.description!.isEmpty))
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                            ),
                            if (_aiExplanation != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(Icons.smart_toy, size: 14, color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'AI Generated',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.primary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: snippet.tags.map((t) {
                            return Chip(
                              label: Text(t),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Author",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    snippet.author,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () =>
                                      controller.upvoteSnippet(snippet.id),
                                  icon: Icon(
                                    isUpvoted
                                        ? Icons.arrow_upward
                                        : Icons.arrow_upward_outlined,
                                    size: 24,
                                    color: isUpvoted ? colorScheme.primary : null,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  snippet.upvote.toString(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isUpvoted
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isUpvoted ? colorScheme.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ])),
            ))
    );
  }

  Future<void> _explainCode(snippet) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final gemini = AIService();

    if (!gemini.canMakeRequest(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Daily limit reached. ${gemini.getRemainingRequests(userId)}/1500 remaining.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isExplaining = true);

    try {
      final explanation = await gemini.explainCode(snippet.code, snippet.language);

      if (mounted) {
        setState(() {
          _aiExplanation = explanation;
          _isExplaining = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('description generated!')),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExplaining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating description: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
