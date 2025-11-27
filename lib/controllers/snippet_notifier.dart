import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:codestaxh/models/snippet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive.dart';

//This notifier manages the list of snippets
class SnippetNotifier extends Notifier<List<Snippet>> {

  final CollectionReference _snippetsCollection = FirebaseFirestore.instance.collection('snippets');

  @override
  List<Snippet> build() {   //where we load initial data from hive
    List<Snippet> initialSnippets = [];

    if (!kIsWeb){
      //mobile only loads from hive cache
      final box = Hive.box<Snippet>('snippets');
      initialSnippets = box.values.toList();
    }

    _listenToFirestoreChange();

    return initialSnippets;
  }

  void _listenToFirestoreChange() {
    _snippetsCollection.snapshots().listen((snapshot) {
      final snippets = <Snippet>[];

      for (var doc in snapshot.docs) {
        try {
          final snippet = Snippet.fromFirestore(doc);
          snippets.add(snippet);
          if (!kIsWeb) {
            final box = Hive.box<Snippet>('snippets');
            box.put(snippet.id, snippet);
          }
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

    if (!kIsWeb) {
      final box = Hive.box<Snippet>('snippets');
      await box.put(snippet.id, snippet);

    }
    try {
      await _snippetsCollection.doc(snippet.id).set(snippet.toMap());
      print('Snippet ${snippet.id} synced to Firestore');
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }

  Future<void> remove(String id) async {
    state = state.where((snippet) => snippet.id != id).toList();

   if (!kIsWeb) {
     final box = Hive.box<Snippet>('snippets');
     await box.delete(id);
   }

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

    if (!kIsWeb) {
      final box = Hive.box<Snippet>('snippets');
      await box.put(id, updatedSnippet);
    }

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
      description: snippet.description
    );


    await update(id, updatedSnippet);
  }
}

// Provider for snippet state management
final snippetProvider = NotifierProvider<SnippetNotifier, List<Snippet>>(() {
  return SnippetNotifier();
});

// --- UI filtering state ---
final snippetSearchProvider = StateProvider<String>((ref) => "");
final snippetTagFilterProvider = StateProvider<Set<String>>((ref) => {});

// --- Derived filtered list ---
final filteredSnippetsProvider = Provider<List<Snippet>>((ref) {
  final snippets = ref.watch(snippetProvider);
  final search = ref.watch(snippetSearchProvider);
  final tags = ref.watch(snippetTagFilterProvider);

  final lowerTags = tags.map((t)=> t.toLowerCase()).toSet();

  //ADD MORE SEARCH PARAMETERS HERE IF NECESSARY
  return snippets.where((s) {
    final matchesSearch = search.isEmpty ||
        s.title.toLowerCase().contains(search.toLowerCase()) ||
        s.code.toLowerCase().contains(search.toLowerCase()) || 
        s.language.toLowerCase().contains(search.toLowerCase());

    final matchesTags = tags.isEmpty || s.tags.map((t)=> t.toLowerCase()).any(lowerTags.contains);


    return matchesSearch && matchesTags;
  }).toList();
}
);

