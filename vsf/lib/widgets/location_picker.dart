import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// PERBAIKAN: Pastikan email kontak Anda valid.
const String NOMINATIM_USER_AGENT = 'VSF-App/1.0 (contact:naimatululumiyah89@example.com)';

// --- DATA KOORDINAT PROVINSI DAN KOTA (Tidak Diubah) ---
final Map<String, LatLng> PROVINCE_CENTER = {
  'DKI Jakarta': LatLng(-6.2088, 106.8456),
  'Jawa Barat': LatLng(-6.9175, 107.6019),
  'Jawa Tengah': LatLng(-7.1957, 110.4038),
  'Jawa Timur': LatLng(-7.5506, 112.7469),
  'Banten': LatLng(-6.4074, 106.1496),
  'Aceh': LatLng(4.6951, 96.7494),
  'Sumatera Utara': LatLng(2.1945, 99.2539),
  'Sumatera Barat': LatLng(-0.9674, 100.4172),
  'Riau': LatLng(0.2934, 101.6964),
  'Jambi': LatLng(-1.6338, 102.7308),
  'Sumatera Selatan': LatLng(-3.7957, 104.7520),
  'Kalimantan Barat': LatLng(-0.0263, 109.3425),
  'Kalimantan Tengah': LatLng(-1.6735, 113.5006),
  'Kalimantan Selatan': LatLng(-3.7669, 114.5897),
  'Kalimantan Timur': LatLng(0.5306, 116.0753),
  'Kalimantan Utara': LatLng(3.0700, 115.2833),
  'Sulawesi Utara': LatLng(1.5029, 124.8754),
  'Sulawesi Tengah': LatLng(-1.4286, 119.8596),
  'Sulawesi Selatan': LatLng(-3.6957, 119.9753),
  'Sulawesi Tenggara': LatLng(-4.0377, 122.1998),
  'Gorontalo': LatLng(0.6971, 122.4467),
  'Sulawesi Barat': LatLng(-2.1239, 119.2321),
  'Maluku': LatLng(-3.1956, 129.1834),
  'Maluku Utara': LatLng(1.5709, 127.7649),
  'Papua': LatLng(-3.5898, 141.8969),
  'Papua Barat': LatLng(-0.8789, 131.2718),
  'Papua Tengah': LatLng(-3.5898, 138.0827),
  'Papua Pegunungan': LatLng(-4.0288, 138.8003),
  'Nusa Tenggara Barat': LatLng(-8.6500, 117.4250),
  'Nusa Tenggara Timur': LatLng(-8.6705, 120.4567),
  'Yogyakarta': LatLng(-7.7956, 110.3695),
  'Bengkulu': LatLng(-3.7957, 102.2381),
  'Kepulauan Riau': LatLng(1.0910, 104.6206),
};

final Map<String, LatLng> CITY_COORDINATES = {
  'Surabaya': LatLng(-7.2505, 112.7581),
  'Malang': LatLng(-7.9797, 112.6304),
  'Bandung': LatLng(-6.9175, 107.6019),
  'Semarang': LatLng(-6.9932, 110.4203),
  'Jakarta Pusat': LatLng(-6.1944, 106.8294),
};
// -------------------------------------------------------------------

class LocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final void Function(LatLng) onLocationPicked;
  final String? selectedCity;
  final String? selectedProvince;

  const LocationPicker({
    super.key,
    this.initialLocation,
    required this.onLocationPicked,
    this.selectedCity,
    this.selectedProvince,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  double _currentZoom = 11.0;
  
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  
  Timer? _debounceTimer;
  
  static const String MAPBOX_ACCESS_TOKEN = 'REDACTED_MAPBOX_TOKEN';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    
    if (widget.selectedCity != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _moveToCity(widget.selectedCity!);
      });
    } else if (widget.selectedProvince != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _moveToProvince(widget.selectedProvince!);
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.selectedCity != widget.selectedCity && 
        widget.selectedCity != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _moveToCity(widget.selectedCity!);
      });
    }
    
    if (oldWidget.selectedProvince != widget.selectedProvince && 
        widget.selectedProvince != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _moveToProvince(widget.selectedProvince!);
      });
    }
  }

  void _moveToCity(String city) {
    final coordinates = CITY_COORDINATES[city];
    if (coordinates != null) {
      _mapController.move(coordinates, 13.0);
      setState(() => _currentZoom = 13.0);
    }
  }

  void _moveToProvince(String province) {
    final center = PROVINCE_CENTER[province];
    if (center != null) {
      _mapController.move(center, 10.0);
      setState(() => _currentZoom = 10.0);
    }
  }

  String? _getBboxForProvince(String? province) {
    if (province == null) return null;
    
    final center = PROVINCE_CENTER[province];
    if (center == null) return null;
    
    // Memberi batas 3 derajat di sekitar pusat provinsi
    final south = center.latitude - 1.5;
    final west = center.longitude - 1.5;
    final north = center.latitude + 1.5;
    final east = center.longitude + 1.5;
    
    return '$west,$south,$east,$north';
  }

  bool _isPointInBbox(double lat, double lng, String? bbox) {
    if (bbox == null) return true;
    
    try {
      final parts = bbox.split(',').map(double.parse).toList();
      if (parts.length != 4) return true;
      
      final west = parts[0];
      final south = parts[1];
      final east = parts[2];
      final north = parts[3];
      
      return lng >= west && lng <= east && lat >= south && lat <= north;
    } catch (e) {
      return true;
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _searchLocation(query);
    });
    
    // Show loading indicator
    setState(() => _isSearching = true);
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    print('🔍 Searching: "$query"');
    
    try {
      // Build search query dengan province
      String searchQuery = query.trim();
      if (widget.selectedProvince != null) {
        // Query disetel menjadi "kata kunci, Nama Provinsi, Indonesia"
        searchQuery = '$query, ${widget.selectedProvince}, Indonesia';
      } else {
        searchQuery = '$query, Indonesia';
      }
      final encodedSearch = Uri.encodeComponent(searchQuery);
      
      final String? bbox = _getBboxForProvince(widget.selectedProvince);
      if (bbox != null) print('   Bbox: $bbox');

      final List<Map<String, dynamic>> results = [];
      
      // OpenStreetMap Nominatim API
      final String nominatimUrl =
          'https://nominatim.openstreetmap.org/search'
          '?q=$encodedSearch'
          '&format=jsonv2' // ✅ PERBAIKAN: Menggunakan format modern
          '&limit=15'
          '&countrycodes=id'
          '&addressdetails=1'
          '&extratags=1';

      print('   Fetching from OSM Nominatim: $nominatimUrl');

      final response = await http.get(
        Uri.parse(nominatimUrl),
        headers: {
          'User-Agent': NOMINATIM_USER_AGENT, // ✅ PERBAIKAN: Menggunakan User-Agent lengkap
          'Accept-Language': 'id,en',
        },
      ).timeout(
        const Duration(seconds: 15), // ✅ PERBAIKAN: Timeout diperpanjang
        onTimeout: () {
          print('   ⏱️ TIMEOUT after 15 seconds (Status 408)');
          // Mengembalikan respons 408 saat timeout
          return http.Response('[]', 408);
        },
      );
      
      print('   Response: ${response.statusCode}');

      // 🛑 PERBAIKAN KRUSIAL: Tangani Status Code non-200
      if (response.statusCode != 200) {
        print('   ❌ API Error: ${response.statusCode}');
        if (mounted) {
            setState(() {
                _searchResults = [];
                _isSearching = false;
            });
        }
        return; // Hentikan fungsi jika status bukan 200 (termasuk 408)
      }

      // Jika status 200, proses JSON
      try {
        final List<dynamic> features = jsonDecode(response.body);
        
        print('   📍 Found ${features.length} results');
        
        for (var feature in features) {
          try {
            final lat = double.parse(feature['lat'] as String);
            final lng = double.parse(feature['lon'] as String);
            final name = feature['display_name'] ?? 'Unknown';
            final type = feature['type'] ?? 'place';
            final importance = double.parse(
              feature['importance']?.toString() ?? '0.5'
            );
            
            // Opsi: Jika Anda ingin lebih banyak hasil, hapus pengecekan BBox manual ini
            final isInBbox = _isPointInBbox(lat, lng, bbox);
            
            if (isInBbox) {
              results.add({
                'name': name,
                'lat': lat,
                'lng': lng,
                'type': type,
                'relevance': importance,
              });
            }
          } catch (e) {
            print('   ⚠️ Parse error for feature: $e');
          }
        }
      } catch (e) {
        print('   ⚠️ JSON decode error: $e. Response body length: ${response.body.length}');
      }
      
      // Remove duplicates & sort
      final Map<String, Map<String, dynamic>> uniqueResults = {};
      for (var result in results) {
        final key = '${(result['lat'] as double).toStringAsFixed(4)}-${(result['lng'] as double).toStringAsFixed(4)}';
        if (!uniqueResults.containsKey(key)) {
          uniqueResults[key] = result;
        }
      }
      
      final finalResults = uniqueResults.values.toList();
      finalResults.sort((a, b) => 
        (b['relevance'] as double).compareTo(a['relevance'] as double)
      );
      
      if (mounted) {
        setState(() {
          _searchResults = finalResults.take(10).toList(); // Max 10 results
          _isSearching = false;
        });
      }
      
      print('✅ Menampilkan ${_searchResults.length} hasil');
      
      if (_searchResults.isEmpty) {
        print('💡 Tips: Coba ketik lebih spesifik atau klik langsung di map');
      }
      
    } catch (e) {
      print('❌ Exception: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }
  // --- Fungsi Lainnya (Tidak Diubah) ---
  void _handleMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _searchResults = [];
      _searchController.clear();
    });
    widget.onLocationPicked(location);
  }

  void _selectSearchResult(double lat, double lng, String name) {
    final location = LatLng(lat, lng);
    _mapController.move(location, 15.0);
    setState(() {
      _currentZoom = 15.0;
      _selectedLocation = location;
      _searchResults = [];
      _searchController.clear();
    });
    widget.onLocationPicked(location);
    FocusScope.of(context).unfocus();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'house':
      case 'residential':
      case 'address':
        return Icons.home;
      case 'amenity':
      case 'shop':
      case 'restaurant':
      case 'cafe':
        return Icons.store;
      case 'attraction':
      case 'tourism':
        return Icons.location_on;
      case 'administrative':
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'house':
      case 'residential':
      case 'address':
        return 'Alamat';
      case 'amenity':
      case 'shop':
      case 'restaurant':
      case 'cafe':
        return 'Tempat Umum';
      case 'attraction':
      case 'tourism':
        return 'Atraksi';
      case 'administrative':
      case 'city':
      case 'town':
      case 'village':
        return 'Kota/Daerah';
      default:
        return 'Lokasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final markerList = <Marker>[];
    if (_selectedLocation != null) {
      markerList.add(
        Marker(
          point: _selectedLocation!,
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 400,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialLocation ?? 
                  const LatLng(-6.1944, 106.8294),
                initialZoom: 11,
                onTap: (tapPosition, point) => _handleMapTap(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}@2x.png?access_token=$MAPBOX_ACCESS_TOKEN',
                  userAgentPackageName: 'com.example.vsf',
                ),
                MarkerLayer(markers: markerList),
              ],
            ),
            
            // Search Bar
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari: Pantai Ancol, RS Siloam, dll...',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.blue),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                                  ),
                                ),
                              )
                            : (_searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      _debounceTimer?.cancel();
                                      setState(() {
                                        _searchResults = [];
                                        _isSearching = false;
                                      });
                                    },
                                  )
                                : null),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  
                  // Search Results
                  if (_isSearching && _searchResults.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Mencari lokasi...',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  
                  if (_searchResults.isNotEmpty && !_isSearching)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          final type = result['type'] ?? 'place';
                          final name = result['name'] ?? 'Unknown';
                          
                          return ListTile(
                            title: Text(
                              name.length > 60 ? '${name.substring(0, 57)}...' : name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _getTypeLabel(type),
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            leading: Icon(
                              _getIconForType(type),
                              size: 18,
                              color: Colors.blue,
                            ),
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            onTap: () {
                              _selectSearchResult(
                                result['lat'],
                                result['lng'],
                                result['name'],
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            
            // Zoom Controls
            Positioned(
              bottom: 12,
              right: 12,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoom_in_${widget.key}',
                    onPressed: () {
                      final newZoom = _currentZoom + 1;
                      _mapController.move(_mapController.center, newZoom);
                      setState(() => _currentZoom = newZoom);
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out_${widget.key}',
                    onPressed: () {
                      final newZoom = (_currentZoom - 1).clamp(1.0, 18.0);
                      _mapController.move(_mapController.center, newZoom);
                      setState(() => _currentZoom = newZoom);
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.blue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}