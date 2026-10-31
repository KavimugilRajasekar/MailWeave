# MailWeave

An Android-only email client built with Flutter. MailWeave fetches a user's
Gmail and (eventually) displays conversations as threaded **tree branches** —
replies render as connected branches so you can follow the flow of a
conversation at a glance.

> **Status:** The onboarding, Google sign-in, secure session handling, and a
> themed home placeholder are in place. The core threaded tree-branch mail
> view is the main feature still to be built.

---

## What works so far

### Onboarding (first launch)
- A single-slide intro screen (`lib/screens/intro_screen.dart`) using the
  `intro_slider` package — a Lottie animation, a "Welcome to / Mail Weave"
  wordmark, and a description where the word "untangled" is emphasized in a
  grey tone between the kicker and the wordmark.
- A bottom call-to-action that **traces a circular outline** from the top all
  the way around over ~4 seconds (an `AnimationController` driving a
  determinate `CircularProgressIndicator`). The arrow icon is hidden while the
  outline draws, then fades in and becomes tappable to continue.
- Whether the intro has been seen is remembered via `SharedPreferences`
  (`intro_seen`), so it only shows on the first launch.

### Authentication
- Google OAuth sign-in via `google_sign_in`, bridged to the Gmail API through
  `extension_google_sign_in_as_googleapis_auth`.
- Scope requested: `gmail.readonly`.
- The login screen (`lib/screens/login_screen.dart`) shows a centered brand
  (Lottie + wordmark + subtitle) and a **bottom-pinned "Sign in with Google"
  button** that is **outlined** (transparent fill, 2 px light-blue border) with
  **black text** and a black loading spinner.
- Credentials (`AccessCredentials`) are serialized to JSON and stored in
  `flutter_secure_storage` (Android Keystore) — not plain shared storage.
- Session restore tries the native Google Sign-In SDK silently first (which
  refreshes tokens automatically), then falls back to the saved credentials.

### App routing (`lib/main.dart`)
- Locks orientation to portrait (Android-only app).
- Edge-to-edge UI with a transparent status/navigation bar and dark icons to
  suit the light-blue/grey theme.
- On startup it checks `intro_seen`; later launches skip the intro and go
  straight to **Home** if the user is still signed in, otherwise to **Login**.

### Home placeholder (`lib/screens/home_screen.dart`)
- Loads the signed-in user's Gmail profile (`users.getProfile('me')`) and shows
  "Welcome, <email>".
- No app bar. A **bottom-right blue circle-outlined button** with `Icons.menu`
  opens a small popup menu containing **Sign out** (which disconnects the
  native session and wipes secure storage, then returns to login).
- The threaded mail view itself is not built yet — this screen is a styled
  placeholder ("Your threaded mail view will appear here.").

### Look & feel
- Material 3 theme seeded from the brand light-blue (`#4A9FE3`), light
  brightness, with `Comfortaa` as the default font family.
- Consistent light-blue / grey palette across screens.
- Two bundled custom fonts (see below).
- Android launcher icon generated from `assets/mailweave.png`.

## Planned
- **Threaded tree-branch mail view** — fetch messages, group them into reply
  trees, and render the branching structure of who replied to what. This is
  the core feature and the reason the app exists.

## Tech stack

- **Flutter** (Material 3) and **Dart** (`sdk: ^3.12.1`), configured for
  Android only.

### Dependencies

| Package | Version | Purpose |
| --- | --- | --- |
| `intro_slider` | `^4.2.5` | Onboarding intro slides |
| `shared_preferences` | `^2.3.2` | Remember that the intro has been seen |
| `lottie` | `^3.1.3` | Animated illustrations on intro/login |
| `google_sign_in` | `^6.2.2` | Interactive Google OAuth |
| `extension_google_sign_in_as_googleapis_auth` | `^2.0.12` | Bridge sign-in → `AuthClient` |
| `googleapis` | `^13.2.0` | Gmail API client |
| `googleapis_auth` | `^2.0.0` | `AccessCredentials` / `AuthClient` types |
| `http` | `^1.2.0` | HTTP transport for restored credentials |
| `flutter_secure_storage` | `^9.2.4` | Keystore-backed credential persistence |
| `cupertino_icons` | `^1.0.8` | iOS-style icon set (Flutter default) |

### Dev dependencies

| Package | Version | Purpose |
| --- | --- | --- |
| `flutter_lints` | `^6.0.0` | Lint rules |
| `flutter_launcher_icons` | `^0.14.3` | Generate Android launcher icons |

## Custom fonts

Two fonts are bundled in `assets/fonts/` and declared in `pubspec.yaml`:

| Family | Style | Weights |
| --- | --- | --- |
| Comfortaa | Rounded geometric sans (body/display) | 300 Light, 400 Regular, 500 Medium, 700 Bold |
| Playwrite US Modern | Handwriting accent font | 100 Thin, 200 ExtraLight, 300 Light, 400 Regular |

## Assets

- `assets/fonts/` — custom fonts (above).
- `assets/json/contact.json` — Lottie animation used on the intro slide.
- `assets/json/man_in_ballon.json` — Lottie animation on the login screen.
- `assets/mailweave.png` — source image for the generated Android launcher icon.

## Project structure

```
mailweave/
├─ android/                  # Android platform files (Android-only build)
│  └─ app/src/main/AndroidManifest.xml
├─ assets/
│  ├─ fonts/                 # Comfortaa & Playwrite US Modern font files
│  ├─ json/                  # Lottie animations
│  └─ mailweave.png          # Launcher-icon source
├─ lib/
│  ├─ main.dart              # Entry point: startup logic & routing
│  ├─ screens/
│  │  ├─ intro_screen.dart   # First-launch onboarding
│  │  ├─ login_screen.dart   # Google sign-in
│  │  └─ home_screen.dart    # Post-sign-in placeholder (mail view TBD)
│  └─ services/
│     └─ auth_service.dart   # Google OAuth, secure credential storage, Gmail API
├─ pubspec.yaml              # Metadata, dependencies, fonts & assets
└─ README.md
```

## Getting started

### Prerequisites

- Flutter SDK (Dart `^3.12.1`)
- An Android device or emulator
- A configured **Google OAuth Android client**: register the app's debug (and
  release) SHA-1 fingerprint in the Google Cloud Console for the Android OAuth
  client, and ensure the Gmail `gmail.readonly` scope is available for your
  test users (Google reviews sensitive scopes for unverified apps).

### Install dependencies

```sh
flutter pub get
```

### (Re)generate the launcher icon

```sh
dart run flutter_launcher_icons
```

### Run the app

```sh
flutter run
```

### Build a release APK

```sh
flutter build apk
```

## Versioning

The current version is `1.0.0+1` (see `pubspec.yaml`), following the
`major.minor.patch+build` convention where `build` maps to the Android
`versionCode`.
