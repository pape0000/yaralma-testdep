import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/holy_lock_service.dart';

/// Holy Lock schedule screen: displays prayer times (Muslim) or Mass schedule (Christian).
class HolyLockScreen extends StatefulWidget {
  const HolyLockScreen({super.key});

  @override
  State<HolyLockScreen> createState() => _HolyLockScreenState();
}

class _HolyLockScreenState extends State<HolyLockScreen> {
  bool _loading = true;
  String? _error;
  Map<String, String>? _prayerTimes;
  List<String>? _massSundays;
  String? _faithShield;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Check if Supabase is initialized
      late final SupabaseClient supabase;
      try {
        supabase = Supabase.instance.client;
      } catch (e) {
        setState(() {
          _error = 'Supabase not configured. Check your environment.';
          _loading = false;
        });
        return;
      }

      final user = supabase.auth.currentUser;

      if (user == null) {
        setState(() {
          _error = 'Not authenticated. Please sign in.';
          _loading = false;
        });
        return;
      }

      // Fetch profile to get faith_shield and location
      final profile = await supabase
          .from('profiles')
          .select('faith_shield, latitude, longitude')
          .eq('id', user.id)
          .maybeSingle();

      final faithShield = profile?['faith_shield'] as String?;
      final lat = profile?['latitude'] as double?;
      final lng = profile?['longitude'] as double?;

      setState(() {
        _faithShield = faithShield;
      });

      if (lat != null && lng != null) {
        _position = Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      // Fetch lock windows or schedule based on faith
      if (faithShield == 'christian') {
        // Show upcoming Mass Sundays
        final sundays = await HolyLockService.getMassSundays(user.id);
        setState(() {
          _massSundays = sundays;
          _loading = false;
        });
      } else {
        // Muslim: show prayer times
        if (_position != null) {
          final times = await HolyLockService.fetchPrayerTimes(
            user.id,
            _position!.latitude,
            _position!.longitude,
          );
          setState(() {
            _prayerTimes = times;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Location not set. Tap "Set Location" to enable Holy Lock.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _setLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          setState(() {
            _error = 'Location permission denied.';
            _loading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        await supabase.from('profiles').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
        }).eq('id', user.id);
      }

      setState(() {
        _position = position;
      });

      await _loadData();
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Holy Lock'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError(theme)
                : _buildSchedule(theme),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _setLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Set Location'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedule(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_faithShield == 'christian') ...[
          Text(
            'Sunday Mass Schedule',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'YARALMA Shield locks the screen 08:00–11:30 every Sunday.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_massSundays != null && _massSundays!.isNotEmpty)
            ...(_massSundays!.map((s) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.church),
                    title: Text(s),
                    subtitle: const Text('08:00 – 11:30'),
                  ),
                )))
          else
            const Text('No upcoming Mass schedule found.'),
        ] else ...[
          Text(
            'Daily Prayer Times',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_position != null)
            Text(
              'Location: ${_position!.latitude.toStringAsFixed(3)}, ${_position!.longitude.toStringAsFixed(3)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          if (_prayerTimes != null)
            ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
              final time = _prayerTimes![prayer] ?? '--:--';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.mosque),
                  title: Text(prayer),
                  subtitle: Text('Lock at $time for 20 minutes'),
                ),
              );
            })
          else
            const Text('Prayer times not available.'),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _setLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Update Location'),
          ),
        ],
      ],
    );
  }
}
