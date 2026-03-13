import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks usage statistics for the Jom Report.
class UsageTracker {
  /// Increments a specific stat for today.
  static Future<void> incrementStat(String statName, {int amount = 1}) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now().toIso8601String().split('T')[0];

      // Upsert: insert or update today's stats
      await supabase.rpc('increment_usage_stat', params: {
        'p_user_id': user.id,
        'p_stat_date': today,
        'p_stat_name': statName,
        'p_amount': amount,
      });
    } catch (e) {
      // Silently fail - stats are non-critical
    }
  }

  /// Records screen time (call periodically, e.g., every minute).
  static Future<void> addScreenTime(int minutes) async {
    await incrementStat('screen_time_minutes', amount: minutes);
  }

  /// Records a honored lock (user didn't try to bypass).
  static Future<void> recordLockHonored() async {
    await incrementStat('locks_honored');
  }

  /// Records a bypassed lock attempt.
  static Future<void> recordLockBypassed() async {
    await incrementStat('locks_bypassed');
  }

  /// Records a blocked Shorts attempt.
  static Future<void> recordShortsBlocked() async {
    await incrementStat('shorts_blocked');
  }

  /// Records a blocked search.
  static Future<void> recordSearchBlocked() async {
    await incrementStat('searches_blocked');
  }
}
