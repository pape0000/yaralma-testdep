# Phase 8: Jom Report — WhatsApp Sunday Summary

## Overview

The Jom Report is an automated weekly summary sent every Sunday morning via WhatsApp to parents with linked phone numbers. It provides insights into the child's digital activity for the past week.

## Database Migration

Run these in **Supabase Dashboard → SQL Editor**:

### 1. Usage Stats Table (`003_usage_stats.sql`)

```sql
-- See: supabase/migrations/003_usage_stats.sql
```

### 2. Increment Function (`increment_usage_stat.sql`)

```sql
-- See: supabase/functions/increment_usage_stat.sql
```

## API Endpoint

### `/api/cron/jom-report` (GET)

Vercel Cron job that runs every Sunday at 08:00 AM:

1. Fetches all users with `whatsapp_phone` set
2. Aggregates `usage_stats` for the past 7 days
3. Sends a formatted WhatsApp message via Twilio

## Vercel Configuration

Updated `vercel.json`:

```json
{
  "crons": [
    {
      "path": "/api/cron/holy-lock",
      "schedule": "*/5 * * * *"
    },
    {
      "path": "/api/cron/jom-report",
      "schedule": "0 8 * * 0"
    }
  ]
}
```

Schedule format: `0 8 * * 0` = Sunday at 08:00 UTC

## Environment Variables (Vercel)

Required:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
CRON_SECRET=your-secret (optional)
```

## Flutter Integration

The `UsageTracker` service (`lib/services/usage_tracker.dart`) provides methods to track stats:

```dart
// Track screen time (call every minute while app is active)
await UsageTracker.addScreenTime(1);

// Track honored lock
await UsageTracker.recordLockHonored();

// Track bypassed lock attempt
await UsageTracker.recordLockBypassed();

// Track blocked Shorts
await UsageTracker.recordShortsBlocked();

// Track blocked search
await UsageTracker.recordSearchBlocked();
```

## Sample Jom Report Message

```
Jom Report 🦁

📊 *Weekly Summary*
━━━━━━━━━━━━━━━━━━
📱 Screen time: 5h 32m
🙏 Holy Locks honored: 21
🚫 Shorts blocked: 8
🔍 Searches blocked: 2
━━━━━━━━━━━━━━━━━━

Keep guiding with love. 💚
```

## Testing

1. Manually trigger: `curl https://your-project.vercel.app/api/cron/jom-report`
2. Check Twilio logs for sent messages
3. Verify stats aggregation in Supabase

## Notes

- Stats are tracked per day, aggregated weekly
- The RPC function `increment_usage_stat` handles atomic upserts
- Christian profiles receive "Blessed Sunday!" greeting instead of "Jom Report 🦁"
