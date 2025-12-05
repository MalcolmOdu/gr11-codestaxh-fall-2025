import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'snippet.g.dart';

@HiveType(typeId: 1) //Unique ID for this model
class Snippet extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String code;

  @HiveField(3)
  final String language;

  @HiveField(4)
  final List<String> tags;

  @HiveField(5)
  final String author;

  @HiveField(6)
  final int upvote;

  @HiveField(7)
  final DateTime dateAdded;

  @HiveField(8)
  final String? teamId;

  @HiveField(9)
  final String?description;

  @HiveField(10)
  final String? authorId;

  @HiveField(11)
  final List<String> upvotedBy;

  Snippet({
    required this.id,
    required this.title,
    required this.code,
    required this.language,
    required this.tags,
    required this.author,
    required this.upvote,
    required this.dateAdded,
    this.description,
    this.teamId,
    required this.authorId,
    this.upvotedBy = const [],
  });

  //Snippet to Map for Firestore
  Map<String, dynamic> toMap() {
    return{
      'id': id,
      'title': title,
      'code': code,
      'language': language,
      'tags': tags,
      'author': author,
      'upvote': upvote,
      'dateAdded': Timestamp.fromDate(dateAdded), //Firestore needs Timestamp
      'description': description,
      'teamId': teamId,
      'authorId':authorId,
      'upvotedBy': upvotedBy,
    };
  }

  //Map to Snippet from Firestore
  factory Snippet.fromMap(Map<String, dynamic> map) {
    return Snippet(
      id: map['id'] as String,
      title: map['title'] as String,
      code: map['code'] as String,
      language: map['language'] as String,
      tags: List<String>.from(map['tags'] as List),
      author: map['author'] as String,
      upvote: map['upvote'] as int,
      dateAdded: (map['dateAdded'] as Timestamp).toDate(),
      description: map['description'] as String?,
      teamId: map['teamId'] as String?,
      authorId: map['authorId'] as String? ?? '', // '' for old snippets with no author during testing
      upvotedBy: List<String>.from(map['upvotedBy'] ?? []),
    );
  }

  factory Snippet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Snippet.fromMap(data);
  }
}