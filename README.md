# Piano-ish

Piano-ish is a free, open-source MIDI piano learning app built
with Flutter. It supports Windows, Android, macOS, iPhone, and iPad.

## Features

- Import Standard MIDI files into a persistent local song library.
- Connect USB and Bluetooth MIDI keyboards, including the Roland FP-10.
- Practice with a complete 88-key keyboard and live note/pedal input.
- Use timed **Play along** or tempo-free **Pause & play** modes.
- Enable low-latency note audition through the device speakers.
- View piano-roll and engraved grand-staff notation.
- Export generated sheet music as PDF.
- Enrich song metadata through MusicBrainz and edit it manually.
- Build learning paths with the Planner and track scores and achievements.
- Customize the accent color, theme, profile, and progress storage.

## Requirements

- Flutter 3.44.6 with Dart 3.12.2 or newer compatible versions.
- Platform build tools for the target operating system.
- A MIDI keyboard is recommended but not required.

## Run from source

```powershell
flutter pub get
flutter run
```

Select a specific device with `flutter devices` and `flutter run -d <device>`.

## Build

```powershell
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
```

Apple builds require macOS and Xcode. See [APPLE_BETA.md](APPLE_BETA.md) for
the macOS, iPhone, iPad, and TestFlight workflow.

The Windows installer requires Inno Setup and can be built with:

```powershell
.\tool\build_windows_installer.cmd
```

Installers and application packages belong in GitHub Releases and are not
stored in this source repository.

### Android release signing

Android release builds intentionally fail until a permanent signing key is
configured. Copy `android/key.properties.example` to `android/key.properties`,
replace its placeholders, and keep both that file and the keystore private.
Back up the keystore securely: future updates must use the same signing key.

## Roland FP-10

For USB MIDI, connect the FP-10 USB-B port to the computer, turn it on, and
select it under **Settings > MIDI devices**. Windows may require Roland's USB
driver.

For Bluetooth MIDI, enable Bluetooth on the FP-10, open **Settings > MIDI
devices**, scan, and connect to the piano. USB generally provides lower and
more consistent latency.

## Data and online services

Imported MIDI files, profile information, learning paths, and practice history
are stored locally in the application's private support directory.

Optional metadata lookup sends the song title and composer to MusicBrainz.
Cover images are loaded from the Cover Art Archive. Piano-ish does not include
third-party songs or MIDI files.

## Project structure

- `lib/` — application source, MIDI parsing/playback, lessons, and UI.
- `test/` — parser, notation, persistence, and responsive-layout tests.
- `android/`, `ios/`, `macos/`, `windows/` — platform projects.
- `installer/` and `tool/` — Windows installer configuration and build script.
- `.github/workflows/` — CI and Apple beta builds.

## License

Piano-ish is available under the [MIT License](LICENSE). Third-party software,
font, metadata, and artwork terms are listed in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and in the app under
**Settings > Legal & licenses**.
