# MailWeave

An Android-only email client built with Flutter that fetches mail and displays
conversations as threaded **tree branches**. Replies are shown in a structured
branching layout so you can follow the flow of a conversation at a glance.

## Features

- **Android only** - tailored and optimized for Android devices.
- **Threaded conversations** - mails are organized into reply trees, showing the
  branching structure of who replied to what.
- **Tree branching view** - replies render as connected branches so the
  conversation history is easy to trace.

## Tech Stack

- **Flutter** - cross-platform UI toolkit (configured for Android here)
- **Dart** - application language

## Custom Fonts

MailWeave bundles two custom fonts in `assets/fonts/`:

| Family | Style | Weights |
| --- | --- | --- |
| Comfortaa | Rounded geometric sans (headings/display) | 300 Light, 400 Regular, 500 Medium, 700 Bold |
| Playwrite US Modern | Handwriting accent font | 100 Thin, 200 ExtraLight, 300 Light, 400 Regular |

Fonts are declared in `pubspec.yaml` and can be used through
`ThemeData` / `TextStyle` via the family names above.

## Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.12.1`)
- An Android device or emulator

### Install dependencies

```sh
flutter pub get
```

### Run the app

```sh
flutter run
```

### Build a release APK

```sh
flutter build apk
```

## Project Structure

```
mailweave/
├─ android/          # Android platform files (Android-only build)
├─ assets/
│  └─ fonts/          # Comfortaa & Playwrite US Modern font files
├─ lib/               # Dart application source
└─ pubspec.yaml       # Project metadata, dependencies, and font/asset config
```

## Versioning

The current version is `1.0.0+1` (see `pubspec.yaml`), following the
`major.minor.patch+build` convention where `build` maps to the Android
`versionCode`.
