import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String ownerId;
  final List<String> members;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  factory Team.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final createdAtField = map['createdAt'];

    if (createdAtField is Timestamp) {
      parsedDate = createdAtField.toDate();
    } else if (createdAtField is String) {
      parsedDate = DateTime.parse(createdAtField);
    } else {
      parsedDate = DateTime.now();
    }
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      ownerId: map['ownerId'] as String,
      members: List<String>.from(map['members'] as List),
      createdAt: parsedDate,
    );
  }
  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team.fromMap(data);
  }
}