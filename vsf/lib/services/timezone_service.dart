class TimezoneHelper {
  static const String APP_TIMEZONE_NAME = 'WIB';
  static const int WIB_OFFSET_HOURS = 7; // UTC+7

  /// Ambil offset timezone device saat ini (dalam jam)
  static int getDeviceTimezoneOffsetHours() {
    return DateTime.now().timeZoneOffset.inHours;
  }

  /// Ambil nama timezone device
  /// 
  /// Returns: 'UTC+7', 'UTC+0', 'UTC-5', dll
  static String getDeviceTimezoneName() {
    final offset = getDeviceTimezoneOffsetHours();
    final sign = offset >= 0 ? '+' : '';
    return 'UTC$sign$offset';
  }

  /// Konversi dari local input (diasumsikan WIB) ke UTC untuk disimpan ke database
  /// 
  /// **GUNAKAN FUNCTION INI SAAT:**
  /// - User membuat event (create_event_page.dart)
  /// - User mengedit waktu event
  /// 
  /// **CONTOH:**
  /// ```
  /// User input: 09:00 (tanggal 15 Jan)
  /// Device: WIB (UTC+7)
  /// 
  /// Input DateTime: 2024-01-15 09:00:00
  /// Output: 2024-01-15 02:00:00Z (UTC)
  /// 
  /// Jika device di timezone lain (GMT):
  /// Input DateTime: 2024-01-15 09:00:00 (diasumsikan WIB)
  /// Adjustment: 09:00 - (0 - 7) = 16:00
  /// Output: 2024-01-15 16:00:00Z (UTC)
  /// ```
  static DateTime localWIBToUTC(DateTime localWIBTime) {
    final deviceOffset = getDeviceTimezoneOffsetHours();
    final offsetDifference = deviceOffset - WIB_OFFSET_HOURS;
    
    // Adjust untuk perbedaan timezone device vs WIB
    final adjusted = localWIBTime.subtract(Duration(hours: offsetDifference));
    final utc = adjusted.toUtc();
    
    print('🕐 [LocalWIB → UTC]');
    print('   Input (WIB): $localWIBTime');
    print('   Device offset: UTC+$deviceOffset');
    print('   WIB offset: UTC+$WIB_OFFSET_HOURS');
    print('   Offset diff: $offsetDifference jam');
    print('   Adjusted: $adjusted');
    print('   Output (UTC): $utc');
    
    return utc;
  }

  /// Konversi dari UTC (database) ke local display (WIB)
  /// 
  /// **GUNAKAN FUNCTION INI SAAT:**
  /// - Display event di activity_detail_page.dart
  /// - Edit event (populate form dari database)
  /// - Share event time ke user
  /// 
  /// **CONTOH:**
  /// ```
  /// Database: 2024-01-15 02:00:00Z (UTC)
  /// Device: WIB (UTC+7)
  /// 
  /// Offset diff: 7 - 0 = 7
  /// Output: 2024-01-15 09:00:00 (WIB)
  /// 
  /// Jika device di timezone lain (GMT):
  /// Offset diff: 7 - 0 = 7
  /// Output: 2024-01-15 09:00:00 (displayed as WIB)
  /// ```
  static DateTime utcToLocalWIB(DateTime utcTime) {
    final deviceOffset = getDeviceTimezoneOffsetHours();
    final offsetDifference = WIB_OFFSET_HOURS - deviceOffset;
    
    final local = utcTime.add(Duration(hours: offsetDifference));
    
    print('🕐 [UTC → LocalWIB]');
    print('   Input (UTC): $utcTime');
    print('   Device offset: UTC+$deviceOffset');
    print('   WIB offset: UTC+$WIB_OFFSET_HOURS');
    print('   Offset diff: $offsetDifference jam');
    print('   Output (WIB): $local');
    
    return local;
  }

  /// Konversi UTC ke timezone apapun yang dipilih user
  /// 
  /// **GUNAKAN FUNCTION INI SAAT:**
  /// - User memilih timezone berbeda di activity_detail_page.dart
  /// - Menampilkan waktu dalam multiple timezone
  /// 
  /// **PARAMETER:**
  /// - `utcTime`: waktu dari database (UTC)
  /// - `targetTimezone`: 'WIB', 'WITA', 'WIT', 'London', dll
  /// 
  /// **CONTOH:**
  /// ```
  /// Database: 2024-01-15 02:00:00Z (UTC)
  /// 
  /// convertUTCToTimezone(utcTime, 'WIB')
  /// → 2024-01-15 09:00:00
  /// 
  /// convertUTCToTimezone(utcTime, 'WITA')
  /// → 2024-01-15 10:00:00
  /// 
  /// convertUTCToTimezone(utcTime, 'London')
  /// → 2024-01-15 02:00:00
  /// ```
  static DateTime convertUTCToTimezone(
    DateTime utcTime,
    String targetTimezone,
  ) {
    final timezoneOffsets = {
      'WIB': 7,      // UTC+7
      'WITA': 8,     // UTC+8
      'WIT': 9,      // UTC+9
      'London': 0,   // UTC+0
      'GMT': 0,      // UTC+0
      'EST': -5,     // UTC-5
      'PST': -8,     // UTC-8
    };

    final offset = timezoneOffsets[targetTimezone] ?? 7; // Default WIB
    final converted = utcTime.add(Duration(hours: offset));

    print('🕐 [UTC → $targetTimezone]');
    print('   Input (UTC): $utcTime');
    print('   Target timezone: $targetTimezone (UTC+$offset)');
    print('   Output: $converted');

    return converted;
  }

  /// Format UTC time ke string dengan timezone yang dipilih
  /// 
  /// **CONTOH:**
  /// ```
  /// formatUTCToTimezone(utcTime, 'WIB', 'HH:mm')
  /// → '09:00'
  /// 
  /// formatUTCToTimezone(utcTime, 'WIB', 'dd MMM yyyy HH:mm')
  /// → '15 Jan 2024 09:00'
  /// ```
  static String formatUTCToTimezone(
    DateTime utcTime,
    String targetTimezone,
    String pattern,
  ) {
    final converted = convertUTCToTimezone(utcTime, targetTimezone);
    
    // Simple formatter (tanpa intl package untuk fleksibilitas)
    final formatted = _formatDateTime(converted, pattern);
    
    return formatted;
  }

  /// Validate jika start time < end time
  /// 
  /// **GUNAKAN SAAT:**
  /// - User submit form create/edit event
  /// 
  /// **RETURNS:**
  /// - `null` jika valid
  /// - `error message` jika invalid
  static String? validateEventTime(DateTime startTime, DateTime endTime) {
    if (startTime.isAfter(endTime)) {
      return 'Waktu mulai tidak boleh lebih besar dari waktu selesai';
    }

    if (startTime == endTime) {
      return 'Waktu mulai dan selesai tidak boleh sama';
    }

    if (endTime.difference(startTime).inHours < 1) {
      return 'Event harus minimal 1 jam';
    }

    return null; // Valid
  }

  /// Helper: Format DateTime dengan pattern sederhana
  static String _formatDateTime(DateTime dt, String pattern) {
    // Pattern examples: 'HH:mm', 'dd MMM yyyy', 'HH:mm dd MMM yyyy'
    
    // Simple implementation (bisa diganti dengan intl jika lebih kompleks)
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final month = _getMonthName(dt.month);
    final year = dt.year.toString();

    return pattern
        .replaceAll('HH', hour)
        .replaceAll('mm', minute)
        .replaceAll('dd', day)
        .replaceAll('MMM', month)
        .replaceAll('yyyy', year);
  }

  static String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  /// Debug: Print timezone info
  static void debugPrintTimezoneInfo() {
    print('\n╔═══════════════════════════════════════');
    print('║ 🕐 TIMEZONE DEBUG INFO');
    print('╠═══════════════════════════════════════');
    print('║ Device Timezone: ${getDeviceTimezoneName()}');
    print('║ Device Offset: ${getDeviceTimezoneOffsetHours()} jam');
    print('║ App Standard: $APP_TIMEZONE_NAME (UTC+$WIB_OFFSET_HOURS)');
    print('║ Now (Local): ${DateTime.now()}');
    print('║ Now (UTC): ${DateTime.now().toUtc()}');
    print('╚═══════════════════════════════════════\n');
  }
}