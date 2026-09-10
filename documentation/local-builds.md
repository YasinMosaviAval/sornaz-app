# Local Chrome preview and Android APK

Only generate APKs, web builds, or other distributable outputs when the user explicitly requests them. Code edits and focused checks do not authorize a build.

Run these commands from `A:\workspace\android\flutter\sornaz-app`.

## Chrome

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tool\run_web.ps1
```

This opens Chrome at http://localhost:8080 and starts a loopback API relay on
port 8081. Keep the terminal open; use `q` to stop. An alternate port can be
selected with `-Port 8090` (the relay uses the next port).

The launcher uses installed dependencies (`--no-pub`) and local Flutter web
renderer assets (`--no-web-resources-cdn`). It needs Flutter, Node.js, Chrome,
and an existing `.dart_tool/package_config.json`. It does not change the
machine's PowerShell execution policy.

The relay forwards requests to https://sornaz.com with TLS verification enabled.
Authentication, articles, and other server features still require connectivity
to that server. A 502 response from the relay means the upstream request failed.
Check `curl.exe -I --connect-timeout 15 https://sornaz.com` to test connectivity.

Microphone access requires permission in Chrome. Browser recordings are stored
in IndexedDB for this origin. Browser music playback uses files chosen by the
user because the browser cannot scan device storage automatically.

To build a standalone web directory for this local relay:

```powershell
& 'A:\tools\flutter-3.47.2\flutter\bin\flutter.bat' build web --release --no-pub --no-web-resources-cdn --dart-define=Sornaz_API_BASE_URL=http://localhost:8081/api/sornaz/v1 --dart-define=SORNAZ_API_BASE_URL=http://localhost:8081/api/sornaz/v1
```

Output: `build/web`. These API addresses are for local preview; replace both
defines with the deployed API address when building for hosting.

## APK

After the existing dependency/cache preparation steps, the build command is:

```powershell
& 'A:\tools\flutter-3.47.2\flutter\bin\flutter.bat' build apk --release --no-pub --target-platform android-arm64 --build-number 10
```

Output: `build/app/outputs/flutter-apk/app-release.apk`.

The failure fixed on 2026-09-09 was an undefined `AppStrings.register_title`
reference on the registration page. The page now uses the existing localized
`auth.register_title` key. The command above subsequently built successfully.

`--no-pub` skips fetching Dart packages; it does not itself force Gradle offline.
An offline Android build still needs the prepared Gradle, Android SDK, and native
dependency caches. The successful verification used the existing local setup;
it was not a network-disconnected test.

Validation: release APK and JavaScript web builds succeeded, Chrome connected
to the Flutter debug service, and all 31 Flutter tests passed. Dart analysis
reported informational lints only. WebAssembly is not the selected web target;
the current notation integration and metronome dependency report Wasm dry-run
incompatibilities.
