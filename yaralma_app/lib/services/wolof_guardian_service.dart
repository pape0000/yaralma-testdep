import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wolof Guardian: Real-time audio monitoring for inappropriate Wolof/French content.
///
/// Uses Hugging Face's SpeechBrain wav2vec2 model for Wolof ASR.
/// Free tier: ~30K requests/month via Hugging Face Inference API.
class WolofGuardianService {
  static String? _apiBaseUrl;

  /// Set the API base URL (your Vercel deployment URL).
  static void configure({required String apiBaseUrl}) {
    _apiBaseUrl = apiBaseUrl;
  }

  /// Check if Wolof Guardian is configured and available.
  static bool isAvailable() => _apiBaseUrl != null && _apiBaseUrl!.isNotEmpty;

  /// Transcribe audio using Hugging Face Wolof ASR.
  /// [audioBase64] - Base64 encoded WAV audio data.
  /// Returns the transcription text.
  static Future<String?> transcribeAudio(String audioBase64) async {
    if (!isAvailable()) return null;

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/wolof-transcribe'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'audioBase64': audioBase64}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['transcription'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check transcription for blocked Wolof/French keywords.
  /// Returns true if content should be muted.
  static Future<MuteCheckResult> checkForBlockedContent(String transcription) async {
    if (!isAvailable()) {
      return MuteCheckResult(shouldMute: false, foundKeywords: []);
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/wolof-check'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'transcription': transcription}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return MuteCheckResult(
          shouldMute: data['shouldMute'] as bool? ?? false,
          foundKeywords: List<String>.from(data['foundKeywords'] ?? []),
        );
      }
      return MuteCheckResult(shouldMute: false, foundKeywords: []);
    } catch (e) {
      return MuteCheckResult(shouldMute: false, foundKeywords: []);
    }
  }

  /// Process audio chunk: transcribe and check for blocked content.
  /// Returns true if inappropriate content detected (should mute).
  static Future<bool> processAudioChunk(String audioBase64) async {
    final transcription = await transcribeAudio(audioBase64);
    if (transcription == null || transcription.isEmpty) return false;

    final result = await checkForBlockedContent(transcription);
    return result.shouldMute;
  }

  /// Get blocked Wolof keywords from Supabase.
  static Future<List<String>> getBlockedWolofKeywords() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('blocked_keywords')
          .select('keyword')
          .inFilter('language', ['wolof', 'french']);

      return (response as List).map((k) => k['keyword'] as String).toList();
    } catch (e) {
      // Fallback to default keywords
      return ['takk', 'jigeen bu nit', 'gor bu nit'];
    }
  }
}

/// Result of checking transcription for blocked content.
class MuteCheckResult {
  final bool shouldMute;
  final List<String> foundKeywords;

  MuteCheckResult({required this.shouldMute, required this.foundKeywords});
}
