// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EventModelAdapter extends TypeAdapter<EventModel> {
  @override
  final int typeId = 4;

  @override
  EventModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EventModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      imageUrl: fields[3] as String?,
      organizerId: fields[4] as String,
      organizerName: fields[5] as String,
      organizerImageUrl: fields[6] as String?,
      location: fields[7] as EventLocationModel,
      eventStartTime: fields[8] as DateTime,
      eventEndTime: fields[9] as DateTime,
      targetVolunteerCount: fields[10] as int,
      currentVolunteerCount: fields[11] as int,
      participationFeeIdr: fields[12] as int,
      category: fields[13] as String,
      isActive: fields[14] as bool,
      createdAt: fields[15] as DateTime?,
      registeredVolunteerIds: (fields[16] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, EventModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.organizerId)
      ..writeByte(5)
      ..write(obj.organizerName)
      ..writeByte(6)
      ..write(obj.organizerImageUrl)
      ..writeByte(7)
      ..write(obj.location)
      ..writeByte(8)
      ..write(obj.eventStartTime)
      ..writeByte(9)
      ..write(obj.eventEndTime)
      ..writeByte(10)
      ..write(obj.targetVolunteerCount)
      ..writeByte(11)
      ..write(obj.currentVolunteerCount)
      ..writeByte(12)
      ..write(obj.participationFeeIdr)
      ..writeByte(13)
      ..write(obj.category)
      ..writeByte(14)
      ..write(obj.isActive)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.registeredVolunteerIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
