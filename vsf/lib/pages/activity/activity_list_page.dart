import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import '../../models/event_model.dart';
import '../../models/user_model.dart';
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
  String _selectedCurrency = 'IDR';  

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

  double _convertPrice(int priceIDR, String toCurrency) {
  if (toCurrency == 'IDR') return priceIDR.toDouble();
  final rate = _exchangeRates[toCurrency] ?? 1.0;
  return priceIDR / rate;
  }

  String _formatCurrency(double amount, String currency) {
    switch (currency) {
      case 'IDR':
        return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      default:
        return amount.toStringAsFixed(2);
    }
  }


  @override
  void initState() {
    super.initState();
    _loadEvents();
    _searchController.addListener(_filterEvents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadEvents() {
    final eventBox = Hive.box<EventModel>('events');
    setState(() {
      _allEvents = eventBox.values.toList();
      _filteredEvents = _allEvents;
    });
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
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
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      });
                      setModalState(() {});
                      _filterEvents();
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
              const SizedBox(height: 24),

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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Daftar Akt',
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
          if (_selectedCategory != 'Semua' || _selectedLocation != 'Semua')
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
                      Chip(
                        label: Text(_selectedLocation),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() => _selectedLocation = 'Semua');
                          _filterEvents();
                        },
                        backgroundColor: Colors.green[50],
                        labelStyle: TextStyle(color: Colors.green[600]),
                      ),
                  ],
                ),
              ),
            ),

          // Results Count
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            child: Text(
              '${_filteredEvents.length} kegiatan ditemukan',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
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
                  // Status Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: event.isFull
                            ? Colors.red
                            : event.isPast
                                ? Colors.grey
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

    // If looks like remote URL, use network
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

    // Treat as local file path
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