import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import '../controllers/snippet_controller.dart';
import 'package:codestaxh/controllers/snippet_notifier.dart';


class DetailedView extends ConsumerWidget {
  final String? id;
  const DetailedView({super.key, this.id});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippets = ref.read(snippetProvider);
    final snippet = snippets.firstWhere((s) => s.id == id);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(snippet.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(snippet.code),
        ),
    );
  }
}
