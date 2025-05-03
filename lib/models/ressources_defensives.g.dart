// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ressources_defensives.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RessourcesDefensivesAdapter extends TypeAdapter<RessourcesDefensives> {
  @override
  final int typeId = 0;

  @override
  RessourcesDefensives read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RessourcesDefensives(
      energie: fields[0] as double,
      bioMateriaux: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, RessourcesDefensives obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.energie)
      ..writeByte(1)
      ..write(obj.bioMateriaux);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RessourcesDefensivesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
