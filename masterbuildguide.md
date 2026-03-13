masterbuildguide.md
YARALMA: Master Build Guide (MVP Phase)
Stack: Flutter, Kotlin, Supabase, GitHub, Vercel, Cursor.
📋 Pre-Flight Checklist
Before starting Task 1, ensure you can log into all these accounts:
[ ] GitHub Online: Create a new empty repository named yaralma-app.
[ ] GitHub Desktop: Logged in and linked to your online account.
[ ] Supabase: New project created; keep the URL and Anon Key handy.
[ ] Cursor: Installed with the Flutter extension.
[ ] Vercel: Logged in and connected to your GitHub account.
[ ] Twilio: Account created (needed for Phase 4 WhatsApp); use Sandbox for development.
[ ] (Later, Phase 9) Google Cloud: Project created; YouTube Data API v3 enabled; OAuth consent configured.

✅ Before You Start Coding — Decisions & Setup
- **Supabase Auth:** Enable Auth in Supabase (Dashboard > Authentication > Providers). Use at least Email or Google so `auth.users` exists and `profiles.id` can reference it. After creating the `profiles` table, add **RLS policies** in SQL Editor so users can read/update their own row, e.g. `create policy "Users can read own profile" on profiles for select using (auth.uid() = id);` and `create policy "Users can update own profile" on profiles for update using (auth.uid() = id);`. (Use `insert` with `with check` for sign-up if you create profile on first login.)
- **WhatsApp → which user?** When someone sends LOCK via WhatsApp, the backend must know which Supabase profile to update. Add a way to link a phone number to a profile: e.g. a column `profiles.whatsapp_phone` (E.164) or a small table `user_whatsapp(user_id, phone)`. When the parent registers, they enter their WhatsApp number; the Twilio webhook uses the incoming "From" number to look up the profile and set `is_locked` for that user.
- **Twilio webhook:** After deploying the Vercel function, in Twilio Console go to WhatsApp Sandbox (or your WhatsApp sender) and set the "When a message comes in" URL to `https://your-app.vercel.app/api/whatsapp` (and POST).
- **Parent vs child device:** The same app runs on the parent's phone (setup) and the child's device (overlay). The child device must subscribe to the correct profile (e.g. same Supabase user if the parent logs in on both, or a "link code" flow so the child device is tied to the parent's profile). Decide early: single-account (parent logs in on child device) or link-by-code so the child device only gets overlay + realtime for that family.
- **Flutter package name:** When you run `flutter create .`, use an org so the Android package is correct from the start, e.g. `flutter create --org com.yaralma .`. Then the Kotlin path will be `com/yaralma/yaralma_app/` (or similar); adjust the Phase 3 path and manifest if you use a different org.

🏗 Phase 1: Local Project Foundation
Goal: Initialize the project and link it to version control.
Repository Setup:
Open GitHub Desktop.
File > Clone Repository > Select yaralma-app from the list.
Choose a local folder (e.g., Documents/Projects/yaralma-app).
Flutter Initialization:
Open Cursor. Use File > Open Folder and select your yaralma-app folder.
Open the terminal (Ctrl + ` ) and run: flutter create .
Open pubspec.yaml and add these under dependencies:
supabase_flutter: ^2.0.0
http: ^1.1.0
provider: ^6.1.1


First Commit:
Go to GitHub Desktop.
Add a summary: "Initial Flutter Scaffold".
Click Commit to Main, then click Push Origin.
🗄 Phase 2: Supabase Backend & Database
Goal: Set up the "Brain" that will store user profiles and commands.
Database Tables (SQL):
Go to your Supabase Dashboard > SQL Editor.
Paste and run this to create the core table:
create table profiles (
  id uuid references auth.users on delete cascade,
  parent_name text,
  faith_shield text, -- 'mouride', 'christian', etc.
  is_locked boolean default false,
  updated_at timestamp with time zone default now(),
  primary key (id)
);
alter table profiles enable row level security;
-- Then add RLS policies (see "Before You Start Coding" above) so users can read/update their own profile.


Enable Real-time:
Go to Database > Replication.
Enable the "Realtime" toggle for the profiles table. This allows the child's app to "hear" the lock command instantly.
🦁 Phase 3: The Android Shield (Kotlin/Accessibility)
Goal: Build the invisible service that draws the blur over YouTube/Netflix.
Kotlin Setup:
In Cursor, navigate to android/app/src/main/kotlin/com/example/yaralma_app/.
Create a file: YaralmaAccessibilityService.kt.
Cursor AI Generation:
Press Cmd+L (or Ctrl+L) in Cursor and ask:"I am building an Android Accessibility Service in Kotlin for my Flutter app. Please write the code for YaralmaAccessibilityService.kt that detects if the active app is 'com.google.android.youtube' or 'com.netflix.mediaclient'. If my Supabase 'is_locked' variable is true, show a full-screen red overlay."
Manifest Update:
Open android/app/src/main/AndroidManifest.xml.
Ask Cursor to add the necessary <service> tags and BIND_ACCESSIBILITY_SERVICE permissions.
💬 Phase 4: WhatsApp Bot (Vercel & Twilio)
Goal: Allow Demba and Joseph to control the app via WhatsApp.
The API Function:
In your root folder, create a folder api and a file inside it called whatsapp.js.
Prompt Cursor:"Create a Node.js serverless function for Vercel. It should receive a WhatsApp message from Twilio. If the message is 'LOCK', it must connect to Supabase and set 'is_locked' to true for the user. Use the Supabase Service Role Key for authentication."
Deploy to Vercel:
Push your code to GitHub via GitHub Desktop.
Go to Vercel Dashboard > Add New > Project > Select yaralma-app.
Crucial: Add your SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in the Vercel Environment Variables settings.
Deploy. Vercel will give you a URL like https://yaralma-app.vercel.app/api/whatsapp.
🧪 Phase 5: Testing & Verification
Run the App: In Cursor, press F5 to run on an Android Emulator or connected device.
Enable Accessibility: On the Android device, go to Settings > Accessibility and turn on YARALMA Shield.
The WhatsApp Test:
Use the Twilio Sandbox to send "LOCK" to your assigned sandbox number.
Watch your Supabase dashboard: Does is_locked turn to true?
Watch the device: Does the red overlay appear over YouTube?

📜 Phase 6: Onboarding — Value Agreement & Faith Shield (Flutter)
Goal: Implement the mandatory flow before settings (per PRD FR-01, FR-02).
- In the Flutter app, add an initial flow that shows the Six Pillars (Teranga, Jom, Kersa, Sutura, Muñ, Ngor) and requires acknowledgment before continuing.
- Add a Faith Shield selection screen: Mouride, Tijaniyya, General Muslim, or Christian. Persist the choice to the Supabase `profiles.faith_shield` column.
- After Faith selection, run the guided Android Accessibility permission flow (FR-03) so the parent enables the YARALMA Shield in system settings.

⏳ Phase 7: Holy Lock — Prayer Times & Mass (Backend + Overlay)
Goal: Full-screen lock during Islamic prayer times and Sunday Mass (FR-09, FR-10, FR-11).
- **Prayer times API:** Use a free API by location, e.g. **Aladhan API** (https://aladhan.com/prayer-times-api — free, no API key for basic use) or **IslamicAPI** (free tier with sign-up). Pass the user's lat/lng (from GPS or stored in profile); get daily prayer times and write lock windows to Supabase. If the chosen API requires a key, store it in Supabase secrets or Vercel env.
- Add a schedule table or config in Supabase (e.g. lock_windows: user_id, start_time, end_time, type: 'prayer' | 'mass' | 'ramadan' | 'lent'). Compute prayer times from the API above; for Christian profiles add Sunday 08:00–11:30.
- The Android overlay already reacts to `is_locked`. Extend the backend (or a scheduled job) to set `is_locked = true` during these windows and clear it after.
- Optional for MVP: Ramadan Mode and Lent Mode as automatic schedule adjustments (FR-11).

📊 Phase 8: Jom Report — WhatsApp Sunday Summary (Vercel + Twilio)
Goal: Automated Sunday morning summary per family (FR-12).
- Add a Vercel Cron (or scheduled function) that runs Sunday morning. For each user with WhatsApp linked, query Supabase for the past week's stats (e.g. screen time, locks honored, Shorts blocked) and send a formatted "Jom Report" via the Twilio WhatsApp API.
- Reuse the same Twilio/WhatsApp configuration as the LOCK bot.

🦁 Phase 9: YouTube Guardian — Shorts, Search, Explore/Kids (API + Overlay)
Goal: Align with FR-04, FR-05, FR-06.
- **Note:** Google does not offer a public Family Link API. Implement via **YouTube Data API v3** (OAuth already in scope) and, where available, restricted/Explore Mode or YouTube Kids; use the overlay to hide the Shorts shelf or search bar when the API cannot enforce it.
- Use YouTube/Google APIs to disable or hide the Shorts shelf, enforce Explore Mode for 9–12 or YouTube Kids for 3–8, and intercept search: clear or block queries containing blocked Wolof/French keywords (maintain a blocklist in Supabase or config).
- The overlay can complement API restrictions (e.g. hide search bar or show a soft block message when forbidden terms are detected).

🎬 Phase 10: Netflix Overlay — Blur List & Thumbnails (Overlay + Data)
Goal: Real-time blur and catalog filtering (FR-07, FR-08).
- Create or ingest the "Lion Guardian" list: community-sourced timestamps (title/episode + start/end) for scenes to blur. Store in Supabase or a static config the overlay can fetch.
- The accessibility service overlays a blur when the current playback time matches a timestamp. For catalog thumbnails, maintain a list of title IDs (or images) to hide in the Netflix UI and implement hiding/blurring in the overlay when those thumbnails are on screen.

👂 Phase 11: Wolof Guardian (ASR) — Real-Time Audio Monitoring ✅
Goal: Real-time mute of inappropriate Wolof (and local French) dialogue (PRD: Wolof acoustic model).
- **ASR Model:** SpeechBrain wav2vec2 for Wolof via Hugging Face Inference API (free tier: ~30K requests/month).
- **Audio Capture:** Android 10+ AudioPlaybackCapture API via foreground service (`WolofAudioService.kt`).
- **Pipeline:** 3-second audio chunks → Vercel API → Hugging Face ASR → keyword check → auto-mute.
- **Auto-Mute:** Device audio muted for 5 seconds with red banner overlay when blocked content detected.
- **Flutter UI:** Start/Stop monitoring toggle on Wolof Guardian screen.
- **Requires:** `HUGGINGFACE_API_TOKEN` in Vercel environment variables.

💡 Troubleshooting for Beginners
Permissions: If the overlay doesn't appear, 99% of the time the Accessibility Service isn't turned on in the phone's settings.
Supabase Connection: If the data isn't updating, check the "Edge Function" logs in Vercel to see if there is an error in the Supabase URL or Key.
Cursor Help: If you get a red underline (error), highlight the code and press Cmd+K (or Ctrl+K) and type "Fix this error."
