# CALL ME OUT (智逃) 📱💨

**"Get out of awkward situations, instantly."**

This is an AI-powered fake call application built with **Kotlin Multiplatform (KMP)**. It simulates a realistic incoming phone call where an AI agent (powered by MiniMax) talks to you, helping you create a plausible excuse to leave any uncomfortable scenario.

![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-blue)
![Stack](https://img.shields.io/badge/Stack-Kotlin%20Multiplatform-purple)
![AI](https://img.shields.io/badge/AI-MiniMax-orange)

## ✨ Key Features

*   **Realism First**: Identical UI to native iOS/Android call screens.
*   **AI Conversation**: Talk naturally with the AI. It listens, thinks, and responds (powered by MiniMax LLM + TTS).
*   **Voice Cloning**: Record 5 seconds of audio to clone any voice (e.g., your boss, partner, or delivery guy) for the caller.
*   **Instant Trigger (秒弹)**:
    *   **iOS**: Support for **Action Button**, **Back Tap**, or **Shortcuts** via `coolphone://call` URL scheme. Launches immediately, bypassing splash screens.
    *   **Android**: Support for Deep Link (`adb shell am start -W -d "coolphone://call"`) or App Shortcuts.
*   **Audio Masking**: clever "filler sounds" (e.g., "Hmm", "Tock") to mask network latency and make the conversation feel instant.

## 🛠 Tech Stack

*   **Logic**: Kotlin Multiplatform (Shared Business Logic, Networking, State Management).
*   **UI**: Compose Multiplatform (UI shared across Android & iOS where possible), plus Native SwiftUI integration for iOS-specific polish.
*   **AI**: MiniMax API (Text generation + Speech synthesis + Voice Cloning).
*   **Architecture**: MVVM with `StateFlow`.

## 🚀 Getting Started

### Prerequisites
*   **Android Studio** (Koala or later recommended) with KMP plugin.
*   **Xcode** (15+ recommended) for iOS build.
*   **JDK 17**.

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/L3LeTrigger-F/CALL_ME_OUT.git
    cd CALL_ME_OUT
    ```

2.  **Open in Android Studio**:
    Open the `CoolPhoneKMP` directory as the project root.

3.  **Run on Android**:
    Select `composeApp` configuration and run on an Emulator/Device.
    *Note: If you see "Unable to resolve host" on Emulator, try a Cold Boot of the emulator to fix DNS.*

4.  **Run on iOS**:
    *   Open `CoolPhoneKMP/iosApp/iosApp.xcworkspace` in Xcode (or run from Android Studio if configured).
    *   Ensure to Trust your Developer Certificate if running on a real device.

## 🎮 How to Use "Instant Trigger"

The app is designed to be triggered discreetly:

### iOS
1.  Open **Shortcuts** app.
2.  Add action **"Open URL"**.
3.  Enter URL: `coolphone://call`
4.  Bind this shortcut to your **Action Button** (iPhone 15 Pro/16) or **Back Tap** (Accessibility settings).

### Android
Create a widget or shortcut that fires this Intent:
```bash
am start -W -a android.intent.action.VIEW -d "coolphone://call"
```

## 🏗 Project Structure

*   `composeApp`: Main KMP module.
    *   `commonMain`: Shared Code (UI, ViewModels, AI Service).
    *   `androidMain`: Android-specific implementations (e.g., MediaRecorder, ToneGenerator).
    *   `iosMain`: iOS-specific bridges.
*   `iosApp`: Native iOS project wrapper (hosting Compose view).

## 📄 License
MIT License.
