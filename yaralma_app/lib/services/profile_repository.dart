import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Faith Shield display names to DB values (profiles.faith_shield).
const Map<String, String> faithShieldToDb = {
  'Mouride': 'mouride',
  'Tijaniyya': 'tijaniyya',
  'General Muslim': 'general_muslim',
  'Christian': 'christian',
};

/// Persists and reads profile data (Phase 2 + Phase 6).
class ProfileRepository {
  static SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Returns the current user id if signed in, else null.
  static String? get currentUserId => _client?.auth.currentUser?.id;

  /// Saves Faith Shield for the current user. No-op if not signed in.
  static Future<void> saveFaithShield(String displayValue) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    final value = faithShieldToDb[displayValue] ?? displayValue.toLowerCase().replaceAll(' ', '_');
    await client.from('profiles').upsert(
      {
        'id': userId,
        'faith_shield': value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'id',
    );
  }
}
