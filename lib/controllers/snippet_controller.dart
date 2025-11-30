import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/snippet.dart';
import 'snippet_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SnippetController {
  final WidgetRef ref;

  SnippetController(this.ref);

  final CollectionReference _snippetsCollection = FirebaseFirestore.instance.collection('snippets');

  Future<void> addSnippet({
    required String title,
    required String code,
    required String language,
    required List<String> tags,
    String? description,
    String? teamId,
    required String authorId,
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
      authorId: authorId,
    );

    await _snippetsCollection.doc(id).set(snippet.toMap());
  }


  Future<void> removeSnippet(String id) async {
    await _snippetsCollection.doc(id).delete();
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
    final snippets = ref.read(snippetProvider).value ?? [];
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
      authorId: oldSnippet.authorId,
    );

    await _snippetsCollection.doc(id).update(updatedSnippet.toMap());
  }


  Future<void> upvoteSnippet(String id) async {
    await _snippetsCollection.doc(id).update({
      'upvote': FieldValue.increment(1),
    });
  }

  List<Snippet> getAllSnippets() {
    return ref.read(snippetProvider).value ?? [];
  }
}