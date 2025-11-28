// =====================================================
// MY ACTIVITIES PAGE REDESIGN (vsf/lib/pages/activity/my_activities_page.dart)
// =====================================================

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../models/volunteer_registration.dart';
import '../../services/event_service.dart';
import 'activity_detail_page.dart';
import '../payment/payment_page.dart';

class MyActivitiesPage extends StatefulWidget {
  final UserModel currentUser;

  const MyActivitiesPage({super.key, required this.currentUser});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage>
    with SingleTickerProviderStateMixin {
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

  Future<void> _loadRegisteredEvents() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final registrationBox = Hive.box<VolunteerRegistration>('registrations');
      final eventBox = Hive.box<EventModel>('events');

      _registrations = registrationBox.values
          .where((reg) => reg.volunteerId == widget.currentUser.id)
          .toList();

      await _eventService.getAllEvents(forceRefresh: true);

      _registeredEvents = _registrations
          .map((reg) {
            final event = eventBox.get(reg.eventId);
            return event;
          })
          .whereType<EventModel>()
          .toList();

    } catch (e) {
      print('❌ Error loading registered events: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image, size: 32),
      );
    }

    if (url.startsWith('http') || url.startsWith('https')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 90, height: 90, fit: BoxFit.cover),
        );
      }
    } catch (_) {}

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, size: 32),
    );
  }

  Widget _buildEventCard(EventModel event, VolunteerRegistration registration) {
    final bool isCompleted = event.isPast;
    final bool isPaid = registration.isPaid;

    return GestureDetector(
      onTap: () async {
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Event Image with Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: _buildSmallEventImage(event),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted ? Colors.grey[600] : Colors.blue[600],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted ? 'Selesai' : 'Berlangsung',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date & Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.formattedEventDate,
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.shortAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Payment Status
                  if (!isPaid && !isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: Colors.orange[700]),
                          const SizedBox(width: 6),
                          Text(
                            '⏳ Belum Dibayar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.green[300]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 6),
                          Text(
                            '✅ Sudah Dibayar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: isCompleted && !registration.hasFeedback
                        ? ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement feedback dialog
                            },
                            icon: const Icon(Icons.message, size: 16),
                            label: const Text('Beri Feedback'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[50],
                              foregroundColor: Colors.orange[700],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          )
                        : isCompleted && registration.hasFeedback
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 16, color: Colors.green[600]),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Feedback Terkirim',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : !isPaid && !isCompleted
                                ? ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PaymentPage(
                                            registration: registration,
                                            event: event,
                                            selectedCurrency:
                                                registration.paymentCurrency ?? 'IDR',
                                          ),
                                        ),
                                      );
                                      _loadRegisteredEvents();
                                    },
                                    icon: const Icon(Icons.payment, size: 16),
                                    label: const Text('Lanjutkan Pembayaran'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber[50],
                                      foregroundColor: Colors.amber[700],
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  )
                                : ElevatedButton.icon(
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
                                    icon: const Icon(Icons.info_outline, size: 16),
                                    label: const Text('Lihat Detail'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[50],
                                      foregroundColor: Colors.blue[700],
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Aktivitas Saya',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _loadRegisteredEvents,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_note, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Mendatang (${upcomingEvents.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Riwayat (${pastEvents.length})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 13,
          ),
          labelColor: Colors.blue[600],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[600],
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
                          padding: const EdgeInsets.all(16),
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
                          padding: const EdgeInsets.all(16),
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