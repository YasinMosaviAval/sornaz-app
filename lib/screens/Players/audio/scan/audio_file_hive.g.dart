// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_file_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AudioFileHiveAdapter extends TypeAdapter<AudioFileHive> {
  @override
  final int typeId = 0;

  @override
  AudioFileHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AudioFileHive(
      filePath: fields[0] as String,
      fileName: fields[1] as String,
      folderName: fields[2] as String,
      durationMs: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, AudioFileHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.fileName)
      ..writeByte(2)
      ..write(obj.folderName)
      ..writeByte(3)
      ..write(obj.durationMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioFileHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
