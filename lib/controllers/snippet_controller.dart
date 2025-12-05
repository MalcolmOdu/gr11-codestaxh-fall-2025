import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/snippet.dart';
import 'snippet_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/notification_provider.dart';

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

    if (teamId != null) {
      _notifyTeam(snippet);
    }
  }

  Future<void> _notifyTeam(Snippet snippet) async {
    try{
      // Get team document, used to get team members to notify
      final teamDoc = await FirebaseFirestore.instance.collection('teams').doc(snippet.teamId).get();

      if (teamDoc.exists){
        // teammates from teamDoc, lists members or empty list if none/not found
        final teammates = List<String>.from(teamDoc.data()?['members']??[]);
        // team name used in notification display
        final teamName = teamDoc.data()?['name']??'Team name not found';

        // Send notification to team members (except creator)
        for (final memberId in teammates) {
          if (memberId != snippet.authorId) {
            await NotificationProvider.sendNotification(
              toUserId: memberId,
              title: 'New Snippet added to $teamName',
              body: '${snippet.author} added ${snippet.title}',
              iconString: 'code',
              path: '/snippet/${snippet.id}',
            );
          }
        }
      }
    }
    catch (e) {
      print('Error notifying team members of post: $e');
    }
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
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final docRef = _snippetsCollection.doc(id);
    
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data() as Map<String, dynamic>;
    final List<String> upvotedBy = List<String>.from(data['upvotedBy'] ?? []);
    final String? authorId = data['authorId'];
    final String title = data['title'] ?? 'Snippet';

    if (upvotedBy.contains(currentUser.uid)) {
      // already upvoted, remove upvote if tapped
      await docRef.update({
        'upvote': FieldValue.increment(-1),
        'upvotedBy': FieldValue.arrayRemove([currentUser.uid]),
      });
    } else {
      // havent upvoted, add upvote when tapped
      await docRef.update({
        'upvote': FieldValue.increment(1),
        'upvotedBy': FieldValue.arrayUnion([currentUser.uid]),
      });

      // send notification only if upvoted
      if (authorId != null && authorId != currentUser.uid) {
        await NotificationProvider.sendNotification(
          toUserId: authorId,
          title: 'Snippet Upvoted',
          body: '${currentUser.displayName ?? "Someone"} upvoted "$title"',
          iconString: 'upvote',
          path: '/snippet/$id',
        );
      }
    }
  }
  

  List<Snippet> getAllSnippets() {
    return ref.read(snippetProvider).value ?? [];
  }
}