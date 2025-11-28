// create_event_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../../widgets/location_picker.dart'; 
import '../../models/event_model.dart';
import '../../models/event_location.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import '../../services/event_service.dart'; 

// ✅ FIX: Timezone handling yang lebih robust
class TimezoneHelper {
  static const String APP_TIMEZONE_NAME = 'WIB'; // App menggunakan WIB sebagai standar
  static const int WIB_OFFSET_HOURS = 7; // UTC+7

  /// Ambil timezone offset device saat ini dalam jam
  static int getDeviceTimezoneOffsetHours() {
    return DateTime.now().timeZoneOffset.inHours;
  }

  /// Konversi dari local input (dianggap WIB) ke UTC untuk disimpan
  /// 
  /// Skenario:
  /// - User input: 09:00 (WIB/UTC+7)
  /// - Device di WIB: offset = 7 → result = 09:00 - 7 = 02:00 UTC ✓
  /// - Device di GMT: offset = 0 → result = 09:00 - (0 - 7) = 16:00 UTC ✓
  static DateTime localWIBToUTC(DateTime localWIBTime) {
    final deviceOffset = getDeviceTimezoneOffsetHours();
    final offsetDifference = deviceOffset - WIB_OFFSET_HOURS;
    
    // Adjust untuk perbedaan timezone device
    final adjusted = localWIBTime.subtract(Duration(hours: offsetDifference));
    final utc = adjusted.toUtc();
    
    print('🕐 Local to UTC Conversion:');
    print('   Input (WIB): $localWIBTime');
    print('   Device offset: UTC+$deviceOffset');
    print('   WIB offset: UTC+$WIB_OFFSET_HOURS');
    print('   Adjusted: $adjusted');
    print('   Output (UTC): $utc');
    
    return utc;
  }

  /// Konversi dari UTC (database) ke local display (WIB)
  /// 
  /// Skenario:
  /// - Database: 02:00 UTC
  /// - Device di WIB: offset = 7 → result = 02:00 + (7 - 0) = 09:00 WIB ✓
  /// - Device di GMT: offset = 0 → result = 02:00 + (7 - 0) = 09:00 WIB ✓
  static DateTime utcToLocalWIB(DateTime utcTime) {
    final deviceOffset = getDeviceTimezoneOffsetHours();
    final offsetDifference = WIB_OFFSET_HOURS - deviceOffset;
    
    final local = utcTime.add(Duration(hours: offsetDifference));
    
    print('🕐 UTC to Local Conversion:');
    print('   Input (UTC): $utcTime');
    print('   Device offset: UTC+$deviceOffset');
    print('   WIB offset: UTC+$WIB_OFFSET_HOURS');
    print('   Output (WIB): $local');
    
    return local;
  }
}

class CreateEventPage extends StatefulWidget {
  final UserModel currentUser;
  final EventModel? existingEvent;

  const CreateEventPage({
    super.key,
    required this.currentUser,
    this.existingEvent,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final EventService _eventService = EventService();
  LatLng? _selectedLocation;
  final LocationService _locationService = LocationService();

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetVolunteerController = TextEditingController(text: '50');
  final _feeController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;
  DateTime? _startDateTime; // ✅ Simpan sebagai local WIB
  DateTime? _endDateTime;   // ✅ Simpan sebagai local WIB
  File? _pickedImage;
  
  bool _isSubmitting = false;
  bool _isManualAddressDisabled = false;
  
  final List<String> _categories = [
    'Pendidikan', 'Lingkungan', 'Kesehatan', 'Sosial', 'Anak-anak'
  ];
  final List<String> _countries = ['Indonesia'];
  final List<String> _provinces = [
    'DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'Banten', 
    'Aceh', 'Sumatera Utara', 'Sumatera Barat', 'Riau', 'Jambi', 'Sumatera Selatan',
    'Kalimantan Barat', 'Kalimantan Tengah', 'Kalimantan Selatan', 'Kalimantan Timur', 'Kalimantan Utara',
    'Sulawesi Utara', 'Sulawesi Tengah', 'Sulawesi Selatan', 'Sulawesi Tenggara', 'Gorontalo', 'Sulawesi Barat',
    'Maluku', 'Maluku Utara', 'Papua', 'Papua Barat', 'Papua Tengah', 'Papua Pegunungan',
    'Nusa Tenggara Barat', 'Nusa Tenggara Timur', 'Yogyakarta', 'Bengkulu', 'Kepulauan Riau',
  ];
  final Map<String, List<String>> _citiesByProvince = {
    'DKI Jakarta': ['Jakarta Pusat', 'Jakarta Barat', 'Jakarta Timur', 'Jakarta Selatan', 'Jakarta Utara'],
    'Jawa Barat': ['Bandung', 'Bekasi', 'Bogor', 'Depok', 'Cimahi', 'Tasikmalaya'],
    'Jawa Tengah': ['Semarang', 'Surakarta', 'Magelang', 'Pekalongan', 'Tegal'],
    'Jawa Timur': ['Surabaya', 'Malang', 'Kediri', 'Blitar', 'Pasuruan'],
    'Banten': ['Tangerang', 'Serang', 'Cilegon', 'Pandeglang', 'Lebak'],
    'Yogyakarta': ['Yogyakarta', 'Sleman', 'Bantul', 'Gunungkidul', 'Kulon Progo'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      final e = widget.existingEvent!;
      _titleController.text = e.title;
      _descController.text = e.description;
      _selectedCategory = e.category;
      _selectedCountry = e.location.country.isNotEmpty ? e.location.country : null;
      _selectedProvince = e.location.province.isNotEmpty ? e.location.province : null;
      _selectedCity = e.location.city.isNotEmpty ? e.location.city : null;
      _districtController.text = e.location.district;
      _villageController.text = e.location.village;
      
      // ✅ FIX: Convert UTC database ke local WIB untuk edit
      _startDateTime = TimezoneHelper.utcToLocalWIB(e.eventStartTime);
      _endDateTime = TimezoneHelper.utcToLocalWIB(e.eventEndTime);
      
      print('📝 Edit Event Loaded:');
      print('   UTC Start: ${e.eventStartTime}');
      print('   Local Display: $_startDateTime');
      
      _targetVolunteerController.text = e.targetVolunteerCount.toString();
      _feeController.text = e.participationFeeIdr == 0 ? '' : e.participationFeeIdr.toString();
      
      if (e.imageUrl != null && e.imageUrl!.isNotEmpty && !e.imageUrl!.startsWith('http')) {
        try {
          _pickedImage = File(e.imageUrl!);
        } catch (_) {}
      }
      
      if (e.location.latitude != 0 && e.location.longitude != 0) {
        _selectedLocation = LatLng(e.location.latitude, e.location.longitude);
        _isManualAddressDisabled = true;
      }
    }
  }

  Future<void> _handleMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _isManualAddressDisabled = true;
    });
    
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        
        _districtController.text = place.subLocality ?? '';
        _villageController.text = place.locality ?? '';

        setState(() {
          final province = place.administrativeArea;
          if (province != null && _provinces.contains(province)) {
            _selectedProvince = province;
            _selectedCity = null;
          }
          
          final city = place.subAdministrativeArea;
          if (city != null && (_citiesByProvince[_selectedProvince] ?? []).contains(city)) {
            _selectedCity = city;
          }
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan detail alamat dari peta.')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    
    // ✅ FIX: DateTime dari DatePicker/TimePicker adalah local time
    // Simpan sebagai local WIB untuk konsistensi
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    
    print('🕐 Date/Time Picker Result:');
    print('   Raw DateTime: $dt');
    print('   Assumed timezone: ${TimezoneHelper.APP_TIMEZONE_NAME}');
    
    setState(() {
      if (isStart) {
        _startDateTime = dt;
      } else {
        _endDateTime = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || 
        _startDateTime == null || 
        _endDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih lokasi di peta')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isNewEvent = widget.existingEvent == null;
      final id = widget.existingEvent?.id ?? 
          'event_${DateTime.now().millisecondsSinceEpoch}';
      
      final location = EventLocationModel(
        country: _selectedCountry ?? '',
        province: _selectedProvince ?? '',
        city: _selectedCity ?? '',
        district: _districtController.text,
        village: _villageController.text,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      // ✅ FIX: Convert local WIB ke UTC untuk database
      final eventStartTimeUTC = TimezoneHelper.localWIBToUTC(_startDateTime!);
      final eventEndTimeUTC = TimezoneHelper.localWIBToUTC(_endDateTime!);

      final eventToSubmit = EventModel(
        id: id,
        title: _titleController.text,
        description: _descController.text,
        imageUrl: widget.existingEvent?.imageUrl, 
        organizerId: widget.currentUser.id,
        organizerName: widget.currentUser.fullName ?? 
                       widget.currentUser.organizationName ?? '-',
        organizerImageUrl: widget.currentUser.profileImagePath,
        location: location,
        eventStartTime: eventStartTimeUTC,  // ✅ UTC
        eventEndTime: eventEndTimeUTC,      // ✅ UTC
        targetVolunteerCount: int.tryParse(_targetVolunteerController.text) ?? 0,
        currentVolunteerCount: widget.existingEvent?.currentVolunteerCount ?? 0,
        participationFeeIdr: int.tryParse(_feeController.text) ?? 0,
        category: _selectedCategory ?? '',
        isActive: true,
        createdAt: widget.existingEvent?.createdAt ?? DateTime.now().toUtc(),
        registeredVolunteerIds: widget.existingEvent?.registeredVolunteerIds ?? [],
      );

      File? fileToUpload = _pickedImage;

      EventModel? resultEvent;
      if (isNewEvent) {
        resultEvent = await _eventService.createEvent(eventToSubmit, fileToUpload);
      } else {
        resultEvent = await _eventService.updateEvent(eventToSubmit, fileToUpload);
      }
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        if (resultEvent != null) {
          print('✅ Event saved successfully');
          print('   Start (UTC): ${resultEvent.eventStartTime}');
          print('   Start (Display): ${TimezoneHelper.utcToLocalWIB(resultEvent.eventStartTime)}');
          print('   End (UTC): ${resultEvent.eventEndTime}');
          print('   End (Display): ${TimezoneHelper.utcToLocalWIB(resultEvent.eventEndTime)}');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isNewEvent ? 'Kegiatan berhasil didaftarkan' : 'Kegiatan berhasil diperbarui'}!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan kegiatan. Coba lagi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _submit: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingEvent == null 
            ? 'Daftarkan Kegiatan Baru' 
            : 'Edit Kegiatan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Judul Kegiatan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Aksi Bersih Pantai Ancol',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Judul wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Deskripsi Kegiatan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Jelaskan tujuan dan tugas volunteer',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Unggah Gambar Kegiatan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          )
                        : widget.existingEvent?.imageUrl != null && 
                          widget.existingEvent!.imageUrl!.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  widget.existingEvent!.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => _imagePlaceholder(),
                                ),
                              )
                            : _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Pilih kategori' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Lokasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCountry = v),
                  decoration: const InputDecoration(hintText: 'Negara', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Pilih negara' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvince,
                  items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedProvince = v;
                      _selectedCity = null;
                    });
                  },
                  decoration: const InputDecoration(hintText: 'Provinsi', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Pilih provinsi' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  items: (_citiesByProvince[_selectedProvince] ?? [])
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  decoration: const InputDecoration(hintText: 'Kota/Kabupaten', border: OutlineInputBorder()),
                  validator: (v) => v == null ? 'Pilih kota' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Pilih Lokasi di Peta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LocationPicker(
                  initialLocation: _selectedLocation,
                  onLocationPicked: _handleMapTap,
                  selectedCity: _selectedCity,
                  selectedProvince: _selectedProvince,
                ),
                if (_selectedLocation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                
                const Text('Detail Alamat', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: _districtController,
                  decoration: InputDecoration(
                    hintText: 'Kecamatan', 
                    border: const OutlineInputBorder(),
                    filled: _isManualAddressDisabled,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Kecamatan wajib diisi' : null,
                  enabled: !_isManualAddressDisabled,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _villageController,
                  decoration: InputDecoration(
                    hintText: 'Desa/Kelurahan', 
                    border: const OutlineInputBorder(),
                    filled: _isManualAddressDisabled,
                    fillColor: Colors.grey[100],
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Desa/Kelurahan wajib diisi' : null,
                  enabled: !_isManualAddressDisabled,
                ),
                const SizedBox(height: 16),
                
                // ✅ IMPROVED: Timezone info display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Waktu akan disimpan dalam UTC (Koordinat Waktu Universal) untuk konsistensi di seluruh timezone',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Tanggal & Waktu Mulai', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDateTime(isStart: true),
                  child: InputDecorator(
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    child: Text(_startDateTime == null
                        ? 'Pilih tanggal & waktu mulai'
                        : '${_startDateTime!}'.split('.').first.replaceAll('T', ' ')),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Tanggal & Waktu Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDateTime(isStart: false),
                  child: InputDecorator(
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    child: Text(_endDateTime == null
                        ? 'Pilih tanggal & waktu selesai'
                        : '${_endDateTime!}'.split('.').first.replaceAll('T', ' ')),
                  ),
                ),
                const SizedBox(height: 16),
                
                const Text('Target Jumlah Volunteer', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _targetVolunteerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Target volunteer wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                
                const Text('Harga Partisipasi (Rp)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    hintText: 'Kosongkan jika gratis',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            widget.existingEvent == null 
                                ? 'Daftarkan Kegiatan' 
                                : 'Simpan Perubahan',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

  Widget _imagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Tap untuk upload gambar',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetVolunteerController.dispose();
    _feeController.dispose();
    _districtController.dispose();
    _villageController.dispose();
    super.dispose();
  }
}