import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/team.dart';

class TeamNotifier extends Notifier<List<Team>> {
  final CollectionReference _teamsCollection = FirebaseFirestore.instance.collection('teams');

  @override
  List<Team> build() {
    _listenToFirestoreChange();
    return [];
  }

  void _listenToFirestoreChange() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _teamsCollection.snapshots().listen((snapshot) {
      final teams = <Team>[];

      for (var doc in snapshot.docs) {
        try {
          final team = Team.fromFirestore(doc);
          if (team.ownerId == user.uid || team.members.contains(user.uid)) {
            teams.add(team);
          }
        } catch (e) {
          print('Error parsing team: ${doc.id}: $e');
        }
      }
      state = teams;
    }, onError: (error) {
      print('Error listening to teams: $error');
    });
  }

  //create a new team
  Future<void> createTeam(String teamName) async{
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final teamId = _teamsCollection.doc().id;
    final team = Team(
      id: teamId,
      name: teamName,
      ownerId: user.uid,
      members: [user.uid],
      createdAt: DateTime.now(),
    );
    try {
      await _teamsCollection.doc(teamId).set(team.toMap());
      print('Team $teamId created');
    } catch (e) {
      print('Error creating team: $e');
      rethrow;
    }
  }

  //Add member to team 
  Future<void> addMember(String teamId, String userEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = state.firstWhere((t) => t.id == teamId);
    if (team.ownerId != user.uid) throw Exception('Only the owner can add members');

    final userSnapshot = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: userEmail).limit(1).get();

    if (userSnapshot.docs.isEmpty) throw Exception('User not found');

    final newUserId = userSnapshot.docs.first.id;
    //Add to members Array
    final updatedMembers = [...team.members, newUserId];
    try{
      await _teamsCollection.doc(teamId).update({'members': updatedMembers});
      print('Member $newUserId added to team $teamId');
    } catch (e) {
      print('Error adding member: $e');
      rethrow;
    }
  }

  //remove member
  Future<void> removeMember(String teamId, String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    final team = state.firstWhere((t) => t.id == teamId);

    if (team.ownerId != user.uid) throw Exception('Only the owner can remove members');

    final updatedMembers = team.members.where((m) => m != userId).toList();
    try {
      await _teamsCollection.doc(teamId).update({'members': updatedMembers});
      print('Member $userId removed from team $teamId');
    } catch (e) {
      print('Error removing member: $e');
      rethrow;
    }
  }

  //Delete team
  Future<void> deleteTeam(String teamId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final team = state.firstWhere((t) => t.id == teamId);
    if (team.ownerId != user.uid) throw Exception('Only the owner can delete the team');

    try {
      await _teamsCollection.doc(teamId).delete();
      print('Team $teamId deleted');
    } catch (e) {
      print('Error deleting team: $e');
      rethrow;
    }
  }
}

// Provider for team state management
final teamProvider = NotifierProvider<TeamNotifier, List<Team>>(() {
  return TeamNotifier();
});