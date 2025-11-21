import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';
import '../../services/session_service.dart';
class NotificationListPage extends StatefulWidget {
const NotificationListPage({super.key});
@override
State<NotificationListPage> createState() => _NotificationListPageState();
}
class _NotificationListPageState extends State<NotificationListPage> {
late UserModel? _currentUser;
late Box<NotificationModel> _notificationBox;
bool _isLoading = true;
@override
void initState() {
super.initState();
_initializeData();
}
Future<void> _initializeData() async {
try {
final sessionService = SessionService();
final user = await sessionService.getCurrentUser();
_notificationBox = Hive.box<NotificationModel>('notifications');
if (mounted) {
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });
  }
  
  // Mark all as read
  if (user != null) {
    for (var notif in _notificationBox.values) {
      if (notif.userId == user.id && !notif.isRead) {
        notif.isRead = true;
        await notif.save();
      }
    }
  }
} catch (e) {
  print('❌ Error initializing notification page: $e');
  if (mounted) {
    setState(() => _isLoading = false);
  }
}
}
@override
Widget build(BuildContext context) {
if (_isLoading) {
return Scaffold(
appBar: AppBar(title: const Text('Notifikasi')),
body: const Center(child: CircularProgressIndicator()),
);
}
if (_currentUser == null) {
  return Scaffold(
    appBar: AppBar(title: const Text('Notifikasi')),
    body: const Center(child: Text('User tidak ditemukan')),
  );
}

final notifications = _notificationBox.values
    .where((n) => n.userId == _currentUser!.id)
    .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

return Scaffold(
  appBar: AppBar(
    title: const Text('Notifikasi'),
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => Navigator.pop(context),
    ),
  ),
  backgroundColor: Colors.grey[50],
  body: notifications.isEmpty
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Belum ada notifikasi',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        )
      : ListView.separated(
          itemCount: notifications.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey[200],
            height: 1,
          ),
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return _buildNotificationTile(notif);
          },
        ),
);
}
Widget _buildNotificationTile(NotificationModel notif) {
return Container(
color: Colors.white,
child: ListTile(
leading: _getNotificationIcon(notif.type),
title: Text(
notif.title,
style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 4),
Text(
notif.message,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: TextStyle(color: Colors.grey[700], fontSize: 13),
),
const SizedBox(height: 4),
Text(
notif.formattedTime,
style: TextStyle(fontSize: 12, color: Colors.grey[500]),
),
],
),
isThreeLine: true,
contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
onTap: () {
// Bisa navigate ke event detail jika diperlukan
print('Tapped notification: ${notif.title}');
},
),
);
}
Widget _getNotificationIcon(String type) {
switch (type) {
case 'payment_success':
return Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: Colors.green[50],
shape: BoxShape.circle,
),
child: Icon(Icons.check_circle, color: Colors.green[600], size: 24),
);
case 'event_upcoming':
return Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: Colors.blue[50],
shape: BoxShape.circle,
),
child: Icon(Icons.event, color: Colors.blue[600], size: 24),
);
default:
return Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: Colors.grey[100],
shape: BoxShape.circle,
),
child: Icon(Icons.notifications, color: Colors.grey[600], size: 24),
);
}
}
}