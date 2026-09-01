# Apple beta builds

Pianora uses one universal iOS application target for both iPhone and iPad.
The bundle identifier is `com.mmovahedi.pianora`, and the current beta version
comes from `pubspec.yaml`.

## Build artifacts with GitHub Actions

1. Push the repository to GitHub.
2. Open **Actions > Build Apple beta > Run workflow**.
3. After the run completes, download:
   - `Pianora-Piano-tranier-macOS-beta`
   - `Pianora-Piano-tranier-iPhone-iPad-beta-unsigned`

The macOS artifact contains a ZIP and DMG. It is unsigned, so macOS testers may
need to approve it in **System Settings > Privacy & Security**. Public macOS
distribution should use Developer ID signing and Apple notarization.

The iPhone/iPad artifact proves the app compiles, but Apple will not install an
unsigned IPA on physical devices. Use the signing steps below for a real beta.

## Create an installable iPhone and iPad beta

1. Enroll in the Apple Developer Program.
2. Register the explicit App ID `com.mmovahedi.pianora` in Certificates,
   Identifiers & Profiles.
3. Create the matching iOS app in App Store Connect.
4. On a Mac, open `ios/Runner.xcworkspace` in Xcode.
5. Select **Runner > Signing & Capabilities**, choose your development team,
   and leave **Automatically manage signing** enabled.
6. Connect an iPhone or iPad and run the app once to validate Bluetooth MIDI,
   audio, MIDI import, sheet rendering, and PDF export on real hardware.
7. Run `flutter build ipa --release`, or select **Product > Archive** in Xcode.
8. In Xcode Organizer, choose **Distribute App > App Store Connect > Upload**.
9. In App Store Connect, open **TestFlight**, complete the beta compliance
   fields, and add internal testers.

Never commit `.p12`, `.mobileprovision`, `.p8`, passwords, or App Store Connect
API keys to this repository.
