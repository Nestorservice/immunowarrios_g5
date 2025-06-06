// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laboratoire_recherche.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LaboratoireRechercheAdapter extends TypeAdapter<LaboratoireRecherche> {
  @override
  final int typeId = 1;

  @override
  LaboratoireRecherche read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LaboratoireRecherche(
      pointsRecherche: fields[0] as double,
      recherchesDebloquees: (fields[1] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, LaboratoireRecherche obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.pointsRecherche)
      ..writeByte(1)
      ..write(obj.recherchesDebloquees);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LaboratoireRechercheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
