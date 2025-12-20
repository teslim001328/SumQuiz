// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContentFolderAdapter extends TypeAdapter<ContentFolder> {
  @override
  final int typeId = 6;

  @override
  ContentFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContentFolder(
      contentId: fields[0] as String,
      folderId: fields[1] as String,
      contentType: fields[2] as String,
      userId: fields[3] as String,
      assignedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ContentFolder obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.contentId)
      ..writeByte(1)
      ..write(obj.folderId)
      ..writeByte(2)
      ..write(obj.contentType)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.assignedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentFolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
