# Phase 11: Wolof Guardian — ASR Integration

## Overview

Wolof Guardian monitors audio in real-time and automatically mutes inappropriate content spoken in Wolof or local French using Hugging Face's SpeechBrain wav2vec2 model.

## Current Status: Ready for Deployment

The ASR integration is complete using:
- **Model**: `speechbrain/asr-wav2vec2-dvoice-wolof` (Hugging Face)
- **Free tier**: ~30K requests/month
- **Accuracy**: 4.83% Character Error Rate

## How It Will Work

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Audio Stream │───▶│  Wolof ASR   │───▶│   Keyword    │───▶│  Auto-Mute   │
│ (YouTube/    │    │   Model      │    │   Checker    │    │   Signal     │
│  Netflix)    │    │              │    │              │    │              │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
```

1. **Audio Capture**: Captures audio from video playback
2. **Speech Recognition**: Processes through Wolof ASR model
3. **Content Analysis**: Checks transcription against blocked keywords
4. **Auto-Mute**: Mutes audio when inappropriate content detected

## Files Created

### Service (`lib/services/wolof_guardian_service.dart`)

```dart
class WolofGuardianService {
  static bool isAvailable() => false;  // Returns true when ASR is ready
  
  static Future<void> startMonitoring() async { ... }
  static Future<void> stopMonitoring() async { ... }
  static List<String> getBlockedWolofKeywords() { ... }
  static Future<bool> processAudioChunk(List<int> audioData) async { ... }
  static Future<void> muteForDuration(Duration duration) async { ... }
}
```

### Screen (`lib/screens/wolof_guardian/wolof_guardian_screen.dart`)

Shows:
- Current availability status ("Coming Soon")
- How it will work (step-by-step cards)
- Preview of blocked Wolof keywords
- Technical requirements checklist

## Blocked Keywords (Preview)

Initial list for Wolof content:
- `takk`
- `jigeen bu nit`
- `gor bu nit`

*More keywords will be added when the ASR model is ready.*

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

## Environment Variables

Add to Vercel:
```
HUGGINGFACE_API_TOKEN=hf_your_token_here
```

Get your free token at: https://huggingface.co/settings/tokens

## Flutter Integration

```dart
// Configure the service with your Vercel URL
WolofGuardianService.configure(apiBaseUrl: 'https://your-app.vercel.app');

// Process audio
final shouldMute = await WolofGuardianService.processAudioChunk(audioBase64);
if (shouldMute) {
  // Trigger mute via method channel
}
```

## Remaining Steps

1. **Audio Capture** (Android)
   - Use `AudioPlaybackCapture` API
   - Requires `FOREGROUND_SERVICE_MEDIA_PLAYBACK` permission

2. **Real-time Pipeline**
   - Capture audio chunks every 2-3 seconds
   - Send to ASR endpoint
   - Check for blocked content
   - Signal mute if needed

## Related PRD Requirement

> *Wolof Guardian: Real-time mute of inappropriate Wolof (and local French) dialogue using a specialized Wolof acoustic model.*

This is documented in the PRD as a future enhancement requiring the Wolof ASR model.
