# Phase 11: Wolof Guardian — Real-Time Audio Monitoring

## Overview

Wolof Guardian monitors audio in real-time and automatically mutes inappropriate content spoken in Wolof or local French using Hugging Face's SpeechBrain wav2vec2 model.

## Current Status: Fully Implemented ✅

The complete pipeline is now implemented:
- **Model**: `speechbrain/asr-wav2vec2-dvoice-wolof` (Hugging Face)
- **Free tier**: ~30K requests/month
- **Accuracy**: 4.83% Character Error Rate
- **Audio Capture**: Android 10+ AudioPlaybackCapture API
- **Auto-Mute**: 5-second mute with visual overlay

## Architecture

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Audio Stream │───▶│  Wolof ASR   │───▶│   Keyword    │───▶│  Auto-Mute   │
│ (YouTube/    │    │   Model      │    │   Checker    │    │   + Overlay  │
│  Netflix)    │    │ (Hugging     │    │   (Vercel)   │    │              │
│              │    │    Face)     │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                                                            │
       │         WolofAudioService (Foreground Service)            │
       └────────────────────────────────────────────────────────────┘
```

## How It Works

1. **User taps "Start" on Wolof Guardian screen**
2. **System prompts for screen capture permission** (required for audio capture)
3. **WolofAudioService starts** as a foreground service with notification
4. **Audio is captured** from media apps in 3-second chunks
5. **Chunks are sent** to Vercel → Hugging Face for transcription
6. **Transcription checked** against blocked keywords
7. **If inappropriate content detected**:
   - Device audio muted for 5 seconds
   - Red overlay banner shown
   - Auto-unmute after timeout

## Files

### Android Service (`WolofAudioService.kt`)

```kotlin
class WolofAudioService : Service() {
    // Captures audio using AudioPlaybackCapture API
    // Requires Android 10+ (API 29)
    // Runs as foreground service with notification
    
    companion object {
        const val CHUNK_DURATION_MS = 3000  // 3 seconds per chunk
    }
}
```

### Accessibility Service Updates (`YaralmaAccessibilityService.kt`)

- Receives mute/unmute broadcasts from WolofAudioService
- Mutes device audio using AudioManager
- Shows red banner overlay during mute

### Flutter Service (`lib/services/wolof_guardian_service.dart`)

```dart
class WolofGuardianService {
  static Future<void> configure({required String apiBaseUrl}) async;
  static bool isAvailable();
  static bool isMonitoring();
  static Future<bool> isAudioCaptureSupported();
  static Future<bool> startMonitoring();
  static Future<void> stopMonitoring();
  static Future<List<String>> getBlockedWolofKeywords();
}
```

### Flutter Screen (`lib/screens/wolof_guardian/wolof_guardian_screen.dart`)

- Real-time monitoring toggle (Start/Stop button)
- Status indicator (Ready / Monitoring Active)
- Blocked keywords list
- Platform-specific messaging (Android 10+ required, iOS coming soon)

## API Endpoints

### `/api/wolof-transcribe` (POST)

Transcribes Wolof audio using Hugging Face Inference API.

**Request:**
```json
{
  "audioBase64": "base64-encoded-wav-audio"
}
```

**Response:**
```json
{
  "success": true,
  "transcription": "transcribed text in Wolof"
}
```

### `/api/wolof-check` (POST)

Checks transcription for blocked keywords.

**Request:**
```json
{
  "transcription": "text to check"
}
```

**Response:**
```json
{
  "success": true,
  "shouldMute": true,
  "foundKeywords": ["takk"]
}
```

## Permissions Required

### AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<service
    android:name=".WolofAudioService"
    android:exported="false"
    android:foregroundServiceType="mediaProjection" />
```

## Environment Variables

Add to Vercel:
```
HUGGINGFACE_API_TOKEN=hf_your_token_here
```

Get your free token at: https://huggingface.co/settings/tokens

## Flutter Configuration

```dart
// Configure the service with your Vercel URL
await WolofGuardianService.configure(
  apiBaseUrl: 'https://your-app.vercel.app'
);

// Start monitoring (prompts for permission)
final success = await WolofGuardianService.startMonitoring();

// Stop monitoring
await WolofGuardianService.stopMonitoring();
```

## Requirements

| Requirement | Status |
|------------|--------|
| Android 10+ (API 29) | Required for AudioPlaybackCapture |
| Accessibility Service | Required for muting |
| Screen Capture Permission | Prompted on start |
| Hugging Face Token | Required for ASR |
| Vercel Deployment | Required for APIs |

## Blocked Keywords (Default)

Stored in Supabase `blocked_keywords` table:
- Wolof inappropriate terms
- French inappropriate terms
- English inappropriate terms

Fallback keywords if Supabase unavailable:
- `takk`
- `jigeen bu nit`
- `gor bu nit`

## User Experience

### Notification
When monitoring is active, a persistent notification appears:
> "Wolof Guardian Active - Monitoring audio for inappropriate content"

### Mute Overlay
When inappropriate content detected:
- Red banner at top of screen
- Message: "🔇 Wolof Guardian: Inappropriate content detected"
- Auto-hides after 5 seconds

## Testing

1. Deploy Vercel APIs
2. Set `HUGGINGFACE_API_TOKEN` in Vercel
3. Install app on Android 10+ device
4. Configure service with Vercel URL
5. Enable Accessibility Service
6. Open Wolof Guardian screen
7. Tap "Start" and grant permission
8. Play video with Wolof audio
9. Verify mute when blocked content detected

## Limitations

- **Android only**: iOS audio capture requires different approach
- **Android 10+ only**: AudioPlaybackCapture API minimum requirement
- **Network required**: ASR runs on Hugging Face servers
- **3-second latency**: Chunk processing time
- **Limited free tier**: ~30K requests/month on Hugging Face
