import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../services/wolof_guardian_service.dart';

/// Wolof Guardian screen with real-time audio monitoring.
class WolofGuardianScreen extends StatefulWidget {
  const WolofGuardianScreen({super.key});

  @override
  State<WolofGuardianScreen> createState() => _WolofGuardianScreenState();
}

class _WolofGuardianScreenState extends State<WolofGuardianScreen> {
  List<String> _keywords = [];
  bool _loading = true;
  bool _isMonitoring = false;
  bool _audioCaptureSupported = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _loadKeywords();
    _checkAudioCaptureSupport();
  }

  Future<void> _loadKeywords() async {
    try {
      final keywords = await WolofGuardianService.getBlockedWolofKeywords();
      if (mounted) {
        setState(() {
          _keywords = keywords;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load keywords';
        });
      }
    }
  }

  Future<void> _checkAudioCaptureSupport() async {
    if (kIsWeb || !_isAndroid) {
      setState(() => _audioCaptureSupported = false);
      return;
    }

    final supported = await WolofGuardianService.isAudioCaptureSupported();
    if (mounted) {
      setState(() {
        _audioCaptureSupported = supported;
        _isMonitoring = WolofGuardianService.isMonitoring();
      });
    }
  }

  bool get _isAndroid {
    try {
      return !kIsWeb && Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      await WolofGuardianService.stopMonitoring();
      if (mounted) {
        setState(() => _isMonitoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio monitoring stopped')),
        );
      }
    } else {
      final success = await WolofGuardianService.startMonitoring();
      if (mounted) {
        if (success) {
          setState(() => _isMonitoring = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio monitoring started')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start monitoring. Please grant permission.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = WolofGuardianService.isAvailable();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wolof Guardian'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Status card
            _buildStatusCard(theme, isAvailable),
            const SizedBox(height: 16),

            // Real-time monitoring toggle (Android only)
            if (_isAndroid && _audioCaptureSupported && isAvailable)
              _buildMonitoringToggle(theme),

            if (_isAndroid && !_audioCaptureSupported)
              _buildUnsupportedCard(theme),

            if (!_isAndroid && !kIsWeb)
              _buildIOSCard(theme),

            if (kIsWeb)
              _buildWebCard(theme),

            const SizedBox(height: 24),

            // Description
            Text(
              'What is Wolof Guardian?',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Wolof Guardian uses Automatic Speech Recognition (ASR) to detect inappropriate content in Wolof and local French during video playback. When detected, the audio is temporarily muted to protect young viewers.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // How it works
            Text(
              'How It Works',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const _StepCard(
              number: '1',
              title: 'Audio Capture',
              description: 'Captures audio stream from YouTube or Netflix playback.',
            ),
            const _StepCard(
              number: '2',
              title: 'Speech Recognition',
              description: 'Processes audio through SpeechBrain Wolof ASR model.',
            ),
            const _StepCard(
              number: '3',
              title: 'Content Analysis',
              description: 'Checks transcription against blocked keywords list.',
            ),
            const _StepCard(
              number: '4',
              title: 'Auto-Mute',
              description: 'Mutes audio for 5 seconds when inappropriate content detected.',
            ),
            const SizedBox(height: 24),

            // Blocked keywords
            _buildKeywordsSection(theme),
            const SizedBox(height: 24),

            // Technical info
            _buildTechnicalInfoCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme, bool isAvailable) {
    final isActive = _isMonitoring && isAvailable;

    return Card(
      color: isActive
          ? theme.colorScheme.primaryContainer
          : isAvailable
              ? theme.colorScheme.surfaceContainerHighest
              : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isActive
                  ? Icons.graphic_eq
                  : isAvailable
                      ? Icons.hearing
                      : Icons.hearing_disabled,
              size: 48,
              color: isActive
                  ? theme.colorScheme.primary
                  : isAvailable
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive
                        ? 'Monitoring Active'
                        : isAvailable
                            ? 'Ready'
                            : 'Not Configured',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? theme.colorScheme.onPrimaryContainer
                          : isAvailable
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.error,
                    ),
                  ),
                  Text(
                    isActive
                        ? 'Listening for inappropriate content...'
                        : isAvailable
                            ? 'Tap below to start monitoring'
                            : 'Configure API URL to enable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isActive
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringToggle(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isMonitoring ? Icons.stop_circle : Icons.play_circle,
                  color: _isMonitoring ? Colors.red : theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Real-Time Monitoring',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isMonitoring
                            ? 'Capturing audio from media apps'
                            : 'Start to monitor YouTube & Netflix audio',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: _toggleMonitoring,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isMonitoring ? Colors.red : null,
                  ),
                  child: Text(_isMonitoring ? 'Stop' : 'Start'),
                ),
              ],
            ),
            if (_isMonitoring) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A notification will appear while monitoring. Audio will auto-mute for 5 seconds when inappropriate content is detected.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnsupportedCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Audio capture requires Android 10 or higher.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.apple, color: theme.colorScheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'iOS audio capture is coming in a future update.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.web, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Audio monitoring is only available on Android devices.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeywordsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Blocked Keywords',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (!_loading)
              Text(
                '${_keywords.length} keywords',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _keywords
                .map((k) => Chip(
                      label: Text(k),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildTechnicalInfoCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Technical Details',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TechRow(icon: Icons.memory, label: 'ASR Model', value: 'SpeechBrain wav2vec2'),
            _TechRow(icon: Icons.cloud, label: 'Provider', value: 'Hugging Face'),
            _TechRow(icon: Icons.timer, label: 'Chunk Size', value: '3 seconds'),
            _TechRow(icon: Icons.volume_off, label: 'Mute Duration', value: '5 seconds'),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text(number),
        ),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TechRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
