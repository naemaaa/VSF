// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventLocationModelAdapter extends TypeAdapter<EventLocationModel> {
  @override
  final int typeId = 2;

  @override
  EventLocationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventLocationModel(
      country: fields[0] as String,
      province: fields[1] as String,
      city: fields[2] as String,
      district: fields[3] as String,
      village: fields[4] as String,
      latitude: fields[6] as double,
      longitude: fields[7] as double,
    );
  }

  @override
  void write(BinaryWriter writer, EventLocationModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.country)
      ..writeByte(1)
      ..write(obj.province)
      ..writeByte(2)
      ..write(obj.city)
      ..writeByte(3)
      ..write(obj.district)
      ..writeByte(4)
      ..write(obj.village)
      ..writeByte(6)
      ..write(obj.latitude)
      ..writeByte(7)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLocationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
