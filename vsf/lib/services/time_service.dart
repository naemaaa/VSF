import 'package:intl/intl.dart';

class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  final Map<String, int> _timezoneOffsets = {
    'WIB': 7,   
    'WITA': 8,  
    'WIT': 9,   
    'London': 0, 
  };

  DateTime convertToTimezone(DateTime utcTime, String timezone) {
    final offset = _timezoneOffsets[timezone] ?? 7; // Default WIB
    return utcTime.add(Duration(hours: offset));
  }

  String formatTime(DateTime utcTime, String timezone) {
    final localTime = convertToTimezone(utcTime, timezone);
    return DateFormat('HH:mm').format(localTime);
  }

  String formatTimeRange(DateTime startUtc, DateTime endUtc, String timezone) {
    final startLocal = convertToTimezone(startUtc, timezone);
    final endLocal = convertToTimezone(endUtc, timezone);
    return '${DateFormat('HH:mm').format(startLocal)} - ${DateFormat('HH:mm').format(endLocal)}';
  }

  String formatDate(DateTime utcTime, String timezone) {
    final localTime = convertToTimezone(utcTime, timezone);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return '${days[localTime.weekday % 7]}, ${localTime.day} ${months[localTime.month - 1]} ${localTime.year}';
  }

  String formatDateTime(DateTime utcTime, String timezone) {
    final localTime = convertToTimezone(utcTime, timezone);
    return DateFormat('dd/MM/yyyy HH:mm').format(localTime);
  }

  List<String> getAvailableTimezones() {
    return _timezoneOffsets.keys.toList();
  }

  String getTimezoneLabel(String timezone) {
    final offset = _timezoneOffsets[timezone];
    if (offset == null) return timezone;
    final sign = offset >= 0 ? '+' : '';
    return '$timezone (UTC$sign$offset)';
  }
}
