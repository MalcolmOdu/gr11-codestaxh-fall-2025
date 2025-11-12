import 'package:hive_ce/hive.dart';
part 'snippet.g.dart';

@HiveType(typeId: 1) //Unigue ID for this model
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

  Snippet({
    required this.id,
    required this.title,
    required this.code,
    required this.language,
    required this.tags,
    required this.author,
    required this.upvote,
    required this.dateAdded,
  });

}