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
    final snippets = ref.watch(snippetProvider);
    final snippet = snippets.firstWhere((s) => s.id == widget.id);
    final controller = SnippetController(ref);

    // global color scheme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 36),
            child: NotificationBell(),
          )
        ],
        toolbarHeight: 80,
        title: Text("Code Snippet"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          
          width: double.infinity,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // TITLE
                  Text(
                    snippet.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  // LANGUAGE BADGE
                  Chip(
                    label: Text(snippet.language),
                  ),

                  const SizedBox(height: 6),

                
                  Container(
                    width: double.infinity,
                   
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child:
                    Padding(padding: const EdgeInsets.all(0),
                      child:
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        
                        children: [
                             Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                                decoration: BoxDecoration(
                                  
                                  color: colorScheme.secondary,
                                  borderRadius: const BorderRadius.vertical(
                                     top: Radius.circular(8),
                                  
                                  ),
                                ),
                                child: Row(
                                  children: [
                                 Text(
                                  "Code",
                                  style: TextStyle(
                                    color: colorScheme.onSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.copy, color: colorScheme.onSecondary, size: 20),
                                  onPressed: () {
                                    // Copy snippet to clipboard
                                    Clipboard.setData(ClipboardData(text: snippet.code));
                                    
                                    // Optional: show a snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Code copied to clipboard!")),
                                    );
                                  }
                                ),
                                  ]
                                )
                              ),
                        
                              const SizedBox(height: 8.0),
                          
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                
                                child: HighlightView(
                                  
                                  snippet.code,
                                  language: snippet.language.toLowerCase(),
                                  theme: githubDarkTheme,
                                  padding: const EdgeInsets.all(12),
                                  textStyle:
                                      const TextStyle(fontSize: 12),
                                ),
                              ),
                        ]
                      )
                      )
                   ),
                  const SizedBox(height: 8.0,),
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
                                color: colorScheme.onSurface
                            ),
                          ),
                          const Spacer(),
                          if (snippet.description == null || snippet.description!.isEmpty)
                            TextButton.icon(
                              onPressed: _isExplaining ? null : () => _explainCode(snippet),
                              icon: _isExplaining
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                                  : const Icon(Icons.auto_awesome, size: 18),
                              label: Text(_isExplaining ? 'Thinking...' : 'AI Description'),
                              style: TextButton.styleFrom(
                                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _aiExplanation ??
                            snippet.description ??
                            "No description. Click ' AI Description ' to generate it.'.",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          fontStyle: (_aiExplanation == null && snippet.description == null)
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
                  Row(
                    
                    children: [
                      
                      const SizedBox(width: 4.0),
                      Wrap(
                        spacing: 3,
                        children: snippet.tags.map((t) {
                          return Chip(
                            label: Text(t),
                          );
                        }).toList(),
                      ),
                      Spacer(),
                      Row(
                        
                        children: [
                          IconButton(
                            onPressed: () => controller.upvoteSnippet(snippet.id),
                            icon: Icon(
                              Icons.arrow_upward,
                              size: 30
                            )
                            ),
                          
                          Text(snippet.upvote.toString(),
                          style: TextStyle(
                            fontSize: 20
                          ),),
                        ],
                      
                      ),
                      

                     ]
                  ),
                  RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: " Author \n ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface
                            ),
                          ),
                          TextSpan(
                            text: snippet.author,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.8)
                            ),
                          ),
                        ],
                      ),
                    ),
                ]
              
            )

          ),
          )
        )
        )
      );
    }
  Future<void> _explainCode(snippet) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final gemini = AIService();

    if (!gemini.canMakeRequest(userId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily limit reached. ${gemini.getRemainingRequests(userId)}/1500 remaining.'),
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
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('description generated!')
                ),
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
