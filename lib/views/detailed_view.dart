import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/snippet_controller.dart';
import 'package:codestaxh/controllers/snippet_notifier.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlighting/themes/github-dark.dart';



class DetailedView extends ConsumerWidget {
  final String? id;
  const DetailedView({super.key, this.id});
  


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippets = ref.watch(snippetProvider);
    final snippet = snippets.firstWhere((s) => s.id == id);
    final controller = SnippetController(ref);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.lightBlue,
        title: Text("Author: ${snippet.author}"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          
          width: double.infinity,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                    backgroundColor:
                        Colors.blue.shade100,
                  ),

                  const SizedBox(height: 6),

                
                  Container(
                    height: 400,
                    width: 400,
                   
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child:
                    Padding(padding: const EdgeInsets.all(12),
                      child:
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        
                        children: [
                             Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  
                                  color: const Color.fromARGB(255, 36, 35, 35),                     // slightly darker bar
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12),
                                  
                                  ),
                                ),
                                child: const Text(
                                  "Code",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
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
                   RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: " Description \n ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // important!
                            ),
                          ),
                          TextSpan(
                            text: snippet.description ?? "No Description",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                    ,
                  Row(
                    
                    children: [
                      
                      const SizedBox(width: 4.0),
                      Wrap(
                        spacing: 3,
                        children: snippet.tags.map((t) {
                          return Chip(
                            label: Text(t),
                            backgroundColor:
                                Colors.green,
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
                  )
                ]
              
            )

          ),
          )
        )
        )
      );
    }
  }
