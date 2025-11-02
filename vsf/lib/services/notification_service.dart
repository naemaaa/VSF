import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    print('🔔 Initializing NotificationService...');

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ⭐ PENTING: Enable foreground notifications untuk Android 12+
    try {
      final androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestNotificationsPermission();
        print('   📲 Android notification permission: $granted');
      }
    } catch (e) {
      print('   ⚠️ Error requesting Android permissions: $e');
    }

    _isInitialized = true;
    print('✅ NotificationService initialized');
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    print('🔔 Notification tapped with payload: $payload');
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();

    print('📍 Requesting notification permissions...');

    try {
      final androidPlugin =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? granted = await androidPlugin.requestNotificationsPermission();
        print('   Android permission granted: $granted');
        return granted ?? false;
      }
    } catch (e) {
      print('   ⚠️ Error: $e');
    }

    return true;
  }

  Future<void> showPaymentSuccessNotification({
    required String eventTitle,
    required int amount,
  }) async {
    if (!_isInitialized) await initialize();

    print('🔔 Showing payment success notification...');

    try {
      // Format amount dengan pemisah ribuan
      String formattedAmount = 'Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      )}';

      // Android Notification Details - dengan priority HIGH untuk muncul di foreground
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'payment_channel',
        'Payment Notifications',
        channelDescription: 'Notifications for payment status',
        importance: Importance.max, // ⭐ MAX untuk foreground
        priority: Priority.max,     // ⭐ MAX priority
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        showWhen: true,
      );

      // iOS Notification Details
      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique ID untuk notification
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      print('   ID: $notificationId');
      print('   Title: ✅ Pembayaran Berhasil!');
      print('   Body: Pembayaran untuk "$eventTitle" sebesar $formattedAmount berhasil diproses.');

      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        '✅ Pembayaran Berhasil!',
        'Pembayaran untuk "$eventTitle" sebesar $formattedAmount telah berhasil diproses.',
        notificationDetails,
        payload: 'payment_success',
      );

      print('✅ Notification sent successfully');
    } catch (e) {
      print('❌ Error showing notification: $e');
      print('   Error type: ${e.runtimeType}');
    }
  }

  Future<void> cancelAllNotifications() async {
    print('🔔 Cancelling all notifications...');
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}