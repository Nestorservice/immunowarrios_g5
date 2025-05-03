// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memoire_immunitaire.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoireImmunitaireAdapter extends TypeAdapter<MemoireImmunitaire> {
  @override
  final int typeId = 2;

  @override
  MemoireImmunitaire read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoireImmunitaire(
      typesConnus: (fields[0] as List?)?.cast<String>(),
      bonusEfficacite: (fields[1] as Map?)?.cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, MemoireImmunitaire obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.typesConnus)
      ..writeByte(1)
      ..write(obj.bonusEfficacite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoireImmunitaireAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
