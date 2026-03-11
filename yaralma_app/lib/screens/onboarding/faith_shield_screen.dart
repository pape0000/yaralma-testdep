import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../services/profile_repository.dart';

/// FR-02: Faith Shield selection — Mouride, Tijaniyya, General Muslim, Christian.
class FaithShieldScreen extends StatelessWidget {
  const FaithShieldScreen({super.key});

  static const List<String> options = [
    'Mouride',
    'Tijaniyya',
    'General Muslim',
    'Christian',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faith Shield'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Select your Faith Shield. This sets prayer times or Mass lock for your family.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              ...options.map(
                (label) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      title: Text(label),
                      onTap: () => _onSelect(context, label),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.pathHome),
                child: const Text('Continue to setup'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _onSelect(BuildContext context, String faithShield) async {
    await ProfileRepository.saveFaithShield(faithShield);
    if (context.mounted) context.go(AppRoutes.pathHome);
  }
}
