import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/snippet.dart';
import 'snippet_notifier.dart';

class SnippetController {
  final WidgetRef ref;

  SnippetController(this.ref);

  Future<void> addSnippet({
    required String title,
    required String code,
    required String language,
    required List<String> tags,
    String? description,
    String? teamId,
  }) async {
    const uuid = Uuid();
    final id = uuid.v4();
    final user = FirebaseAuth.instance.currentUser!;
    final author = user.displayName ?? user.email ?? 'Anonymous';

    final snippet = Snippet(
      id: id,
      title: title,
      code: code,
      language: language,
      tags: tags,
      author: author,
      upvote: 0,
      dateAdded: DateTime.now(),
      description: description,
      teamId: teamId,
    );

    await ref.read(snippetProvider.notifier).add(snippet);
  }


  Future<void> removeSnippet(String id) async {
    await ref.read(snippetProvider.notifier).remove(id);
  }

  Future<void> updateSnippet({
    required String id,
    required String title,
    required String code,
    required String language,
    required List<String> tags,
    String? description,
    String? teamId,
  }) async {
    final snippets = ref.read(snippetProvider);
    final oldSnippet = snippets.firstWhere((s) => s.id == id);

    final updatedSnippet = Snippet(
      id: id,
      title: title,
      code: code,
      language: language,
      tags: tags,
      author: oldSnippet.author,
      upvote: oldSnippet.upvote,
      dateAdded: oldSnippet.dateAdded,
      description: description ?? oldSnippet.description,
      teamId: teamId ?? oldSnippet.teamId,
    );

    await ref.read(snippetProvider.notifier).update(id, updatedSnippet);
  }


  Future<void> upvoteSnippet(String id) async {
    await ref.read(snippetProvider.notifier).upvote(id);
  }

  List<Snippet> getAllSnippets() {
    return ref.read(snippetProvider);
  }
}