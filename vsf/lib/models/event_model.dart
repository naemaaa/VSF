// event_model.dart
import 'package:hive/hive.dart';
import 'event_location.dart';

part 'event_model.g.dart';

@HiveType(typeId: 4)
class EventModel extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String description;
  @HiveField(3) final String? imageUrl;

  // Organizer info
  @HiveField(4) final String organizerId;
  @HiveField(5) final String organizerName;
  @HiveField(6) final String? organizerImageUrl;

  // Location (detail)
  @HiveField(7) final EventLocationModel location;

  // Time (UTC untuk consistency)
  @HiveField(8) final DateTime eventStartTime;
  @HiveField(9) final DateTime eventEndTime;

  // Volunteer & Donation
  @HiveField(10) final int targetVolunteerCount;
  @HiveField(11) int currentVolunteerCount; // <-- Dibiarkan non-final agar bisa dimutasi oleh Hive save()
  @HiveField(12) final int participationFeeIdr; 

  // Category
  @HiveField(13) final String category; 

  // Status
  @HiveField(14) final bool isActive;

  @HiveField(15) final DateTime createdAt;

  // List volunteer IDs yang sudah daftar
  @HiveField(16) final List<String> registeredVolunteerIds;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.organizerId,
    required this.organizerName,
    this.organizerImageUrl,
    required this.location,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.targetVolunteerCount,
    this.currentVolunteerCount = 0,
    this.participationFeeIdr = 0,
    required this.category,
    this.isActive = true,
    DateTime? createdAt,
    List<String>? registeredVolunteerIds,
  })  : createdAt = createdAt ?? DateTime.now(),
        registeredVolunteerIds = registeredVolunteerIds ?? [];
  
  // ==================== FACTORY FROM JSON ====================
  // (Sama seperti implementasi terakhir)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<String> parseRegisteredIds(dynamic value) {
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    double parseCoordinate(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final locationModel = EventLocationModel(
      country: json['location_country'] as String? ?? '',
      province: json['location_province'] as String? ?? '',
      city: json['location_city'] as String? ?? '',
      district: json['location_district'] as String? ?? '',
      village: json['location_village'] as String? ?? '',
      latitude: parseCoordinate(json['location_latitude']),
      longitude: parseCoordinate(json['location_longitude']),
    );
    
    final id = json['id'].toString();

    return EventModel(
      id: id,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      organizerId: json['organizer_id'] as String,
      organizerName: json['organizer_name'] as String,
      organizerImageUrl: json['organizer_image_url'] as String?,
      location: locationModel,
      eventStartTime: DateTime.parse(json['event_start_time'] as String).toUtc(),
      eventEndTime: DateTime.parse(json['event_end_time'] as String).toUtc(),
      targetVolunteerCount: json['target_volunteer_count'] as int,
      currentVolunteerCount: json['current_volunteer_count'] as int? ?? 0,
      participationFeeIdr: json['participation_fee_idr'] as int? ?? 0,
      category: json['category'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      registeredVolunteerIds: parseRegisteredIds(json['registered_volunteer_ids']),
    );
  }

  // ==================== METHOD copyWith BARU ====================
  // Digunakan untuk membuat EventModel baru dengan beberapa field yang diubah
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? organizerId,
    String? organizerName,
    String? organizerImageUrl,
    EventLocationModel? location,
    DateTime? eventStartTime,
    DateTime? eventEndTime,
    int? targetVolunteerCount,
    int? currentVolunteerCount,
    int? participationFeeIdr,
    String? category,
    bool? isActive,
    DateTime? createdAt,
    List<String>? registeredVolunteerIds,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      organizerImageUrl: organizerImageUrl ?? this.organizerImageUrl,
      location: location ?? this.location,
      eventStartTime: eventStartTime ?? this.eventStartTime,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      targetVolunteerCount: targetVolunteerCount ?? this.targetVolunteerCount,
      currentVolunteerCount: currentVolunteerCount ?? this.currentVolunteerCount, 
      participationFeeIdr: participationFeeIdr ?? this.participationFeeIdr,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      registeredVolunteerIds: registeredVolunteerIds ?? this.registeredVolunteerIds,
    );
  }

  // ==================== GETTERS (Diperlukan oleh UI) ====================

  // Getter: volunteerPercentage (Error di image_37a796.png)
  double get volunteerPercentage {
    if (targetVolunteerCount == 0) return 0;
    return (currentVolunteerCount / targetVolunteerCount) * 100;
  }
  
  // Getter: remainingSlots (Diperlukan di ActivityDetailPage)
  int get remainingSlots => targetVolunteerCount - currentVolunteerCount;

  // Getter: isFull (Diperlukan di ActivityDetailPage)
  bool get isFull => currentVolunteerCount >= targetVolunteerCount;

  // Getter: isPast (Diperlukan di ActivityDetailPage)
  bool get isPast => DateTime.now().toUtc().isAfter(eventEndTime);

  // Getter: isOngoing (Diperlukan di ActivityDetailPage)
  bool get isOngoing {
    final now = DateTime.now().toUtc();
    return now.isAfter(eventStartTime) && now.isBefore(eventEndTime);
  }

  // Getter: isFree (Diperlukan di ActivityDetailPage)
  bool get isFree => participationFeeIdr == 0;

  // Getter: formattedPrice (Diperlukan di ActivityDetailPage & EventCard)
  String get formattedPrice {
    if (isFree) return 'Gratis';
    return 'Rp ${participationFeeIdr.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    )}';
  }

  // Getter: eventStatus (Diperlukan di ActivityDetailPage & EventCard)
  String get eventStatus {
    if (isPast) return 'Selesai';
    if (!isActive) return 'Tidak Aktif';
    if (isFull) return 'Penuh';
    if (isOngoing) return 'Berlangsung';
    return 'Tersedia'; // Upcoming
  }

  // Getter: formattedEventDate (Diperlukan di ActivityDetailPage & EventCard)
  String get formattedEventDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final local = eventStartTime.toLocal();
    final dayIndex = local.weekday % 7; 
    return '${days[dayIndex]}, ${local.day} ${months[local.month - 1]} ${local.year}';
  }
  
  // ==================== METHODS (Diperlukan oleh ActivityDetailPage) ====================

  // Method: isUserRegistered (Error di image_37a737.png)
  bool isUserRegistered(String userId) {
    return registeredVolunteerIds.contains(userId);
  }
  
  // Method: removeVolunteer (Error di image_37a6fa.png)
  void removeVolunteer(String volunteerId) {
    if (registeredVolunteerIds.contains(volunteerId)) {
      registeredVolunteerIds.remove(volunteerId);
      currentVolunteerCount = currentVolunteerCount > 0 ? currentVolunteerCount - 1 : 0;
      // Perhatikan: Karena currentVolunteerCount diubah menjadi non-final, mutasi ini
      // akan tersimpan saat event.save() dipanggil di ActivityDetailPage.
    }
  }
  
  // Method: addVolunteer (Diperlukan untuk konsistensi/future use)
  void addVolunteer(String volunteerId) {
    if (!registeredVolunteerIds.contains(volunteerId) && !isFull) {
      registeredVolunteerIds.add(volunteerId);
      currentVolunteerCount++;
    }
  }

  @override
  String toString() => 'EventModel(id: $id, title: $title)';
}