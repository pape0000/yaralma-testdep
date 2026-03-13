import 'package:flutter/material.dart';

import '../../services/wolof_guardian_service.dart';

/// Wolof Guardian screen with ASR integration status.
class WolofGuardianScreen extends StatefulWidget {
  const WolofGuardianScreen({super.key});

  @override
  State<WolofGuardianScreen> createState() => _WolofGuardianScreenState();
}

class _WolofGuardianScreenState extends State<WolofGuardianScreen> {
  List<String> _keywords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKeywords();
  }

  Future<void> _loadKeywords() async {
    final keywords = await WolofGuardianService.getBlockedWolofKeywords();
    setState(() {
      _keywords = keywords;
      _loading = false;
    });
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
            Card(
              color: isAvailable
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isAvailable ? Icons.hearing : Icons.hearing_disabled,
                      size: 48,
                      color: isAvailable
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAvailable ? 'Active' : 'Coming Soon',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            isAvailable
                                ? 'Monitoring audio for inappropriate content'
                                : 'Awaiting Wolof ASR model integration',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isAvailable
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
              'How It Will Work',
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
              description: 'Processes audio through a specialized Wolof ASR model.',
            ),
            const _StepCard(
              number: '3',
              title: 'Content Analysis',
              description: 'Checks transcription against blocked keywords list.',
            ),
            const _StepCard(
              number: '4',
              title: 'Auto-Mute',
              description: 'Mutes audio when inappropriate content is detected.',
            ),
            const SizedBox(height: 24),

        // Blocked keywords
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
            const SizedBox(height: 24),

            // Technical requirements
            Card(
              color: theme.colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          'Technical Requirements',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Wolof ASR model (in development)\n'
                      '• Audio capture API integration\n'
                      '• Real-time processing pipeline\n'
                      '• Blocked keywords database',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
