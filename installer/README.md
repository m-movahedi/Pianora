# Windows installer

Build the release installer from the repository root:

```powershell
.\tool\build_windows_installer.cmd
```

The generated setup program is placed in `installer/output`. Inno Setup 6 is
required; install it once with:

```powershell
winget install --id JRSoftware.InnoSetup --exact
```

## Publishing an update

1. Increase `version:` in `pubspec.yaml`, including the build number.
2. Run `.\tool\build_windows_installer.cmd`.
3. Distribute the new setup executable.

Users can run the new setup normally. The permanent `AppId` in `pianora.iss`
makes it update the existing installation in place. Do not change that ID in a
future release. User profiles and progress are stored outside the installation
directory and are preserved during upgrades and uninstall/reinstall cycles.

The generated installer is not code-signed. A public production release should
be signed with a trusted Windows code-signing certificate to reduce SmartScreen
warnings.
