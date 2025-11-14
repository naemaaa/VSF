import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'dart:io'; 
import '../models/event_model.dart';

class EventService {
  static final EventService _instance = EventService._internal();
  factory EventService() => _instance;
  EventService._internal();

  static const String SUPABASE_URL = 'https://jazhzojpgcumghslmquk.supabase.co'; 
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imphemh6b2pwZ2N1bWdoc2xtcXVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTk5MzUsImV4cCI6MjA3NzM3NTkzNX0.uPzc8dVI-LgDXY2aS_K8rSWx7kdwL5oV6xBHS9j1xEo'; 
  static const String STORAGE_BUCKET = 'event-images'; 

  final _headers = {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': 'Bearer $SUPABASE_ANON_KEY',
  };

  Map<String, dynamic> _eventToJson(EventModel event) {
    return {
      'id': event.id,
      'title': event.title,
      'description': event.description,
      'image_url': event.imageUrl,
      'organizer_id': event.organizerId,
      'organizer_name': event.organizerName,
      'organizer_image_url': event.organizerImageUrl,
      'event_start_time': event.eventStartTime.toIso8601String(),
      'event_end_time': event.eventEndTime.toIso8601String(),
      'target_volunteer_count': event.targetVolunteerCount,
      'current_volunteer_count': event.currentVolunteerCount,
      'participation_fee_idr': event.participationFeeIdr,
      'category': event.category,
      'is_active': event.isActive,
      'created_at': event.createdAt.toIso8601String(),
      'location_country': event.location.country,
      'location_province': event.location.province,
      'location_city': event.location.city,
      'location_district': event.location.district,
      'location_village': event.location.village,
      'location_latitude': event.location.latitude,
      'location_longitude': event.location.longitude,
      'registered_volunteer_ids': event.registeredVolunteerIds,
    };
  }

  Future<String?> uploadImageToStorage(File imageFile, String eventId) async {
    try {
      print('📤 Uploading image for event $eventId...');
      
      final bytes = await imageFile.readAsBytes();
      final fileName = '${eventId}_${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';

      final uploadResponse = await http.post(
        Uri.parse('$SUPABASE_URL/storage/v1/object/$STORAGE_BUCKET/$fileName'),
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': 'Bearer $SUPABASE_ANON_KEY',
          'Content-Type': 'image/${imageFile.path.split('.').last}',
        },
        body: bytes,
      ).timeout(const Duration(seconds: 30));

      if (uploadResponse.statusCode == 200 || uploadResponse.statusCode == 201) {
        final publicUrl = '$SUPABASE_URL/storage/v1/object/public/$STORAGE_BUCKET/$fileName';
        print('✅ Image uploaded: $publicUrl');
        return publicUrl;
      } else {
        print('❌ Upload failed: ${uploadResponse.statusCode} - ${uploadResponse.body}');
        return null;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  Future<void> _updateCache(List<EventModel> events) async {
    final eventBox = Hive.box<EventModel>('events');
    await eventBox.clear();
    for (var event in events) {
      await eventBox.put(event.id, event);
    }
    print('💾 Cache updated with ${events.length} events');
  }

  Future<void> _updateSingleCache(EventModel event) async {
    final eventBox = Hive.box<EventModel>('events');
    await eventBox.put(event.id, event);
    print('💾 Single event cached: ${event.id}');
  }

  // ==================== FETCH METHODS (API + CACHE) ====================
  
  Future<List<EventModel>> getAllEvents({bool forceRefresh = false}) async {
    final eventBox = Hive.box<EventModel>('events');
    
    if (!forceRefresh && eventBox.isNotEmpty) {
      print('📦 Loading events from cache (${eventBox.length} items)');
      return eventBox.values.toList();
    }

    try {
      print('🌐 Fetching events from Supabase...');
      final response = await http.get(
        Uri.parse('$SUPABASE_URL/rest/v1/events?order=created_at.desc'),
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Fetched ${data.length} events from API');
        final events = data.map((json) => EventModel.fromJson(json)).toList();
        await _updateCache(events);
        return events;
      } else {
        print('❌ API Error: ${response.statusCode}');
        return eventBox.values.toList();
      }
    } catch (e) {
      print('❌ Network Error: $e');
      return eventBox.values.toList();
    }
  }

  Future<List<EventModel>> getActiveEvents({bool forceRefresh = false}) async {
    final allEvents = await getAllEvents(forceRefresh: forceRefresh);
    return allEvents
        .where((event) => event.isActive && !event.isPast)
        .toList();
  }

  Future<EventModel?> getEventById(String id) async {
    final eventBox = Hive.box<EventModel>('events');
    final cachedEvent = eventBox.get(id);
    
    try {
      // PENTING: Force refresh dari API untuk mendapatkan status volunteer terbaru
      final response = await http.get(
        Uri.parse('$SUPABASE_URL/rest/v1/events?id=eq.$id&select=*&limit=1'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final event = EventModel.fromJson(data.first);
          await _updateSingleCache(event);
          return event;
        }
      }
      return cachedEvent;
    } catch (e) {
      print('❌ Error getEventById: $e');
      return cachedEvent;
    }
  }

  Future<List<EventModel>> getEventsByOrganizer(String organizerId) async {
    final allEvents = await getAllEvents();
    return allEvents.where((e) => e.organizerId == organizerId).toList();
  }

  Future<List<EventModel>> searchEvents(String query) async {
    final allEvents = await getAllEvents();
    final lowerQuery = query.toLowerCase();
    return allEvents.where((e) => 
      e.title.toLowerCase().contains(lowerQuery) ||
      e.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // ==================== CUD OPERATIONS (API + CACHE) ====================
  
  /// CREATE: Post event baru ke API
  Future<EventModel?> createEvent(EventModel event, File? imageFile) async {
    try {
      print('📝 Creating event: ${event.title}...');
      
      // 1. Upload image dulu (jika ada)
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await uploadImageToStorage(imageFile, event.id);
        if (imageUrl == null) {
          print('⚠️ Image upload failed, continuing without image');
        }
      }

      // 2. Update event dengan image URL
      final eventToSave = EventModel(
        id: event.id,
        title: event.title,
        description: event.description,
        imageUrl: imageUrl ?? event.imageUrl,
        organizerId: event.organizerId,
        organizerName: event.organizerName,
        organizerImageUrl: event.organizerImageUrl,
        location: event.location,
        eventStartTime: event.eventStartTime,
        eventEndTime: event.eventEndTime,
        targetVolunteerCount: event.targetVolunteerCount,
        currentVolunteerCount: event.currentVolunteerCount,
        participationFeeIdr: event.participationFeeIdr,
        category: event.category,
        isActive: event.isActive,
        createdAt: event.createdAt,
        registeredVolunteerIds: event.registeredVolunteerIds,
      );

      // 3. POST ke Supabase dengan select=* untuk mendapatkan response
      final payload = _eventToJson(eventToSave);

      final response = await http.post(
        Uri.parse('$SUPABASE_URL/rest/v1/events?select=*'), // ⬅️ PERBAIKAN
        headers: {
          ..._headers,
          'Prefer': 'return=representation', // ⬅️ PERBAIKAN
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Event created successfully!');
        
        // 4. Parse response & update cache
        if (response.body.isNotEmpty) { // ⬅️ PERBAIKAN: Cek dulu apakah body tidak kosong
          try {
            final List<dynamic> responseData = jsonDecode(response.body);
            if (responseData.isNotEmpty) {
              final createdEvent = EventModel.fromJson(responseData.first);
              await _updateSingleCache(createdEvent);
              return createdEvent;
            }
          } catch (e) {
            print('⚠️ Failed to parse response: $e');
          }
        }
        
        // Fallback: return event yang kita kirim
        await _updateSingleCache(eventToSave);
        return eventToSave;
      } else {
        print('❌ Create failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Create error: $e');
      return null;
    }
  }

  /// UPDATE: Patch event yang sudah ada
  Future<EventModel?> updateEvent(EventModel event, File? newImageFile) async {
    try {
      print('✏️ Updating event: ${event.title}...');
      
      // 1. Upload image baru jika ada
      String? imageUrl = event.imageUrl;
      if (newImageFile != null) {
        final uploadedUrl = await uploadImageToStorage(newImageFile, event.id);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      // 2. Update event dengan image URL baru
      final eventToUpdate = EventModel(
        id: event.id,
        title: event.title,
        description: event.description,
        imageUrl: imageUrl,
        organizerId: event.organizerId,
        organizerName: event.organizerName,
        organizerImageUrl: event.organizerImageUrl,
        location: event.location,
        eventStartTime: event.eventStartTime,
        eventEndTime: event.eventEndTime,
        targetVolunteerCount: event.targetVolunteerCount,
        currentVolunteerCount: event.currentVolunteerCount,
        participationFeeIdr: event.participationFeeIdr,
        category: event.category,
        isActive: event.isActive,
        createdAt: event.createdAt,
        registeredVolunteerIds: event.registeredVolunteerIds,
      );

      // 3. PATCH ke Supabase
      final payload = _eventToJson(eventToUpdate);
      payload.remove('id');
      
      final response = await http.patch(
        Uri.parse('$SUPABASE_URL/rest/v1/events?id=eq.${event.id}'),
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Event updated successfully!');
        await _updateSingleCache(eventToUpdate);
        return eventToUpdate;
      } else {
        print('❌ Update failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Update error: $e');
      return null;
    }
  }

  /// DELETE: Soft delete (set is_active = false)
  Future<bool> deleteEvent(String eventId) async {
    try {
      print('🗑️ Deleting event: $eventId...');
      
      final response = await http.patch(
        Uri.parse('$SUPABASE_URL/rest/v1/events?id=eq.$eventId'),
        headers: _headers,
        body: jsonEncode({'is_active': false}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Event deleted (soft)');
        
        final eventBox = Hive.box<EventModel>('events');
        final event = eventBox.get(eventId);
        if (event != null) {
          final updatedEvent = EventModel(
            id: event.id,
            title: event.title,
            description: event.description,
            imageUrl: event.imageUrl,
            organizerId: event.organizerId,
            organizerName: event.organizerName,
            organizerImageUrl: event.organizerImageUrl,
            location: event.location,
            eventStartTime: event.eventStartTime,
            eventEndTime: event.eventEndTime,
            targetVolunteerCount: event.targetVolunteerCount,
            currentVolunteerCount: event.currentVolunteerCount,
            participationFeeIdr: event.participationFeeIdr,
            category: event.category,
            isActive: false,
            createdAt: event.createdAt,
            registeredVolunteerIds: event.registeredVolunteerIds,
          );
          await eventBox.put(eventId, updatedEvent);
        }
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Delete error: $e');
      return false;
    }
  }

  // ==================== VOLUNTEER REGISTRATION ====================
  
  /// FUNGSI INI HANYA UNTUK UPDATE EVENT, BUKAN REGISTRASI PENUH
  Future<bool> incrementVolunteerCount(String eventId, String volunteerId) async {
    try {
      // 1. Ambil data event saat ini (penting untuk perhitungan yang akurat)
      final event = await getEventById(eventId); 
      if (event == null) return false;

      final updatedIds = [...event.registeredVolunteerIds];
      if (!updatedIds.contains(volunteerId)) {
        updatedIds.add(volunteerId);
      } else {
        // ID sudah ada, tidak perlu update
        return true; 
      }
      
      final newCount = event.currentVolunteerCount + 1;

      // 2. PATCH ke Supabase
      final response = await http.patch(
        Uri.parse('$SUPABASE_URL/rest/v1/events?id=eq.$eventId'),
        headers: _headers,
        body: jsonEncode({
          'current_volunteer_count': newCount, 
          'registered_volunteer_ids': updatedIds,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 3. PERBAIKAN: Update cache lokal SEGERA setelah PATCH berhasil
        final updatedEventLocally = EventModel(
          id: event.id,
          title: event.title,
          description: event.description,
          imageUrl: event.imageUrl,
          organizerId: event.organizerId,
          organizerName: event.organizerName,
          organizerImageUrl: event.organizerImageUrl,
          location: event.location,
          eventStartTime: event.eventStartTime,
          eventEndTime: event.eventEndTime,
          targetVolunteerCount: event.targetVolunteerCount,
          currentVolunteerCount: newCount, // Menggunakan count yang baru
          participationFeeIdr: event.participationFeeIdr,
          category: event.category,
          isActive: event.isActive,
          createdAt: event.createdAt,
          registeredVolunteerIds: updatedIds, // Menggunakan list ID yang baru
        );
        await _updateSingleCache(updatedEventLocally);
        
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Increment error: $e');
      return false;
    }
  }

  // FUNGSI INI DIGUNAKAN UNTUK PEMBATALAN REGISTRASI (dipanggil dari ActivityDetailPage)
  Future<bool> decrementVolunteerCount(String eventId, String volunteerId) async {
    try {
      // Dapatkan data event terbaru dari API untuk memastikan konsistensi
      final event = await getEventById(eventId); 
      if (event == null) return false;

      final updatedIds = [...event.registeredVolunteerIds];
      updatedIds.remove(volunteerId);
      
      final newCount = event.currentVolunteerCount > 0 
              ? event.currentVolunteerCount - 1 
              : 0;

      // Kirim PATCH request ke Supabase
      final response = await http.patch(
        Uri.parse('$SUPABASE_URL/rest/v1/events?id=eq.$eventId'),
        headers: _headers,
        body: jsonEncode({
          'current_volunteer_count': newCount,
          'registered_volunteer_ids': updatedIds,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Update cache lokal SEGERA setelah PATCH berhasil
        final updatedEventLocally = EventModel(
          id: event.id,
          title: event.title,
          description: event.description,
          imageUrl: event.imageUrl,
          organizerId: event.organizerId,
          organizerName: event.organizerName,
          organizerImageUrl: event.organizerImageUrl,
          location: event.location,
          eventStartTime: event.eventStartTime,
          eventEndTime: event.eventEndTime,
          targetVolunteerCount: event.targetVolunteerCount,
          currentVolunteerCount: newCount,
          participationFeeIdr: event.participationFeeIdr,
          category: event.category,
          isActive: event.isActive,
          createdAt: event.createdAt,
          registeredVolunteerIds: updatedIds,
        );
        await _updateSingleCache(updatedEventLocally);
        
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Decrement error: $e');
      return false;
    }
  }
}