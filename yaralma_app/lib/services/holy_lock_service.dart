import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing Holy Lock schedules (prayer times & Mass).
class HolyLockService {
  /// Fetches prayer times from Aladhan API and saves lock windows.
  /// Returns a map of prayer name to time string (e.g. {"Fajr": "05:30"}).
  static Future<Map<String, String>> fetchPrayerTimes(
    String userId,
    double latitude,
    double longitude,
  ) async {
    final today = _formatDate(DateTime.now());
    final url = Uri.parse(
      'https://api.aladhan.com/v1/timings/$today'
      '?latitude=$latitude&longitude=$longitude&method=3',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch prayer times');
    }

    final data = json.decode(response.body);
    final timings = data['data']?['timings'] as Map<String, dynamic>?;

    if (timings == null) {
      throw Exception('Invalid response from prayer times API');
    }

    // Save lock windows to Supabase
    await _savePrayerLockWindows(userId, timings, today);

    return {
      'Fajr': timings['Fajr'] ?? '',
      'Dhuhr': timings['Dhuhr'] ?? '',
      'Asr': timings['Asr'] ?? '',
      'Maghrib': timings['Maghrib'] ?? '',
      'Isha': timings['Isha'] ?? '',
    };
  }

  static Future<void> _savePrayerLockWindows(
    String userId,
    Map<String, dynamic> timings,
    String dateStr,
  ) async {
    final supabase = Supabase.instance.client;
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    const lockDurationMinutes = 20;

    // Parse date string DD-MM-YYYY
    final parts = dateStr.split('-');
    final isoDatePrefix = '${parts[2]}-${parts[1]}-${parts[0]}';
    final startOfDay = DateTime.parse('${isoDatePrefix}T00:00:00Z');
    final endOfDay = DateTime.parse('${isoDatePrefix}T23:59:59Z');

    // Delete existing prayer lock windows for today
    await supabase
        .from('lock_windows')
        .delete()
        .eq('user_id', userId)
        .inFilter('lock_type', ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
        .gte('start_time', startOfDay.toIso8601String())
        .lte('start_time', endOfDay.toIso8601String());

    // Build new lock windows
    final lockWindows = <Map<String, dynamic>>[];

    for (final prayer in prayers) {
      final timeStr = timings[prayer] as String?;
      if (timeStr == null || timeStr.isEmpty) continue;

      final startTime = DateTime.parse('${isoDatePrefix}T$timeStr:00');
      final endTime = startTime.add(const Duration(minutes: lockDurationMinutes));

      lockWindows.add({
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'lock_type': prayer.toLowerCase(),
      });
    }

    if (lockWindows.isNotEmpty) {
      await supabase.from('lock_windows').insert(lockWindows);
    }
  }

  /// Gets upcoming Mass Sundays for a Christian user.
  static Future<List<String>> getMassSundays(String userId) async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();

    // Check if Mass schedule exists in lock_windows
    final existing = await supabase
        .from('lock_windows')
        .select('start_time')
        .eq('user_id', userId)
        .eq('lock_type', 'mass')
        .gte('start_time', now.toIso8601String())
        .order('start_time', ascending: true)
        .limit(4);

    if (existing != null && (existing as List).isNotEmpty) {
      return (existing as List)
          .map((row) => _formatSundayDate(row['start_time'] as String))
          .toList();
    }

    // Create Mass schedule for next 4 Sundays
    final sundays = _getNextSundays(4);
    final lockWindows = sundays.map((sunday) {
      final dateStr = sunday.toIso8601String().split('T')[0];
      return {
        'user_id': userId,
        'start_time': '${dateStr}T08:00:00Z',
        'end_time': '${dateStr}T11:30:00Z',
        'lock_type': 'mass',
      };
    }).toList();

    await supabase.from('lock_windows').insert(lockWindows);

    return sundays.map((s) => _formatSundayDate(s.toIso8601String())).toList();
  }

  static List<DateTime> _getNextSundays(int count) {
    final sundays = <DateTime>[];
    var d = DateTime.now();

    while (sundays.length < count) {
      d = d.add(const Duration(days: 1));
      if (d.weekday == DateTime.sunday) {
        sundays.add(d);
      }
    }

    return sundays;
  }

  static String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day-$month-${d.year}';
  }

  static String _formatSundayDate(String isoString) {
    final date = DateTime.parse(isoString);
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Sunday, ${months[date.month]} ${date.day}, ${date.year}';
  }
}
