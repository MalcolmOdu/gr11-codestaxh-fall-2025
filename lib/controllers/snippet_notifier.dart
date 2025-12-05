import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:codestaxh/models/snippet.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/notification_provider.dart';

//This notifier manages the list of snippets
class SnippetStreamNotifier extends StreamNotifier<List<Snippet>> {

  final CollectionReference _snippetsCollection = FirebaseFirestore.instance.collection('snippets');

  @override
  Stream<List<Snippet>> build() {   //where we load initial data from hive
    final controller = StreamController<List<Snippet>>();

    if (!kIsWeb){
      //mobile only loads from hive cache
      final box = Hive.box<Snippet>('snippets');
      controller.add(box.values.toList());
    

    box.watch().listen((_){
      controller.add(box.values.toList());
    });
    }
    _snippetsCollection.snapshots().listen((snapshot) {
    final snippets = snapshot.docs
        .map((doc) => Snippet.fromFirestore(doc))
        .toList();

    controller.add(snippets);

    if (!kIsWeb) {
      final box = Hive.box<Snippet>('snippets');
      for (final snippet in snippets) {
        box.put(snippet.id, snippet);
      }
    }
    });

    return controller.stream;
  }

  Future<void> add(Snippet snippet) async {
    //state = [...state, snippet];

    if (!kIsWeb) {
      final box = Hive.box<Snippet>('snippets');
      await box.put(snippet.id, snippet);

    }
    try {
      await _snippetsCollection.doc(snippet.id).set(snippet.toMap());
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
  }

  Future<void> remove(String id) async {
    //state = state.where((snippet) => snippet.id != id).toList();

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
  
  Future<void> updateSnippet(String id, Snippet updatedSnippet) async {
 
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
    
    final doc = await _snippetsCollection.doc(id).get();
    if(!doc.exists) return;
    final snippet = Snippet.fromFirestore(doc);

    final currentUser = FirebaseAuth.instance.currentUser;

    final updatedSnippet = Snippet(
      id: snippet.id,
      title: snippet.title,
      code: snippet.code,
      language: snippet.language,
      tags: snippet.tags,
      author: snippet.author,
      upvote: snippet.upvote + 1,
      dateAdded: snippet.dateAdded,
      description: snippet.description,
      teamId: snippet.teamId,
      authorId: snippet.authorId
    );


    await updateSnippet(id, updatedSnippet);

    if (currentUser != null
      && snippet.authorId != null
      && snippet.authorId!.isNotEmpty
      && snippet.authorId != currentUser.uid) {
      await NotificationProvider.sendNotification(
        toUserId: snippet.authorId!,
        title: 'Snippet Upvoted',
        body: '${currentUser.displayName ?? "Someone"} upvoted your snippet: ${snippet.title}',
        iconString: 'upvote'
      );
    }
  }
}

// Provider for snippet state management
final snippetProvider = StreamProvider<List<Snippet>>((ref){
  return FirebaseFirestore.instance
      .collection('snippets')
      .snapshots()
      .map((q) => q.docs
          .map((doc) => Snippet.fromFirestore(doc))   // pass the whole snapshot
          .toList());
});
  

// --- UI filtering state ---
enum SnippetSortType {recent, upvote, none}

enum SnippetFilterType {all, personal, team}
//add author, language, 
final snippetSearchProvider = StateProvider<String>((ref) => "");
final snippetTagFilterProvider = StateProvider<Set<String>>((ref) => {});
final snippetLanguageFilterProvider = StateProvider<Set<String>>((ref) => {});
final snippetAuthorFilterProvider = StateProvider<Set<String>>((ref) => {});
final snippetSortProvider = StateProvider<SnippetSortType>((ref) => SnippetSortType.none); // 'recent' or 'upvote' or 'none'



final snippetFilterProvider = StateProvider<SnippetFilterType>((ref) => SnippetFilterType.all);

//advanced search parameters 
final filteredSnippetsProvider = Provider<List<Snippet>>((ref) {
  final asyncSnippets = ref.watch(snippetProvider);
  final search = ref.watch(snippetSearchProvider);
  final tags = ref.watch(snippetTagFilterProvider);
  final filterType = ref.watch(snippetFilterProvider);
  final languages = ref.watch(snippetLanguageFilterProvider);
  final authors = ref.watch(snippetAuthorFilterProvider);
  final sortType = ref.watch(snippetSortProvider);
  final user = FirebaseAuth.instance.currentUser;

  final lowerTags = tags.map((t)=> t.toLowerCase()).toSet();

  //ADD MORE SEARCH PARAMETERS HERE IF NECESSARY
  return asyncSnippets.when(
    loading: () => [],
    error: (_,_) => [],
    data: (snippets) {
    final filtered = snippets.where((s) {
      final matchesSearch = search.isEmpty ||
          s.title.toLowerCase().contains(search.toLowerCase()) ||
          s.code.toLowerCase().contains(search.toLowerCase()) || 
          s.language.toLowerCase().contains(search.toLowerCase());
     

      final matchesTags = tags.isEmpty || s.tags.map((t)=> t.toLowerCase()).any(lowerTags.contains);
      //author has to be exact match to filter, can be changed later
      final matchesAuthors = authors.isEmpty || authors.contains(s.author) || (s.authorId != null && authors.contains(s.authorId!));
      
      final matchesLanguages = languages.isEmpty || languages.map((lang)=> lang.toLowerCase()).contains(s.language.toLowerCase());
     
      bool matchesTeamFilter = true;
      switch (filterType) {
        case SnippetFilterType.all:
          matchesTeamFilter = true;
          break;
        case SnippetFilterType.personal:
          matchesTeamFilter = s.teamId == null && (s.author == user?.displayName || s.author == user?.email);
          break;
        case SnippetFilterType.team:
          matchesTeamFilter = s.teamId != null;
          break;
      }
      return matchesSearch && matchesTags && matchesTeamFilter && matchesLanguages && matchesAuthors;  
    }).toList();
    switch (sortType) {
        case SnippetSortType.none:
          
          break;

        case SnippetSortType.recent:
          filtered.sort(
              (a, b) => b.dateAdded.compareTo(a.dateAdded)); // newest first
              
          break;

        case SnippetSortType.upvote:
          filtered.sort(
              (a, b) => b.upvote.compareTo(a.upvote)); // highest first
              
          break;
      }
      return filtered;
  });
});

