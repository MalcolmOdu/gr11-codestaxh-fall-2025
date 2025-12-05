// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snippet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SnippetAdapter extends TypeAdapter<Snippet> {
  @override
  final int typeId = 1;

  @override
  Snippet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Snippet(
      id: fields[0] as String,
      title: fields[1] as String,
      code: fields[2] as String,
      language: fields[3] as String,
      tags: (fields[4] as List).cast<String>(),
      author: fields[5] as String,
      upvote: fields[6] as int,
      dateAdded: fields[7] as DateTime,
      description: fields[9] as String?,
      teamId: fields[8] as String?,
      authorId: fields[10] as String?,
      upvotedBy: (fields[11] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Snippet obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.language)
      ..writeByte(4)
      ..write(obj.tags)
      ..writeByte(5)
      ..write(obj.author)
      ..writeByte(6)
      ..write(obj.upvote)
      ..writeByte(7)
      ..write(obj.dateAdded)
      ..writeByte(8)
      ..write(obj.teamId)
      ..writeByte(9)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.authorId)
      ..writeByte(11)
      ..write(obj.upvotedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SnippetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
