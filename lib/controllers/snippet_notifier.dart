import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:codestaxh/models/snippet.dart';

//This notifier manages the list of snippets
class SnippetNotifier extends Notifier<List<Snippet>> {

  @override
  List<Snippet> build() {   //where we load initial data from hive
    final box = Hive.box<Snippet>('snippets');
    return box.values.toList();
  }

  void add(Snippet snippet) {
    final currentSnippets = state;
    state = [...currentSnippets, snippet];
    final box = Hive.box<Snippet>('snippets');  //save to hive for offline persistence
    box.put(snippet.id, snippet);
  }

  void remove(String id) {
    state = state.where((snippet) => snippet.id != id).toList();
    final box = Hive.box<Snippet>('snippets');
    box.delete(id);
  }

  void update(String id, Snippet updatedSnippet) {
    state = state.map((snippet) {
      if (snippet.id == id) {
        return updatedSnippet;
      }
      return snippet;
    }).toList();

    final box = Hive.box<Snippet>('snippets');
    box.put(id, updatedSnippet);
  }

  //increment upvote count for a snippet
  void upvote(String id) {
    state = state.map((snippet) {
      if (snippet.id == id){
        return Snippet(
          id: snippet.id,
          title: snippet.title,
          code: snippet.code,
          language: snippet.language,
          tags: snippet.tags,
          author: snippet.author,
          upvote: snippet.upvote + 1,
          dateAdded: snippet.dateAdded
        );
      }
      return snippet;
    }).toList();

    final box = Hive.box<Snippet>('snippets');
    final snippet = state.firstWhere((snippet) => snippet.id == id);
    box.put(id, snippet);
  }
}