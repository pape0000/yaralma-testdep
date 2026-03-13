# Phase 7: Holy Lock — Prayer Times & Mass

## Overview

Holy Lock automatically locks the child's screen during sacred times:
- **Muslim profiles**: Locks 20 minutes at each of the 5 daily prayers (Fajr, Dhuhr, Asr, Maghrib, Isha)
- **Christian profiles**: Locks Sunday mornings 08:00–11:30 for Mass

## Database Migration

Run this SQL in your Supabase Dashboard (SQL Editor):

```sql
-- See: supabase/migrations/002_lock_windows.sql
```

This adds:
- `latitude` and `longitude` columns to `profiles` for location-based prayer times
- `lock_windows` table to store scheduled lock periods

## API Endpoints (Vercel)

### 1. `/api/prayer-times` (POST)

Fetches prayer times from the Aladhan API and saves lock windows.

**Request:**
```json
{
  "userId": "uuid",
  "latitude": 14.716677,
  "longitude": -17.467686
}
```

**Response:**
```json
{
  "success": true,
  "date": "11-03-2026",
  "timings": {
    "Fajr": "06:12",
    "Dhuhr": "13:18",
    "Asr": "16:38",
    "Maghrib": "19:07",
    "Isha": "20:17"
  },
  "lockWindowsCount": 5
}
```

### 2. `/api/mass-schedule` (POST)

Creates lock windows for the next 4 Sundays (08:00–11:30).

**Request:**
```json
{
  "userId": "uuid"
}
```

### 3. `/api/cron/holy-lock` (GET)

Vercel Cron job that runs every 5 minutes:
- Checks `lock_windows` table for active windows (start_time ≤ now ≤ end_time)
- Sets `is_locked = true` for users with active windows
- Sets `is_locked = false` for users whose windows have ended

## Vercel Configuration

The cron job is configured in `vercel.json`:

```json
{
  "crons": [
    {
      "path": "/api/cron/holy-lock",
      "schedule": "*/5 * * * *"
    }
  ]
}
```

## Environment Variables (Vercel)

Add these to your Vercel project settings:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
CRON_SECRET=your-secret-token (optional, for securing cron endpoint)
```

## Flutter App

The Holy Lock screen (`lib/screens/holy_lock/holy_lock_screen.dart`):
1. Fetches the user's faith shield and location from Supabase
2. If Muslim, calls Aladhan API directly from the app and saves lock windows
3. If Christian, creates Mass schedule lock windows
4. Displays the schedule (prayer times or upcoming Sundays)

### Location Permission

The app uses the `geolocator` package to get the user's location. Permissions are configured in:
- **Android**: `AndroidManifest.xml` (ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION)
- **iOS**: `Info.plist` (NSLocationWhenInUseUsageDescription)

## How It Works

1. Parent opens Holy Lock screen and grants location permission
2. Prayer times are fetched and stored as `lock_windows` in Supabase
3. Vercel cron checks every 5 minutes:
   - If current time is within a lock window → `is_locked = true`
   - If lock window has ended → `is_locked = false`
4. Android Accessibility Service reads `is_locked` from SharedPreferences (synced from Supabase) and shows/hides the overlay

## Testing

1. Set your location (Dakar: 14.716677, -17.467686)
2. Check Supabase `lock_windows` table for new entries
3. Manually trigger the cron: `curl https://your-project.vercel.app/api/cron/holy-lock`
4. Verify `is_locked` updates in `profiles` table during prayer time
