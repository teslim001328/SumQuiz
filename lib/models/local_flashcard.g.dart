// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalFlashcardAdapter extends TypeAdapter<LocalFlashcard> {
  @override
  final int typeId = 3;

  @override
  LocalFlashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalFlashcard(
      question: fields[0] as String,
      answer: fields[1] as String,
    )..id = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, LocalFlashcard obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.answer)
      ..writeByte(2)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalFlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
