import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:codestaxh/models/snippet.dart';
import 'snippet_notifier.dart';

class SnippetController {
 final WidgetRef ref;

  SnippetController(this.ref);

  void addSnippet({
    required String title,
    required String code,
    required String language,
    required List<String> tags,
    required String author,
  }){
    const uuid = Uuid();
    final id = uuid.v4();

    final snippet = Snippet(
      id: id,
      title: title,
      code: code,
      language: language,
      tags: tags,
      author: author,
      upvote: 0,
      dateAdded: DateTime.now(),
    );

    ref.read(snippetProvider.notifier).add(snippet);
  }

  void removeSnippet(String id){
    ref.read(snippetProvider.notifier).remove(id);
  }

  void uodateSnippet({
    required String id,
    required String title,
    required String code,
    required String language,
    required List<String> tags,
  }){
    final snippets = ref.read(snippetProvider);
    final oldSnippet = snippets.firstWhere((snippet) => snippet.id == id);
    final updatedSnippet = Snippet(
      id: id,
      title: title,
      code: code,
      language: language,
      tags: tags,
      author: oldSnippet.author,
      upvote: oldSnippet.upvote,
      dateAdded: oldSnippet.dateAdded,
    );
    ref.read(snippetProvider.notifier).update(id, updatedSnippet);
  }

  void upvoteSnippet(String id){
    ref.read(snippetProvider.notifier).upvote(id);
  }

  List<Snippet> getAllSnippets(){
    return ref.read(snippetProvider);
  }
}