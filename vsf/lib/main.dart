import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

// Import models
import 'models/user_model.dart';
import 'models/event_model.dart';
import 'models/event_location.dart';
import 'models/article_model.dart';
import 'models/volunteer_registration.dart';
import 'models/user_stats_model.dart';
import 'services/notification_service.dart';


// Import services
import 'services/session_service.dart';

// Import pages
import 'pages/auth/login_page.dart';
import 'pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request location permissions
  await _requestLocationPermissions();

  // Initialize Hive
  await Hive.initFlutter();

  // Delete all Hive boxes (untuk testing - COMMENT ini kalau sudah prod)
  // try {
  //   await Hive.deleteFromDisk();
  // } catch (e) {
  //   print('Error deleting Hive data: $e');
  // }
  await Hive.deleteBoxFromDisk('user_stats');
  await Hive.deleteBoxFromDisk('articles');
  // Register Adapters
  Hive.registerAdapter(UserTypeAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  Hive.registerAdapter(EventLocationModelAdapter());
  Hive.registerAdapter(EventModelAdapter());
  Hive.registerAdapter(VolunteerRegistrationAdapter());
  Hive.registerAdapter(UserStatsAdapter());
  
  

  // Open Boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<UserStats>('user_stats');  
  await Hive.openBox<ArticleModel>('articles');
  await Hive.openBox<EventModel>('events');
  await Hive.openBox<VolunteerRegistration>('registrations');


  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // ← CHECK PERMISSION STATUS
  print('📲 Checking notification permission...');
  final granted = await notificationService.requestPermissions();
  print('📲 Permission granted: $granted');

  print('📍 Requesting location permission at startup...');
  await _requestLocationPermissionOnce();

  // ← SEED DATA (User & Event saja, TIDAK termasuk Artikel)
  await seedDummyData();

  runApp(const MyApp());
}

Future<void> _requestLocationPermissions() async {
  try {
    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    print('Location permission error: $e');
  }
}

// Hash password
String hashPassword(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString();
}

Future<void> _requestLocationPermissionOnce() async {
  try {
    final status = await Geolocator.checkPermission();
    print('   Current permission status: $status');

    if (status == LocationPermission.denied) {
      print('   📍 Permission denied, requesting...');
      final newStatus = await Geolocator.requestPermission();
      print('   After request: $newStatus');

      if (newStatus == LocationPermission.whileInUse ||
          newStatus == LocationPermission.always) {
        print('   ✅ Location permission granted');
      } else if (newStatus == LocationPermission.deniedForever) {
        print('   ❌ Location permission denied forever');
      }
    } else if (status == LocationPermission.whileInUse ||
        status == LocationPermission.always) {
      print('   ✅ Location permission already granted');
    } else if (status == LocationPermission.deniedForever) {
      print('   ❌  Location permission denied forever');
    }

    // Also check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('   Location service enabled: $serviceEnabled');

  } catch (e) {
    print('   ⚠️ Error requesting location permission: $e');
  }
}

// ← SEED HANYA User & Event (ARTIKEL DIAMBIL DARI API)
Future<void> seedDummyData() async {
  final userBox = Hive.box<UserModel>('users');
  final eventBox = Hive.box<EventModel>('events');

  // Seed Users jika belum ada
  if (userBox.isEmpty) {
    final user1 = UserModel(
      id: 'user_001',
      email: 'johndoe@example.com',
      passwordHash: hashPassword('password123'),
      userType: UserType.individual,
      fullName: 'John Doe',
      nik: '3174012345670001',
      phone: '+62 812 3456 7890',
      bio: 'Passionate about making a difference in the community.',
    );

    final org1 = UserModel(
      id: 'org_001',
      email: 'yayasan@cipta.org',
      passwordHash: hashPassword('org123'),
      userType: UserType.organization,
      organizationName: 'Yayasan Cipta Asa',
      npwp: '01.234.567.8-901.000',
      phone: '+62 21 5678 9012',
      bio: 'Yayasan yang berfokus pada pendidikan dan kesejahteraan anak Indonesia.',
    );

    final org2 = UserModel(
      id: 'org_002',
      email: 'komunitas@peduli.id',
      passwordHash: hashPassword('peduli123'),
      userType: UserType.organization,
      organizationName: 'Komunitas Peduli Lingkungan Jakarta',
      npwp: '02.345.678.9-012.000',
      phone: '+62 21 8765 4321',
      bio: 'Komunitas yang bergerak di bidang pelestarian lingkungan.',
    );

    await userBox.add(user1);
    await userBox.add(org1);
    await userBox.add(org2);
    
    print('✅ Seed Users completed: 3 users');
  }

  // Seed Events jika belum ada
  if (eventBox.isEmpty) {
    final event1 = EventModel(
      id: 'event_001',
      title: 'Aksi Bersih Pantai Ancol',
      description:
          'Mari bergabung bersama kami dalam aksi bersih-bersih Pantai Ancol untuk menjaga kebersihan lingkungan dan kesehatan laut!',
      imageUrl: 'https://images.unsplash.com/photo-1618477461853-cf6ed80faba5?w=800',
      organizerId: 'org_002',
      organizerName: 'Komunitas Peduli Lingkungan Jakarta',
      location: EventLocationModel(
        country: 'Indonesia',
        province: 'DKI Jakarta',
        city: 'Jakarta Utara',
        district: 'Pademangan',
        village: 'Ancol',
        latitude: -6.1254,
        longitude: 106.8416,
      ),
      eventStartTime: DateTime(2023, 11, 25, 1, 0), // UTC
      eventEndTime: DateTime(2023, 11, 25, 4, 0),
      targetVolunteerCount: 100,
      currentVolunteerCount: 45,
      participationFeeIdr: 0,
      category: 'Lingkungan',
    );

    final event2 = EventModel(
      id: 'event_002',
      title: 'Aksi Tanam 1000 Pohon',
      description:
          'Bergabunglah dalam gerakan penanaman 1000 pohon untuk kota hijau!',
      imageUrl: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800',
      organizerId: 'org_002',
      organizerName: 'Komunitas Peduli Lingkungan Jakarta',
      location: EventLocationModel(
        country: 'Indonesia',
        province: 'Jawa Barat',
        city: 'Bandung',
        district: 'Lembang',
        village: 'Cikole',
        latitude: -6.8168,
        longitude: 107.6179,
      ),
      eventStartTime: DateTime(2023, 12, 10, 2, 0),
      eventEndTime: DateTime(2023, 12, 10, 5, 0),
      targetVolunteerCount: 150,
      currentVolunteerCount: 87,
      participationFeeIdr: 0,
      category: 'Lingkungan',
    );

    final event3 = EventModel(
      id: 'event_003',
      title: 'Bantu Mengajar di Panti Asuhan Kasih Bunda',
      description:
          'Ayo berbagi ilmu dan kasih sayang dengan mengajar anak-anak di Panti Asuhan.',
      imageUrl: 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800',
      organizerId: 'org_001',
      organizerName: 'Yayasan Cipta Asa',
      location: EventLocationModel(
        country: 'Indonesia',
        province: 'DKI Jakarta',
        city: 'Jakarta Selatan',
        district: 'Pasar Minggu',
        village: 'Jati Padang',
        latitude: -6.2989,
        longitude: 106.8411,
      ),
      eventStartTime: DateTime(2023, 12, 1, 3, 0),
      eventEndTime: DateTime(2023, 12, 1, 8, 0),
      targetVolunteerCount: 20,
      currentVolunteerCount: 12,
      participationFeeIdr: 50000,
      category: 'Pendidikan',
    );

    await eventBox.add(event1);
    await eventBox.add(event2);
    await eventBox.add(event3);

    print('✅ Seed Events completed: 3 events');
  }

  // ← ARTIKEL TIDAK DI-SEED, akan diambil dari API saat HomePage load
  print('ℹ️  Articles will be fetched from API on HomePage load');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volunteer Spot Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await _sessionService.isLoggedIn();

    if (isLoggedIn) {
      final user = await _sessionService.getCurrentUser();

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(currentUser: user),
          ),
        );
      } else {
        await _sessionService.clearSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.volunteer_activism,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'Volunteer Spot Finder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}