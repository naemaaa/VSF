import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';  
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/location_picker.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/event_model.dart';
import '../../models/event_location.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';

class CreateEventPage extends StatefulWidget {
  final UserModel currentUser;
  final EventModel? existingEvent;

  const CreateEventPage({super.key, required this.currentUser, this.existingEvent});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  LatLng? _selectedLocation;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // If editing existing event, prefill fields
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
      _rtRwController.text = e.location.rtRw;
      // stored as UTC in model; convert to local for editing UI
      _startDateTime = e.eventStartTime.toLocal();
      _endDateTime = e.eventEndTime.toLocal();
      _targetVolunteerController.text = e.targetVolunteerCount.toString();
      _feeController.text = e.participationFeeIdr == 0 ? '' : e.participationFeeIdr.toString();
      if (e.imageUrl != null && e.imageUrl!.isNotEmpty) {
        try {
          _pickedImage = File(e.imageUrl!);
        } catch (_) {}
      }
      // Set initial map location if coordinates exist
      if (e.location.latitude != 0 && e.location.longitude != 0) {
        _selectedLocation = LatLng(e.location.latitude, e.location.longitude);
      }
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetVolunteerController = TextEditingController(text: '50');
  final _feeController = TextEditingController();
  final _districtController = TextEditingController();
  final _villageController = TextEditingController();
  final _rtRwController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCountry;
  String? _selectedProvince;
  String? _selectedCity;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  File? _pickedImage;

  Future<void> _handleMapTap(LatLng position) async {
    setState(() => _selectedLocation = position);
    try {
      // Get address details from coordinates
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _districtController.text = place.subLocality ?? '';
        _villageController.text = place.locality ?? '';
        _rtRwController.text = (place.street ?? '').replaceAll(RegExp(r'[^0-9/]'), '');
        // Update dropdowns if values found
        final province = place.administrativeArea;
        if (province != null && _provinces.contains(province)) {
          setState(() {
            _selectedProvince = province;
            _selectedCity = null;
          });
        }
        final city = place.subAdministrativeArea;
        if (city != null && (_citiesByProvince[_selectedProvince] ?? []).contains(city)) {
          setState(() => _selectedCity = city);
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  final List<String> _categories = [
    'Pendidikan', 'Lingkungan', 'Kesehatan', 'Sosial', 'Anak-anak'
  ];
  final List<String> _countries = ['Indonesia'];
  final List<String> _provinces = [
    // Jawa (5)
    'DKI Jakarta', 'Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'Banten',
    
    // Sumatera (6)
    'Aceh', 'Sumatera Utara', 'Sumatera Barat', 'Riau', 'Jambi', 'Sumatera Selatan',
    
    // Kalimantan (5)
    'Kalimantan Barat', 'Kalimantan Tengah', 'Kalimantan Selatan', 'Kalimantan Timur', 'Kalimantan Utara',
    
    // Sulawesi (6)
    'Sulawesi Utara', 'Sulawesi Tengah', 'Sulawesi Selatan', 'Sulawesi Tenggara', 'Gorontalo', 'Sulawesi Barat',
    
    // Papua & Maluku (6)
    'Maluku', 'Maluku Utara', 'Papua', 'Papua Barat', 'Papua Tengah', 'Papua Pegunungan',
    
    // Nusa Tenggara (2)
    'Nusa Tenggara Barat', 'Nusa Tenggara Timur',
    
    // Lainnya (3)
    'Yogyakarta', 'Bengkulu', 'Kepulauan Riau',
  ];
  final Map<String, List<String>> _citiesByProvince = {
  // Jawa (5)
  'DKI Jakarta': [
    'Jakarta Pusat', 'Jakarta Barat', 'Jakarta Timur', 'Jakarta Selatan', 'Jakarta Utara'
  ],
  'Jawa Barat': [
    'Bandung', 'Bekasi', 'Bogor', 'Depok', 'Cimahi', 'Tasikmalaya', 'Cianjur', 
    'Sukabumi', 'Garut', 'Purwakarta', 'Karawang', 'Subang', 'Indramayu'
  ],
  'Jawa Tengah': [
    'Semarang', 'Surakarta', 'Magelang', 'Pekalongan', 'Tegal', 'Kudus', 
    'Salatiga', 'Wonosobo', 'Purwokerto', 'Klaten', 'Wonogiri'
  ],
  'Jawa Timur': [
    'Surabaya', 'Malang', 'Kediri', 'Blitar', 'Pasuruan', 'Probolinggo', 
    'Mojokerto', 'Madiun', 'Batu', 'Gresik', 'Tuban', 'Sidoarjo', 'Lamongan'
  ],
  'Banten': [
    'Tangerang', 'Serang', 'Cilegon', 'Pandeglang', 'Lebak'
  ],

  // Sumatera (6)
  'Aceh': [
    'Banda Aceh', 'Sabang', 'Lhokseumawe', 'Langsa', 'Meulaboh', 'Takengon',
    'Aceh Besar', 'Pidie', 'Aceh Utara', 'Aceh Timur', 'Aceh Tengah'
  ],
  'Sumatera Utara': [
    'Medan', 'Binjai', 'Deli Serdang', 'Karo', 'Langkat', 'Asahan',
    'Labuhanbatu', 'Tapanuli Utara', 'Tapanuli Tengah', 'Tapanuli Selatan', 'Mandailing Natal'
  ],
  'Sumatera Barat': [
    'Padang', 'Bukittinggi', 'Payakumbuh', 'Sawahlunto', 'Padang Panjang',
    'Agam', 'Lima Puluh Kota', 'Pasaman', 'Solok', 'Tanah Datar'
  ],
  'Riau': [
    'Pekanbaru', 'Dumai', 'Siak', 'Kampar', 'Rohul', 'Indragiri Hilir',
    'Indragiri Hulu', 'Kuantan Singingi', 'Pelalawan', 'Rokan Hilir', 'Rokan Hulu'
  ],
  'Jambi': [
    'Jambi', 'Sungai Penuh', 'Kerinci', 'Merangin', 'Bungo', 'Tebo',
    'Muara Jambi', 'Muara Bulian', 'Muara Tebo', 'Sarolangun'
  ],
  'Sumatera Selatan': [
    'Palembang', 'Prabumulih', 'Lubuklinggau', 'Musi Banyu Asin', 'Musi Rawas',
    'Banyuasin', 'Ogan Ilir', 'Ogan Komering Ilir', 'Ogan Komering Ulu', 'Lahat'
  ],

  // Kalimantan (5)
  'Kalimantan Barat': [
    'Pontianak', 'Singkawang', 'Sambas', 'Bengkayang', 'Landak', 'Mempawah',
    'Kubu Raya', 'Sanggau', 'Sekadau', 'Kapuas Hulu', 'Sintang'
  ],
  'Kalimantan Tengah': [
    'Palangka Raya', 'Kapuas', 'Barito Utara', 'Barito Timur', 'Katingan',
    'Kotawaringin Barat', 'Kotawaringin Timur', 'Lamandau', 'Seruyan', 'Sukamara'
  ],
  'Kalimantan Selatan': [
    'Banjarmasin', 'Banjarbaru', 'Banjar', 'Barito Kuala', 'Hulu Sungai Utara',
    'Hulu Sungai Selatan', 'Hulu Sungai Tengah', 'Tabalong', 'Tanah Laut', 'Tapin'
  ],
  'Kalimantan Timur': [
    'Samarinda', 'Balikpapan', 'Bontang', 'Kutai Kartanegara', 'Paser',
    'Kutai Barat', 'Berau', 'Penajam Paser Utara'
  ],
  'Kalimantan Utara': [
    'Tarakan', 'Tanjung Selor', 'Malinau', 'Nunukan', 'Bulungan'
  ],

  // Sulawesi (6)
  'Sulawesi Utara': [
    'Manado', 'Bitung', 'Tomohon', 'Minahasa', 'Minahasa Utara', 'Minahasa Selatan',
    'Minahasa Tenggara', 'Bolaang Mongondow', 'Bolaang Mongondow Utara', 'Bolaang Mongondow Selatan'
  ],
  'Sulawesi Tengah': [
    'Palu', 'Mantikulore', 'Donggala', 'Banggai Kepulauan', 'Banggai', 'Morowali',
    'Morowali Utara', 'Parigi Moutong', 'Poso', 'Sigi', 'Tojo Una-Una'
  ],
  'Sulawesi Selatan': [
    'Makassar', 'Parepare', 'Palopo', 'Gowa', 'Takalar', 'Jeneponto', 'Bantaeng',
    'Barru', 'Bone', 'Bulukumba', 'Enrekang', 'Luwu', 'Luwu Timur', 'Luwu Utara',
    'Maros', 'Pangkajene Kepulauan', 'Pinrang', 'Sidenreng Rappang', 'Sinjai', 'Soppeng', 'Toraja Utara'
  ],
  'Sulawesi Tenggara': [
    'Kendari', 'Baubau', 'Bombana', 'Buton', 'Buton Selatan', 'Buton Tengah',
    'Buton Utara', 'Kolaka', 'Kolaka Timur', 'Kolaka Utara', 'Konawe', 'Konawe Kepulauan',
    'Konawe Selatan', 'Konawe Utara', 'Muna', 'Muna Barat', 'Wakatobi'
  ],
  'Gorontalo': [
    'Gorontalo', 'Tilamuta', 'Boalemo', 'Bone Bolango', 'Gorontalo Utara', 'Pohuwato'
  ],
  'Sulawesi Barat': [
    'Mamuju', 'Manado', 'Majene', 'Mamasa', 'Mamuju Utara', 'Mamuju Tengah', 'Polewali Mandar'
  ],

  // Papua & Maluku (6)
  'Maluku': [
    'Ambon', 'Tual', 'Bula', 'Amahai', 'Masohi', 'Manipa', 'Seram Barat',
    'Seram Timur', 'Maluku Barat Daya', 'Maluku Tenggara', 'Maluku Tenggara Barat'
  ],
  'Maluku Utara': [
    'Ternate', 'Tidore', 'Sofifi', 'Halmahera Barat', 'Halmahera Tengah', 'Halmahera Timur',
    'Halmahera Utara', 'Halmahera Selatan', 'Pulau Morotai', 'Pulau Taliabu'
  ],
  'Papua': [
    'Jayapura', 'Wamena', 'Lembah Baliem', 'Merauke', 'Biak', 'Sorong',
    'Mimika', 'Jayawijaya', 'Asmat', 'Yapen Waropen'
  ],
  'Papua Barat': [
    'Manokwari', 'Sorong', 'Fakfak', 'Kaimana', 'Teluk Bintuni', 'Teluk Wondama'
  ],
  'Papua Tengah': [
    'Tiom', 'Kasonaweja', 'Mamberamo Raya', 'Mamberamo Tengah'
  ],
  'Papua Pegunungan': [
    'Wamena', 'Oksibil', 'Tiom', 'Dekai'
  ],

  // Nusa Tenggara (2)
  'Nusa Tenggara Barat': [
    'Mataram', 'Bima', 'Dompu', 'Lombok Barat', 'Lombok Tengah', 'Lombok Timur',
    'Lombok Utara', 'Sumbawa', 'Sumbawa Barat', 'Sumbawa Timur'
  ],
  'Nusa Tenggara Timur': [
    'Kupang', 'Maumere', 'Ende', 'Belu', 'Flores Timur', 'Kupang', 'Lembata',
    'Manggarai', 'Manggarai Barat', 'Manggarai Timur', 'Nagekeo', 'Ngada',
    'Rote Ndao', 'Sabu Raijua', 'Sikka', 'Sumba Barat', 'Sumba Timur'
  ],

  // Lainnya (3)
  'Yogyakarta': [
    'Yogyakarta', 'Sleman', 'Bantul', 'Gunungkidul', 'Kulon Progo'
  ],
  'Bengkulu': [
    'Bengkulu', 'Curup', 'Lebong', 'Muko-Muko', 'Rejang Lebong', 'Bengkulu Utara',
    'Bengkulu Selatan', 'Kaur', 'Seluma'
  ],
  'Kepulauan Riau': [
    'Tanjung Pinang', 'Batam', 'Bintan', 'Karimun', 'Anambas', 'Lingga', 'Natuna'
  ],
};

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDir.path}/vsf_images');
        if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
        final saved = await File(picked.path).copy('${imagesDir.path}/$fileName');
        setState(() => _pickedImage = saved);
      } catch (e) {
        setState(() => _pickedImage = File(picked.path));
      }
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
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDateTime = dt;
      } else {
        _endDateTime = dt;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _startDateTime == null || _endDateTime == null) return;

    final eventBox = Hive.box<EventModel>('events');
    final id = widget.existingEvent?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final location = EventLocation(
      country: _selectedCountry ?? '',
      province: _selectedProvince ?? '',
      city: _selectedCity ?? '',
      district: _districtController.text,
      village: _villageController.text,
      rtRw: _rtRwController.text,
      latitude: _selectedLocation?.latitude ?? 0,
      longitude: _selectedLocation?.longitude ?? 0,
    );
    final imagePath = _pickedImage?.path ?? widget.existingEvent?.imageUrl;
    final event = EventModel(
      id: id,
      title: _titleController.text,
      description: _descController.text,
      imageUrl: imagePath,
      organizerId: widget.currentUser.id,
      organizerName: widget.currentUser.fullName ?? widget.currentUser.organizationName ?? '-',
      organizerImageUrl: widget.currentUser.profileImagePath,
      location: location,
      eventStartTime: _startDateTime!.toUtc(),
      eventEndTime: _endDateTime!.toUtc(),
      targetVolunteerCount: int.tryParse(_targetVolunteerController.text) ?? 0,
      currentVolunteerCount: 0,
      participationFeeIdr: int.tryParse(_feeController.text) ?? 0,
      category: _selectedCategory ?? '',
      isActive: true,
      createdAt: DateTime.now(),
    );
    if (widget.existingEvent != null) {
      final existing = widget.existingEvent!;
      existing.title = event.title;
      existing.description = event.description;
      existing.imageUrl = event.imageUrl;
      existing.location = event.location;
      existing.eventStartTime = event.eventStartTime;
      existing.eventEndTime = event.eventEndTime;
      existing.targetVolunteerCount = event.targetVolunteerCount;
      existing.participationFeeIdr = event.participationFeeIdr;
      existing.category = event.category;
      existing.save();
    } else {
      await eventBox.put(id, event);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftarkan Kegiatan Baru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Judul Kegiatan'),
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
              const Text('Deskripsi Kegiatan'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan tujuan dan tugas volunteer secara rinci',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Unggah Gambar Kegiatan'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: DottedBorder(
                  color: Colors.grey,
                  strokeWidth: 1,
                  dashPattern: const [6, 3],
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: _pickedImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Unggah file atau seret dan lepas\nPNG, JPG, GIF hingga 10MB',
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : Image.file(_pickedImage!, height: 100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kategori'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                validator: (v) => v == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 16),
              const Text('Lokasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCountry = v),
                decoration: const InputDecoration(
                  hintText: 'Pilih Negara',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
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
                decoration: const InputDecoration(
                  hintText: 'Pilih Provinsi',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                validator: (v) => v == null ? 'Pilih provinsi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCity,
                items: (_citiesByProvince[_selectedProvince] ?? [])
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                decoration: const InputDecoration(
                  hintText: 'Pilih Kota/Kabupaten',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                validator: (v) => v == null ? 'Pilih kota/kabupaten' : null,
              ),
              const SizedBox(height: 16),
              const Text('Pilih Lokasi di Peta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    'Koordinat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(hintText: 'Kecamatan', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Kecamatan wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _villageController,
                decoration: const InputDecoration(hintText: 'Desa/Kelurahan', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Desa/Kelurahan wajib diisi' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rtRwController,
                decoration: const InputDecoration(hintText: 'RT/RW', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'RT/RW wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Tanggal & Waktu Mulai'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDateTime(isStart: true),
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'mm/dd/yyyy, --:-- --'),
                  child: Text(_startDateTime == null
                      ? ''
                      : '${_startDateTime!.toLocal()}'.split('.').first.replaceAll('T', ' ')),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Tanggal & Waktu Selesai'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDateTime(isStart: false),
                child: InputDecorator(
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'mm/dd/yyyy, --:-- --'),
                  child: Text(_endDateTime == null
                      ? ''
                      : '${_endDateTime!.toLocal()}'.split('.').first.replaceAll('T', ' ')),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Target Jumlah Volunteer'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetVolunteerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.people), border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Target volunteer wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              const Text('Harga Partisipasi (Rp)'),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Daftarkan Kegiatan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;
  final BorderType borderType;
  final Radius radius;

  const DottedBorder({
    required this.child,
    this.color = Colors.grey,
    this.strokeWidth = 1,
    this.dashPattern = const [6, 3],
    this.borderType = BorderType.RRect,
    this.radius = const Radius.circular(12),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(radius),
        border: Border.all(color: color, width: strokeWidth, style: BorderStyle.solid),
      ),
      child: child,
    );
  }
}

enum BorderType { RRect }