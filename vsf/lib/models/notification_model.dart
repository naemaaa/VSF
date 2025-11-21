import 'package:hive/hive.dart';

part 'notification_model.g.dart';

@HiveType(typeId: 8)
class NotificationModel extends HiveObject {
@HiveField(0)
late String id;
@HiveField(1)
late String userId;
@HiveField(2)
late String type; // 'payment_success', 'event_upcoming', dll
@HiveField(3)
late String title;
@HiveField(4)
late String message;
@HiveField(5)
String? relatedEventId;
@HiveField(6)
late DateTime createdAt;
@HiveField(7)
late bool isRead;
NotificationModel({
required String id,
required String userId,
required String type,
required String title,
required String message,
this.relatedEventId,
DateTime? createdAt,
bool isRead = false,
}) {
this.id = id;
this.userId = userId;
this.type = type;
this.title = title;
this.message = message;
this.createdAt = createdAt ?? DateTime.now();
this.isRead = isRead;
}
String get formattedTime {
final now = DateTime.now();
final diff = now.difference(createdAt);
if (diff.inMinutes < 1) return 'Baru saja';
if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
if (diff.inHours < 24) return '${diff.inHours} jam lalu';
if (diff.inDays < 7) return '${diff.inDays} hari lalu';

return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
}
}