import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

import '../../services/settings_launcher.dart';

/// Post-onboarding home: settings, accessibility setup (FR-03), account link placeholder.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('YARALMA'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Your shield is ready.',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isAndroid
                  ? 'Next: enable the YARALMA Shield in Settings > Accessibility, then link YouTube and Netflix.'
                  : _isIOS
                      ? 'Use this app to set up your family shield. The overlay runs on Android devices; here you can manage settings and view reports.'
                      : _isWeb
                          ? 'Testing in the browser. Use the Android or iOS app on a device for the full experience (including the overlay on the child\'s Android device).'
                          : 'Next: link YouTube and Netflix and manage your Holy Lock schedule.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            if (_isAndroid)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.accessibility_new),
                  title: const Text('Enable overlay (Accessibility)'),
                  subtitle: const Text('FR-03: Turn on YARALMA Shield in system settings'),
                  onTap: () async {
                    await SettingsLauncher.openAccessibilitySettings();
                  },
                ),
              )
            else if (_isIOS)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Overlay on Android'),
                  subtitle: const Text(
                    'The YARALMA Shield overlay runs on the child\'s Android device. On this iPhone you manage settings and get WhatsApp reports.',
                  ),
                ),
              )
            else if (_isWeb)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.web),
                  title: const Text('Browser testing'),
                  subtitle: const Text(
                    'You can test onboarding and navigation here. The overlay and device features need the Android or iOS app.',
                  ),
                ),
              ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Link YouTube / Google'),
                subtitle: const Text('OAuth — coming in Phase 9'),
                onTap: () {},
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Holy Lock schedule'),
                subtitle: const Text('Prayer times & Mass — Phase 7'),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
