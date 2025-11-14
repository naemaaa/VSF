// activity_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../models/volunteer_registration.dart';
import '../../widgets/event_map_viewer.dart';
import '../volunteer/register_volunteer_page.dart';
import 'event_participants_page.dart';
import '../../services/event_service.dart'; 


class ActivityDetailPage extends StatefulWidget {
  final EventModel event;
  final UserModel currentUser;

  const ActivityDetailPage({
    super.key,
    required this.event,
    required this.currentUser,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  // Gunakan EventService
  final EventService _eventService = EventService();
  
  final double _usdRate = 15800.0;
  final double _eurRate = 17200.0;
  String _selectedTimezone = 'WIB';
  
  String? _currentUserLat;
  String? _currentUserLng;
  String? _currentUserProvince;
  bool _locationLoading = false;
  
  // Simpan event di state untuk update status setelah register/cancel
  late EventModel _currentEvent; 

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event; // Inisialisasi dari widget
    _setCurrentUserProvince();
    _requestUserLocation();
  }

  void _setCurrentUserProvince() {
    setState(() {
      _currentUserProvince = widget.event.location.province;
    });
  }

  Future<void> _requestUserLocation() async {
    if (_locationLoading) return;
    
    setState(() => _locationLoading = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak. Aktifkan di pengaturan untuk melihat jarak.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        
        if (mounted) {
          setState(() {
            _currentUserLat = position.latitude.toString();
            _currentUserLng = position.longitude.toString();
          });
        }
      }
    } catch (e) {
      print('❌ Error getting location: $e');
    }
    
    if (mounted) {
      setState(() => _locationLoading = false);
    }
  }

  // FUNGSI UNTUK REFRESH DATA EVENT DARI API/CACHE
  Future<void> _refreshEventData(String eventId) async {
    // Memaksa refresh event dari API untuk mendapatkan data volunteer terbaru
    final updatedEvent = await _eventService.getEventById(eventId); 
    if (updatedEvent != null) {
      if (mounted) setState(() => _currentEvent = updatedEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan _currentEvent (state)
    final event = _currentEvent;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.share, color: Colors.black87),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur share coming soon')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(event),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.isFull
                              ? Colors.red[50]
                              : event.isPast
                                  ? Colors.grey[200]
                                  : Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.eventStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: event.isFull
                                ? Colors.red[600]
                                : event.isPast
                                    ? Colors.grey[600]
                                    : Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Organizer Info
                  Row(
                        children: [
                          // Organizer Avatar/Logo
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.orange[100],
                              border: Border.all(color: Colors.orange[300]!, width: 2),
                            ),
                            child: ClipOval(
                              child: widget.event.organizerImageUrl != null && 
                                      widget.event.organizerImageUrl!.isNotEmpty
                                  ? widget.event.organizerImageUrl!.startsWith('http')
                                      ? Image.network(
                                          widget.event.organizerImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.orange[100],
                                              child: Icon(
                                                Icons.business,
                                                color: Colors.orange[600],
                                                size: 24,
                                              ),
                                            );
                                          },
                                        )
                                      : Image.file(
                                          File(widget.event.organizerImageUrl!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.orange[100],
                                              child: Icon(
                                                Icons.business,
                                                color: Colors.orange[600],
                                                size: 24,
                                              ),
                                            );
                                          },
                                        )
                                  : Container(
                                      color: Colors.orange[100],
                                      child: Icon(
                                        Icons.business,
                                        color: Colors.orange[600],
                                        size: 24,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Penyelenggara',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.event.organizerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  
                  // Deskripsi
                  const Text(
                    'Deskripsi Kegiatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Waktu Kegiatan
                  const Text(
                    'Waktu Kegiatan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTimezoneChip('WIB'),
                      const SizedBox(width: 8),
                      _buildTimezoneChip('WITA'),
                      const SizedBox(width: 8),
                      _buildTimezoneChip('WIT'),
                      const SizedBox(width: 8),
                      _buildTimezoneChip('London'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTimezone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getConvertedTime(event),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                event.formattedEventDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Lokasi
                  const Text(
                    'Lokasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red[400]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                event.location.fullAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openGoogleMaps(event),
                            icon: const Icon(Icons.map),
                            label: const Text('Lihat Lokasi di Maps'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue[600],
                              side: BorderSide(color: Colors.blue[600]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Map Viewer
                  EventMapViewer(
                    event: event,
                    currentUserLat: _currentUserLat,
                    currentUserLng: _currentUserLng,
                    currentUserProvince: _currentUserProvince,
                  ),
                  const SizedBox(height: 24),
                  
                  // Harga Partisipasi
                  const Text(
                    'Harga Partisipasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCurrencyCard(
                          'IDR',
                          event.formattedPrice,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCurrencyCard(
                          'USD',
                          _convertToUSD(event),
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCurrencyCard(
                          'EUR',
                          _convertToEUR(event),
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Jumlah Volunteer
                  const Text(
                    'Jumlah Volunteer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${event.currentVolunteerCount} / ${event.targetVolunteerCount}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${event.volunteerPercentage.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: event.volunteerPercentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[600]!,
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tersisa ${event.remainingSlots} slot',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildBottomActions(event),
        ),
      ),
    );
  }

  Widget _buildBottomActions(EventModel event) {
    if (event.organizerId == widget.currentUser.id) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventParticipantsPage(
                      event: event,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.people),
              label: const Text('Lihat Peserta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: OutlinedButton.icon(
              onPressed: () => _openGoogleMaps(event),
              icon: const Icon(Icons.map),
              label: const Text('Lihat Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                side: BorderSide(color: Colors.blue[600]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    final isRegistered = event.isUserRegistered(widget.currentUser.id);
    if (isRegistered) {
      if (event.isPast) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openGoogleMaps(event),
            icon: const Icon(Icons.map),
            label: const Text('Lihat Maps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[600],
              side: BorderSide(color: Colors.blue[600]!),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        );
      }
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _confirmCancelRegistration(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Batalkan Pendaftaran', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: OutlinedButton.icon(
              onPressed: () => _openGoogleMaps(event),
              icon: const Icon(Icons.map),
              label: const Text('Lihat Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue[600],
                side: BorderSide(color: Colors.blue[600]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: event.isFull || event.isPast
            ? null
            : () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterVolunteerPage(
                      event: event,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
                // BARIS KRUSIAL: Memastikan data event di-refresh setelah pendaftaran berhasil
                if (result == true) {
                  // Panggil refresh data dari server/cache untuk memperbarui _currentEvent
                  await _refreshEventData(event.id); 
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey[300],
        ),
        child: Text(
          event.isFull
              ? 'Kuota Penuh'
              : event.isPast
                  ? 'Event Sudah Selesai'
                  : 'Daftar Volunteer',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancelRegistration(EventModel event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pendaftaran'),
        content: const Text('Apakah Anda yakin ingin membatalkan pendaftaran untuk kegiatan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );
    if (confirm == true) {
      await _cancelRegistration(event);
    }
  }

  Future<void> _cancelRegistration(EventModel event) async {
    try {
      // 1. Panggil Service untuk menghapus ID dari registeredVolunteerIds di Supabase
      final success = await _eventService.decrementVolunteerCount(event.id, widget.currentUser.id);

      if (!success) {
        throw Exception('Gagal membatalkan pendaftaran. Coba lagi.');
      }
      
      // 2. Hapus entri registrasi dari box lokal (penting untuk kebersihan data)
      final regBox = Hive.box<VolunteerRegistration>('registrations');
      dynamic foundKey;
      for (final k in regBox.keys) {
        final v = regBox.get(k);
        if (v != null && v.eventId == event.id && v.volunteerId == widget.currentUser.id) {
          foundKey = k;
          break;
        }
      }
      if (foundKey != null) await regBox.delete(foundKey);

      // 3. Refresh state di halaman detail
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftaran berhasil dibatalkan')));
        // Memuat ulang data dari server untuk memperbarui _currentEvent
        await _refreshEventData(event.id); 
      }
    } catch (e) {
      print('❌ Error canceling registration: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membatalkan pendaftaran')));
    }
  }
  
  // Widget helper
  Widget _buildOrganizerAvatar(EventModel event) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange[100],
        border: Border.all(color: Colors.orange[300]!, width: 2),
      ),
      child: ClipOval(
        child: (event.organizerImageUrl != null && event.organizerImageUrl!.isNotEmpty)
            ? (event.organizerImageUrl!.startsWith('http')
                ? Image.network(
                    event.organizerImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _defaultOrganizerIcon(),
                  )
                : Image.file(
                    File(event.organizerImageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _defaultOrganizerIcon(),
                  ))
            : _defaultOrganizerIcon(),
      ),
    );
  }

  Widget _defaultOrganizerIcon() {
    return Container(
      color: Colors.orange[100],
      child: Icon(
        Icons.business,
        color: Colors.orange[600],
        size: 24,
      ),
    );
  }

  Widget _buildTimezoneChip(String timezone) {
    final isSelected = _selectedTimezone == timezone;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTimezone = timezone);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          timezone,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage(EventModel event) {
    final url = event.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 80)),
      );
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image, size: 80)),
        ),
      );
    }

    try {
      final file = File(url);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image, size: 80)),
        ),
      );
    } catch (_) {
      return Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 80)),
      );
    }
  }

  String _getConvertedTime(EventModel event) {
    int offsetHours = 0;
    switch (_selectedTimezone) {
      case 'WIB':
        offsetHours = 7;
        break;
      case 'WITA':
        offsetHours = 8;
        break;
      case 'WIT':
        offsetHours = 9;
        break;
      case 'London':
        offsetHours = 0; 
        break;
    }
    final startUtc = event.eventStartTime.toUtc();
    final endUtc = event.eventEndTime.toUtc();
    final convertedStart = startUtc.add(Duration(hours: offsetHours));
    final convertedEnd = endUtc.add(Duration(hours: offsetHours));
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(convertedStart)} - ${formatter.format(convertedEnd)}';
  }

  Widget _buildCurrencyCard(String currency, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            currency,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _convertToUSD(EventModel event) {
    if (event.isFree) return 'Free';
    final usd = event.participationFeeIdr / _usdRate;
    return '\$${usd.toStringAsFixed(2)}';
  }

  String _convertToEUR(EventModel event) {
    if (event.isFree) return 'Free';
    final eur = event.participationFeeIdr / _eurRate;
    return '€${eur.toStringAsFixed(2)}';
  }

  Future<void> _openGoogleMaps(EventModel event) async {
    final lat = event.location.latitude;
    final lng = event.location.longitude;
    
    // Pastikan koordinat valid sebelum membuat URI
    if (lat == 0 && lng == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Koordinat lokasi tidak ditemukan.')),
        );
      }
      return;
    }

    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'; // Menggunakan format yang benar
    final uri = Uri.parse(googleMapsUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
        );
      }
    }
  }
}