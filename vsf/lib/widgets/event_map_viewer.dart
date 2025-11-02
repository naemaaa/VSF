import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/event_model.dart';
import '../../services/location_service.dart';

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
  'Yogyakarta': LatLng(-7.7956, 110.3695),
};

class EventMapViewer extends StatefulWidget {
  final EventModel event;
  final String? currentUserLat;
  final String? currentUserLng;
  final String? currentUserProvince;

  const EventMapViewer({
    super.key,
    required this.event,
    this.currentUserLat,
    this.currentUserLng,
    this.currentUserProvince,
  });

  @override
  State<EventMapViewer> createState() => _EventMapViewerState();
}

class _EventMapViewerState extends State<EventMapViewer> {
  late MapController _mapController;
  double? _distanceToEvent;
  final LocationService _locationService = LocationService();
  
  static const String MAPBOX_ACCESS_TOKEN = 'REDACTED_MAPBOX_TOKEN';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _calculateDistance();
    
    if (widget.currentUserProvince != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _moveToProvince(widget.currentUserProvince!);
      });
    }
  }

  @override
  void didUpdateWidget(EventMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.currentUserProvince != widget.currentUserProvince && 
        widget.currentUserProvince != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _moveToProvince(widget.currentUserProvince!);
      });
    }
    
    // Recalculate jarak saat user location berubah
    if (oldWidget.currentUserLat != widget.currentUserLat || 
        oldWidget.currentUserLng != widget.currentUserLng) {
      print('📍 User location updated, recalculating distance...');
      _calculateDistance();
    }
  }

  void _moveToProvince(String province) {
    final center = PROVINCE_CENTER[province];
    if (center != null) {
      _mapController.move(center, 10.0);
    }
  }

  Future<void> _calculateDistance() async {
    if (widget.currentUserLat != null && widget.currentUserLng != null) {
      try {
        print('🔄 Calculating distance...');
        print('   User: ${widget.currentUserLat}, ${widget.currentUserLng}');
        print('   Event: ${widget.event.location.latitude}, ${widget.event.location.longitude}');
        
        final distance = _locationService.calculateDistance(
          double.parse(widget.currentUserLat!),
          double.parse(widget.currentUserLng!),
          widget.event.location.latitude,
          widget.event.location.longitude,
        );
        
        print('✅ Distance: $distance km');
        
        if (mounted) {
          setState(() => _distanceToEvent = distance);
        }
      } catch (e) {
        print('❌ Error calculating distance: $e');
      }
    } else {
      print('⚠️ User location not available');
      print('   currentUserLat: ${widget.currentUserLat}');
      print('   currentUserLng: ${widget.currentUserLng}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Event marker (blue)
    final eventMarker = Marker(
      point: LatLng(
        widget.event.location.latitude,
        widget.event.location.longitude,
      ),
      width: 40,
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
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
    );

    final markerList = <Marker>[eventMarker];
    
    if (widget.currentUserLat != null && widget.currentUserLng != null) {
      try {
        markerList.add(
          Marker(
            point: LatLng(
              double.parse(widget.currentUserLat!),
              double.parse(widget.currentUserLng!),
            ),
            width: 40,
            height: 40,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        );
      } catch (e) {
        print('Error parsing user coordinates: $e');
      }
    }

    final defaultCenter = LatLng(
      widget.event.location.latitude,
      widget.event.location.longitude,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map Container (TANPA SEARCH - hanya tampil)
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.mapbox.com/v4/mapbox.satellite/{z}/{x}/{y}@2x.png?access_token=$MAPBOX_ACCESS_TOKEN',
                  userAgentPackageName: 'com.example.vsf',
                ),
                MarkerLayer(markers: markerList),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Distance Info
        if (_distanceToEvent != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.straighten, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jarak ke Event',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _locationService.formatDistance(_distanceToEvent!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Jarak akan muncul saat volunteer membuka event',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}