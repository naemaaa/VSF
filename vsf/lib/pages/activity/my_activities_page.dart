import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../models/volunteer_registration.dart';
import '../../services/event_service.dart';
import 'activity_detail_page.dart';

class MyActivitiesPage extends StatefulWidget {
  final UserModel currentUser;

  const MyActivitiesPage({super.key, required this.currentUser});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;
  List<EventModel> _registeredEvents = [];
  List<VolunteerRegistration> _registrations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRegisteredEvents();
  }

  bool _isUserStillRegistered(EventModel event) {
    return event.registeredVolunteerIds.contains(widget.currentUser.id);
  }

  // ⬅️ PERBAIKAN: Refresh dari API + Cache
  Future<void> _loadRegisteredEvents() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Loading registered events for user: ${widget.currentUser.id}');
      
      final registrationBox = Hive.box<VolunteerRegistration>('registrations');
      final eventBox = Hive.box<EventModel>('events');

      // Get all registrations for current user
      _registrations = registrationBox.values
          .where((reg) => reg.volunteerId == widget.currentUser.id)
          .toList();

      print('📋 Found ${_registrations.length} registrations in Hive');

      // Refresh events from API
      await _eventService.getAllEvents(forceRefresh: true);

      // Get corresponding events
      _registeredEvents = _registrations
          .map((reg) {
            final event = eventBox.get(reg.eventId);
            print('Event ${reg.eventId}: ${event != null ? "found" : "NOT FOUND"}');
            return event;
          })
          .whereType<EventModel>()
          .toList();

      print('✅ Loaded ${_registeredEvents.length} events');
    } catch (e) {
      print('❌ Error loading registered events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ⬅️ PERBAIKAN: Refresh saat kembali ke halaman
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRegisteredEvents();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildSmallEventImage(EventModel event) {
    final url = event.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image, size: 32),
      );
    }

    if (url.startsWith('http') || url.startsWith('https')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    }

    try {
      final file = File(url);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
        );
      }
    } catch (_) {}

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, size: 32),
    );
  }

  Widget _buildEventCard(EventModel event, VolunteerRegistration registration) {
    final bool isCompleted = event.isPast;

    return GestureDetector(
      onTap: () async {
        // Navigate dan refresh saat kembali
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailPage(
              event: event,
              currentUser: widget.currentUser,
            ),
          ),
        );
        // Refresh setelah kembali
        _loadRegisteredEvents();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildSmallEventImage(event),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.formattedEventDate,
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location.shortAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (isCompleted && !registration.hasFeedback)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          // TODO: Implement feedback dialog
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange[50],
                          foregroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Beri Feedback'),
                      ),
                    )
                  else if (isCompleted && registration.hasFeedback)
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Selesai',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ActivityDetailPage(
                                event: event,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                          _loadRegisteredEvents();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingEvents = _registeredEvents.where((e) => !e.isPast).toList();
    final pastEvents = _registeredEvents.where((e) => e.isPast).toList();

    upcomingEvents.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
    pastEvents.sort((a, b) => b.eventStartTime.compareTo(a.eventStartTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegisteredEvents,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Mendatang (${upcomingEvents.length})'),
            Tab(text: 'Riwayat (${pastEvents.length})'),
          ],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Events Tab
                upcomingEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_available,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada aktivitas mendatang',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRegisteredEvents,
                        child: ListView.builder(
                          itemCount: upcomingEvents.length,
                          itemBuilder: (context, index) {
                            final event = upcomingEvents[index];
                            final registration = _registrations.firstWhere(
                                (r) => r.eventId == event.id);
                            return _buildEventCard(event, registration);
                          },
                        ),
                      ),

                // Past Events Tab
                pastEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada riwayat aktivitas',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRegisteredEvents,
                        child: ListView.builder(
                          itemCount: pastEvents.length,
                          itemBuilder: (context, index) {
                            final event = pastEvents[index];
                            final registration = _registrations.firstWhere(
                                (r) => r.eventId == event.id);
                            return _buildEventCard(event, registration);
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}