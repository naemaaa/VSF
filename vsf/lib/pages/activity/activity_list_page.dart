import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import 'activity_detail_page.dart';

class ActivityListPage extends StatefulWidget {
  final UserModel currentUser;

  const ActivityListPage({super.key, required this.currentUser});

  @override
  State<ActivityListPage> createState() => _ActivityListPageState();
}



class _ActivityListPageState extends State<ActivityListPage> {
  final _searchController = TextEditingController();
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  String _selectedCategory = 'Semua';
  String _selectedLocation = 'Semua';
  String _selectedDistance = 'Semua';
  
  double? _userLat;
  double? _userLng;
  bool _loadingLocation = false;
  
  final LocationService _locationService = LocationService();
  final String _selectedCurrency = 'IDR';  

  final Map<String, double> _exchangeRates = {  
    'IDR': 1.0,
    'USD': 15800.0,
    'EUR': 17200.0,
  };

  final List<String> _categories = [
    'Semua',
    'Pendidikan',
    'Lingkungan',
    'Kesehatan',
    'Sosial',
    'Anak-anak'
  ];

  final List<String> _locations = [
    'Semua',
    'DKI Jakarta',
    'Jawa Barat',
    'Jawa Tengah',
    'Jawa Timur',
    'Banten',
    'Aceh',
    'Sumatera Utara',
    'Sumatera Barat',
    'Riau',
    'Jambi',
    'Sumatera Selatan' ,
    'Kalimantan Barat',
    'Kalimantan Tengah',
    'Kalimantan Selatan',
    'Kalimantan Timur',
    'Kalimantan Utara',
    'Sulawesi Utara',
    'Sulawesi Tengah',
    'Sulawesi Selatan',
    'Sulawesi Tenggara',
    'Gorontalo',
    'Sulawesi Barat',
    'Maluku',
    'Maluku Utara',
    'Papua',
    'Papua Barat',
    'Papua Tengah',
    'Papua Pegunungan',
    'Nusa Tenggara Barat',
    'Nusa Tenggara Timur',
    'Yogyakarta',
    'Bengkulu',
    'Kepulauan Riau',
  ];

  final List<String> _distanceOptions = ['Semua', 'Terdekat', 'Terjauh'];

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_filterEvents);
    _getUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() => _loadingLocation = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          print('📍 User location: $_userLat, $_userLng');
        });
        _filterEvents();
      }
    } catch (e) {
      print('⚠️ Error getting location: $e');
    }
    
    if (mounted) {
      setState(() => _loadingLocation = false);
    }
  }

  void _loadEvents() {
    final eventBox = Hive.box<EventModel>('events');
    setState(() {
      // ✅ PERBAIKAN: Ambil SEMUA event (termasuk yang isPast)
      _allEvents = eventBox.values
          .where((event) => event.isActive)
          .toList();
      _filterEvents();
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    
    var filtered = _allEvents.where((event) {
      // Filter by search query
      final matchesQuery = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.description.toLowerCase().contains(query) ||
          event.location.city.toLowerCase().contains(query);

      // Filter by category
      final matchesCategory = _selectedCategory == 'Semua' ||
          event.category == _selectedCategory;

      // Filter by location
      final matchesLocation = _selectedLocation == 'Semua' ||
          event.location.province == _selectedLocation;

      return matchesQuery && matchesCategory && matchesLocation;
    }).toList();

    // ✅ PERBAIKAN: Sort dengan prioritas
    filtered.sort((a, b) {
      // Prioritas 1: Event yang belum selesai (isPast = false) lebih atas
      final aIsPast = a.isPast ? 1 : 0;
      final bIsPast = b.isPast ? 1 : 0;
      
      if (aIsPast != bIsPast) {
        return aIsPast.compareTo(bIsPast);
      }
      
      // Prioritas 2 (dalam kategori yang sama): Event tidak penuh lebih atas
      final aIsFull = a.isFull ? 1 : 0;
      final bIsFull = b.isFull ? 1 : 0;
      
      if (aIsFull != bIsFull) {
        return aIsFull.compareTo(bIsFull);
      }
      
      // Prioritas 3: Urutkan berdasarkan jarak
      if (_userLat != null && _userLng != null) {
        final distA = _locationService.calculateDistance(
          _userLat!,
          _userLng!,
          a.location.latitude,
          a.location.longitude,
        );
        
        final distB = _locationService.calculateDistance(
          _userLat!,
          _userLng!,
          b.location.latitude,
          b.location.longitude,
        );
        
        if (_selectedDistance == 'Terdekat') {
          return distA.compareTo(distB);
        } else if (_selectedDistance == 'Terjauh') {
          return distB.compareTo(distA);
        }
      }
      
      // Default: Urutkan berdasarkan tanggal mulai
      return a.eventStartTime.compareTo(b.eventStartTime);
    });

    setState(() {
      _filteredEvents = filtered;
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: 0.7,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              controller: scrollController,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Kegiatan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'Semua';
                          _selectedLocation = 'Semua';
                          _selectedDistance = 'Semua';
                        });
                        setModalState(() {});
                        _filterEvents();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ✅ PERBAIKAN: Filter Jarak
                const Text(
                  'Urutkan Berdasarkan Jarak',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_userLat != null && _userLng != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _distanceOptions.map((distance) {
                      final isSelected = _selectedDistance == distance;
                      return FilterChip(
                        label: Text(distance),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDistance = distance;
                          });
                          setModalState(() {});
                          _filterEvents();
                        },
                        backgroundColor: Colors.grey[100],
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue[600],
                      );
                    }).toList(),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_off, color: Colors.orange[600], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aktifkan lokasi untuk filter berdasarkan jarak',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Kategori Filter
                const Text(
                  'Kategori',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        setModalState(() {});
                        _filterEvents();
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Colors.blue[100],
                      checkmarkColor: Colors.blue[600],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Lokasi Filter
                const Text(
                  'Lokasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLocation,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: _locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLocation = value;
                      });
                      setModalState(() {});
                      _filterEvents();
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Apply Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDistanceText(EventModel event) {
    if (_userLat == null || _userLng == null) {
      return '';
    }
    
    final distance = _locationService.calculateDistance(
      _userLat!,
      _userLng!,
      event.location.latitude,
      event.location.longitude,
    );
    
    return _locationService.formatDistance(distance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Daftar Aktivitas',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kegiatan...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: _showFilterBottomSheet,
                  ),
                ),
              ],
            ),
          ),

          // Active Filters Chips
          if (_selectedCategory != 'Semua' || _selectedLocation != 'Semua' || _selectedDistance != 'Semua')
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCategory != 'Semua')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedCategory),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() => _selectedCategory = 'Semua');
                            _filterEvents();
                          },
                          backgroundColor: Colors.blue[50],
                          labelStyle: TextStyle(color: Colors.blue[600]),
                        ),
                      ),
                    if (_selectedLocation != 'Semua')
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedLocation),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() => _selectedLocation = 'Semua');
                            _filterEvents();
                          },
                          backgroundColor: Colors.green[50],
                          labelStyle: TextStyle(color: Colors.green[600]),
                        ),
                      ),
                    if (_selectedDistance != 'Semua')
                      Chip(
                        label: Text(_selectedDistance),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _selectedDistance = 'Semua');
                          _filterEvents();
                        },
                        backgroundColor: Colors.purple[50],
                        labelStyle: TextStyle(color: Colors.purple[600]),
                      ),
                  ],
                ),
              ),
            ),

          // Results Count & Location Status
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredEvents.length} kegiatan ditemukan',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                if (_loadingLocation)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(Colors.blue[400]),
                    ),
                  )
                else if (_userLat != null && _userLng != null)
                  Tooltip(
                    message: 'Lokasi aktif',
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.green[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Jarak aktif',
                          style: TextStyle(fontSize: 11, color: Colors.green[600]),
                        ),
                      ],
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.location_off, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Jarak tidak tersedia',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Event List
          Expanded(
            child: _filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada kegiatan ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _loadEvents();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        return _buildEventCard(event);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final distanceText = _getDistanceText(event);
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActivityDetailPage(
              event: event,
              currentUser: widget.currentUser,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Stack(
                children: [
                  _buildEventImage(event),
                  
                  // Status Badge (Tersedia/Penuh/Selesai)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: event.isPast
                            ? Colors.grey
                            : event.isFull
                                ? Colors.red
                                : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.eventStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Distance Badge
                  if (distanceText.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[600],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.shortAddress,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedEventDate,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Volunteers & Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Volunteers
                      Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${event.currentVolunteerCount}/${event.targetVolunteerCount}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.isFree ? Colors.green[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.formattedPrice,
                          style: TextStyle(
                            fontSize: 12,
                            color: event.isFree ? Colors.green[600] : Colors.orange[600],
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildEventImage(EventModel event) {
    final url = event.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        height: 160,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 64),
      );
    }

    if (url.startsWith('http') || url.startsWith('https')) {
      return Image.network(
        url,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 160,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 64),
        ),
      );
    }

    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(file, height: 160, width: double.infinity, fit: BoxFit.cover);
      } else {
        return Container(
          height: 160,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, size: 64),
        );
      }
    } catch (e) {
      return Container(
        height: 160,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 64),
      );
    }
  }
}