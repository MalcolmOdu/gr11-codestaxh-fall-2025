import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:codestaxh/models/snippet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive.dart';

//This notifier manages the list of snippets
class SnippetNotifier extends Notifier<List<Snippet>> {

  final CollectionReference _snippetsCollection = FirebaseFirestore.instance.collection('snippets');

  @override
  List<Snippet> build() {   //where we load initial data from hive
    final box = Hive.box<Snippet>('snippets');
    final initialSnippets = box.values.toList();

    _listenToFirestoreChange();

    return initialSnippets;
  }

  void _listenToFirestoreChange() {
    _snippetsCollection.snapshots().listen((snapshot) {
      final snippets = <Snippet>[];
      final box = Hive.box<Snippet>('snippets');

      for (var doc in snapshot.docs) {
        try {
          final snippet = Snippet.fromFirestore(doc);
          snippets.add(snippet);
          box.put(snippet.id, snippet);
        } catch (e) {
          print('Error parsing snippet: ${doc.id}: $e');
        }
      }
      state = snippets;
    }, onError: (error) {
      print('Error listening to Firestore: $error');
    });
  }

  Future<void> add(Snippet snippet) async {
    state = [...state, snippet];

    final box = Hive.box<Snippet>('snippets');
    await box.put(snippet.id, snippet);

    try {
      await _snippetsCollection.doc(snippet.id).set(snippet.toMap());
      print('Snippet ${snippet.id} synced to Firestore');
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }

  Future<void> remove(String id) async {
    state = state.where((snippet) => snippet.id != id).toList();

    final box = Hive.box<Snippet>('snippets');
    await box.delete(id);

    try {
      await _snippetsCollection.doc(id).delete();
      print('Snippet $id deleted from Firestore');
    } catch (e) {
      print('Error deleting from Firestore: $e');
    }
  }

  /// Update an existing snippet in both Hive and Firestore
  Future<void> update(String id, Snippet updatedSnippet) async {
    state = state.map((snippet) {
      if (snippet.id == id) {
        return updatedSnippet;
      }
      return snippet;
    }).toList();

    final box = Hive.box<Snippet>('snippets');
    await box.put(id, updatedSnippet);

    try {
      await _snippetsCollection.doc(id).update(updatedSnippet.toMap());
      print('Snippet $id updated in Firestore');
    } catch (e) {
      print('Error updating Firestore: $e');
    }
  }


  Future<void> upvote(String id) async {
    final snippet = state.firstWhere((s) => s.id == id);

    final updatedSnippet = Snippet(
      id: snippet.id,
      title: snippet.title,
      code: snippet.code,
      language: snippet.language,
      tags: snippet.tags,
      author: snippet.author,
      upvote: snippet.upvote + 1,
      dateAdded: snippet.dateAdded,
    );


    await update(id, updatedSnippet);
  }
}

// Provider for snippet state management
final snippetProvider = NotifierProvider<SnippetNotifier, List<Snippet>>(() {
  return SnippetNotifier();
});