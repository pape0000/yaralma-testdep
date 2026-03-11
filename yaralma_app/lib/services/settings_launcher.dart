import 'package:flutter/services.dart';

/// Launches Android Accessibility settings so the user can enable YARALMA Shield (FR-03).
class SettingsLauncher {
  static const _channel = MethodChannel('com.yaralma.yaralma_app/settings');

  /// Opens the system Accessibility settings screen. Android only; no-op on other platforms.
  static Future<bool> openAccessibilitySettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
