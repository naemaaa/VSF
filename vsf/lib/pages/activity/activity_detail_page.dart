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
import '../../services/timezone_service.dart'; 
import '../volunteer/register_volunteer_page.dart';
import 'event_participants_page.dart';

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
  final double _usdRate = 15800.0;
  final double _eurRate = 17200.0;
  String _selectedTimezone = 'WIB'; // ✅ ADD THIS
  
  String? _currentUserLat;
  String? _currentUserLng;
  String? _currentUserProvince;
  bool _locationLoading = false;

  late EventModel _localEvent;
  late bool _isUserRegistered;
  
  UserModel? _organizerUser;
  bool _loadingOrganizerImage = true;

  @override
  void initState() {
    super.initState();
    _localEvent = widget.event;
    _refreshRegistrationStatus();
    _setCurrentUserProvince();
    _requestUserLocation();
    _loadOrganizerImage();
    _selectedTimezone = 'WIB';
    
    // ✅ ADD THIS: Debug timezone info
    print('═══════════════════════════════════════');
    print('🎯 Activity Detail Page Opened');
    print('═══════════════════════════════════════');
    TimezoneHelper.debugPrintTimezoneInfo();
    
    print('📍 Event Time Info:');
    print('   Stored (UTC): ${_localEvent.eventStartTime}');
    print('   Display (WIB): ${TimezoneHelper.utcToLocalWIB(_localEvent.eventStartTime)}');
    print('═══════════════════════════════════════\n');
  }

  @override
  void didUpdateWidget(ActivityDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != widget.event.id) {
      setState(() {
        _localEvent = widget.event;
        _refreshRegistrationStatus();
        _loadOrganizerImage();
      });
    }
  }

  void _loadOrganizerImage() async {
    setState(() => _loadingOrganizerImage = true);
    
    try {
      final userBox = Hive.box<UserModel>('users');
      
      UserModel? organizer;
      for (var user in userBox.values) {
        if (user.id == _localEvent.organizerId) {
          organizer = user;
          break;
        }
      }
      
      if (organizer != null) {
        print('✅ Organizer found: ${organizer.displayName}');
        print('   Profile image: ${organizer.profileImagePath}');
        
        setState(() {
          _organizerUser = organizer;
          _loadingOrganizerImage = false;
        });
      } else {
        print('⚠️ Organizer not found in Hive');
        setState(() => _loadingOrganizerImage = false);
      }
    } catch (e) {
      print('❌ Error loading organizer: $e');
      setState(() => _loadingOrganizerImage = false);
    }
  }

  void _refreshRegistrationStatus() {
    final eventBox = Hive.box<EventModel>('events');
    final latestEvent = eventBox.get(_localEvent.id);
    
    if (latestEvent != null) {
      _isUserRegistered = latestEvent.isUserRegistered(widget.currentUser.id);
      if (mounted) {
        setState(() {
          _localEvent = latestEvent;
        });
      }
    } else {
      _isUserRegistered = _localEvent.isUserRegistered(widget.currentUser.id);
    }
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

  // ✅ NEW METHOD: Convert UTC to selected timezone
  String _getConvertedTime(EventModel event) {
    // Event.eventStartTime sudah dalam UTC (dari database)
    final startTimeInTargetTZ = TimezoneHelper.convertUTCToTimezone(
      event.eventStartTime,
      _selectedTimezone,
    );
    final endTimeInTargetTZ = TimezoneHelper.convertUTCToTimezone(
      event.eventEndTime,
      _selectedTimezone,
    );

    final formatter = DateFormat('HH:mm');
    final startStr = formatter.format(startTimeInTargetTZ);
    final endStr = formatter.format(endTimeInTargetTZ);
    
    print('🕐 Time conversion:');
    print('   Selected timezone: $_selectedTimezone');
    print('   Start (UTC): ${event.eventStartTime}');
    print('   Start ($_selectedTimezone): $startTimeInTargetTZ');
    print('   Time range: $startStr - $endStr');
    
    return '$startStr - $endStr';
  }

  // ✅ NEW METHOD: Build timezone chip
  Widget _buildTimezoneChip(String timezone) {
    final isSelected = _selectedTimezone == timezone;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTimezone = timezone);
        print('🌍 Timezone changed to: $timezone');
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

  // ✅ NEW METHOD: Get timezone offset
  int _getTimezoneOffset(String timezone) {
    final offsets = {
      'WIB': 7,
      'WITA': 8,
      'WIT': 9,
      'London': 0,
    };
    return offsets[timezone] ?? 7;
  }

  @override
  Widget build(BuildContext context) {
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
              background: _buildHeaderImage(),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                              _localEvent.category,
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
                              color: _localEvent.isFull
                                  ? Colors.red[50]
                                  : _localEvent.isPast
                                      ? Colors.grey[200]
                                      : Colors.green[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _localEvent.eventStatus,
                              style: TextStyle(
                                fontSize: 12,
                                color: _localEvent.isFull
                                    ? Colors.red[600]
                                    : _localEvent.isPast
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
                        _localEvent.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildOrganizerCard(),
                      
                      const SizedBox(height: 24),
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
                        _localEvent.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Waktu Kegiatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // ✅ TIMEZONE SELECTOR
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
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
                      ),
                      const SizedBox(height: 12),
                      
                  
                      
                      // ✅ TIME DISPLAY
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
                                    _getConvertedTime(_localEvent),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _localEvent.formattedEventDate,
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
                                    _localEvent.location.fullAddress,
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
                                onPressed: _openGoogleMaps,
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
                      EventMapViewer(
                        event: _localEvent,
                        currentUserLat: _currentUserLat,
                        currentUserLng: _currentUserLng,
                        currentUserProvince: _currentUserProvince,
                      ),
                      const SizedBox(height: 24),
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
                              _localEvent.formattedPrice,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCurrencyCard(
                              'USD',
                              _convertToUSD(),
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCurrencyCard(
                              'EUR',
                              _convertToEUR(),
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                                  '${_localEvent.currentVolunteerCount} / ${_localEvent.targetVolunteerCount}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_localEvent.volunteerPercentage.toStringAsFixed(0)}%',
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
                              value: _localEvent.volunteerPercentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue[600]!,
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tersisa ${_localEvent.remainingSlots} slot',
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
              ],
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
          child: _buildBottomActions(),
        ),
      ),
    );
  }

  Widget _buildOrganizerCard() {
    if (_loadingOrganizerImage) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Penyelenggara',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orange[200],
              border: Border.all(color: Colors.orange[400]!, width: 2),
            ),
            child: ClipOval(
              child: _organizerUser != null && 
                  _organizerUser!.profileImagePath != null &&
                  _organizerUser!.profileImagePath!.isNotEmpty
                  ? _buildOrganizerImage()
                  : _buildOrganizerInitials(),
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
                const SizedBox(height: 4),
                Text(
                  _localEvent.organizerName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizerImage() {
    final imagePath = _organizerUser!.profileImagePath;
    
    if (imagePath == null || imagePath.isEmpty) {
      return _buildOrganizerInitials();
    }

    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildOrganizerInitials();
        },
      );
    }

    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildOrganizerInitials();
          },
        );
      }
    } catch (e) {
      print('Error loading image: $e');
    }

    return _buildOrganizerInitials();
  }

  Widget _buildOrganizerInitials() {
    String initials = 'O';
    
    if (_organizerUser != null) {
      initials = _organizerUser!.initials;
    } else if (_localEvent.organizerName.isNotEmpty) {
      final parts = _localEvent.organizerName.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty) {
        initials = parts[0].substring(0, 1).toUpperCase();
      }
    }

    return Container(
      color: Colors.orange[200],
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange[800],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    if (widget.event.organizerId == widget.currentUser.id) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventParticipantsPage(
                      event: _localEvent,
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
              onPressed: _openGoogleMaps,
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

    if (_isUserRegistered) {
      if (_localEvent.isPast) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openGoogleMaps,
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
              onPressed: _confirmCancelRegistration,
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
              onPressed: _openGoogleMaps,
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
        onPressed: _localEvent.isFull || _localEvent.isPast
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegisterVolunteerPage(
                      event: _localEvent,
                      currentUser: widget.currentUser,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        _refreshRegistrationStatus();
                      }
                    });
                  }
                });
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
          _localEvent.isFull
              ? 'Kuota Penuh'
              : _localEvent.isPast
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

  Future<void> _confirmCancelRegistration() async {
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
      await _cancelRegistration();
    }
  }

  Future<void> _cancelRegistration() async {
    try {
      final regBox = Hive.box<VolunteerRegistration>('registrations');
      final eventBox = Hive.box<EventModel>('events');
      
      final regEntry = regBox.values.firstWhere(
        (r) => r.eventId == _localEvent.id && r.volunteerId == widget.currentUser.id,
        orElse: () => throw Exception('Registration not found'),
      );
      
      dynamic foundKey;
      for (final k in regBox.keys) {
        final v = regBox.get(k);
        if (v == regEntry) {
          foundKey = k;
          break;
        }
      }
      
      if (foundKey != null) await regBox.delete(foundKey);
      
      final event = eventBox.get(_localEvent.id) ?? _localEvent;
      event.removeVolunteer(widget.currentUser.id);
      await eventBox.put(event.id, event);
      
      if (mounted) {
        setState(() {
          _localEvent = event;
          _isUserRegistered = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pendaftaran berhasil dibatalkan')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membatalkan pendaftaran')),
        );
      }
    }
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

  String _convertToUSD() {
    if (_localEvent.isFree) return 'Free';
    final usd = _localEvent.participationFeeIdr / _usdRate;
    return '\${usd.toStringAsFixed(2)}';
  }

  String _convertToEUR() {
    if (_localEvent.isFree) return 'Free';
    final eur = _localEvent.participationFeeIdr / _eurRate;
    return '€${eur.toStringAsFixed(2)}';
  }

  Future<void> _openGoogleMaps() async {
    try {
      final lat = _localEvent.location.latitude;
      final lng = _localEvent.location.longitude;
      
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      
      final uri = Uri.parse(googleMapsUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
        final mapsUri = Uri.parse(mapsUrl);
        
        if (await canLaunchUrl(mapsUri)) {
          await launchUrl(
            mapsUri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tidak dapat membuka Google Maps.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error opening maps: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildHeaderImage() {
    final url = widget.event.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 80),
      );
    }

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 80),
          );
        },
      );
    }

    try {
      final file = File(url);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.image, size: 80),
          );
        },
      );
    } catch (_) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 80),
      );
    }
  }
}