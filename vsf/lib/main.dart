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
import 'models/notification_model.dart';


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

   await Hive.deleteBoxFromDisk('articles');
  // Register Adapters
  Hive.registerAdapter(UserTypeAdapter());
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ArticleModelAdapter());
  Hive.registerAdapter(EventLocationModelAdapter());
  Hive.registerAdapter(EventModelAdapter());
  Hive.registerAdapter(VolunteerRegistrationAdapter());
  Hive.registerAdapter(UserStatsAdapter());
  Hive.registerAdapter(NotificationModelAdapter());
  
  

  // Open Boxes
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<UserStats>('user_stats');  
  await Hive.openBox<ArticleModel>('articles');
  await Hive.openBox<EventModel>('events');
  await Hive.openBox<VolunteerRegistration>('registrations');
  await Hive.openBox<NotificationModel>('notifications');


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