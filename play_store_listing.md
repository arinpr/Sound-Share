# SoundShare — Google Play Store Listing & Submission Guide

## 📱 App Listing Metadata

### App Title (Max 30 characters)
`SoundShare: Audio & BeatSync`

### Short Description (Max 80 characters)
`Share audio with nearby Bluetooth devices and feel the music with BeatSync.`

### Full Description (Max 4000 characters)
```text
SoundShare is the ultimate audio companion for Android, designed to let you share sound effortlessly and feel every beat.

✨ KEY FEATURES:

🎧 REAL-TIME AUDIO SHARING
• Connect and stream audio to multiple Bluetooth headphones and speakers simultaneously.
• Ultra-low latency transmission engineered for synchronized group listening.
• Seamless device management: easily discover, pair, and manage nearby Bluetooth audio receivers.

🎵 BEATSYNC — FEEL THE MUSIC
• Transform your listening experience with real-time audio-haptic feedback.
• Feel kicks, drops, snares, and sub-bass frequencies through synchronized vibration patterns.
• Independent operation: Use BeatSync with internal phone audio or while sharing to Bluetooth receivers.
• Smart rate limiting and safety cooldowns to protect battery life and user comfort.
• Customizable controls: Adjust Haptic Intensity, Beat Sensitivity, and Bass Response to match your vibe.

🎨 PREMIUM DESIGN & ACCESSIBILITY
• Clean, modern interface designed with fluid 60fps waveform visualizations.
• Accessible animations with full support for reduced-motion settings.
• Background audio support via notification controls with zero disruptive ads.

🔒 PRIVACY FIRST
SoundShare processes audio analysis entirely on-device in real-time. No microphone recordings or audio streams are ever stored or uploaded to remote servers.
```

---

## 🛡️ Play Console Data Safety & Permissions Guide

| Permission | Reason for Google Play Review |
|---|---|
| **Nearby Devices (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`)** | Used exclusively to discover, connect, and stream audio to secondary Bluetooth audio headphones/speakers. |
| **Microphone / Audio Capture (`RECORD_AUDIO`)** | Used in real-time by BeatSync for frequency/transient beat detection. Audio data is analyzed in memory and immediately discarded; **no audio is recorded, saved, or transmitted**. |
| **Foreground Service (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`)** | Keeps audio streaming and BeatSync haptics active when the app is in the background or screen is locked. |
| **Vibration (`VIBRATE`)** | Triggers synchronized haptic feedback corresponding to detected audio rhythms. |
| **Notifications (`POST_NOTIFICATIONS`)** | Displays ongoing session controls (Play/Pause/Stop) in the system notification shade. |

---

## 📋 Data Safety Questionnaire Answers

- **Does your app collect or share any user data?** ➔ **No**
- **Is all user data ephemeral?** ➔ **Yes** (Audio buffers are processed in RAM and discarded).
- **Does your app contain ads?** ➔ **No**
- **Target Audience / Age Rating** ➔ **Everyone (PEGI 3 / ESRB Everyone)**
