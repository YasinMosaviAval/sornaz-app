# Offline Android arm64 release

The Flutter SDK, Android SDK, Dart packages, Gradle plugins and all artifacts must
already be installed on this machine. --no-pub alone does not make Gradle offline.

The project's android/offline-maven repository includes the story editor's three
previously missing runtime JARs with their original POM/module metadata. Their
SHA-256 hashes are recorded in story-dependencies.sha256.json. Exclusive repository
filters are limited to those exact versions; dependency constraints are preserved.
TLS certificate checks have not been disabled.

Verify Gradle dependency readiness without creating an APK:

    cd android
    .\gradlew.bat :app:verifyOfflineReleaseDependencies --offline -Ptarget-platform=android-arm64

From the Flutter project root, run an actual offline build when needed:

    $env:SORNAZ_GRADLE_OFFLINE = 'true'
    & 'A:\tools\flutter-3.47.2\flutter\bin\flutter.bat' build apk --release --no-pub --target-platform android-arm64 --build-number 10
    Remove-Item Env:SORNAZ_GRADLE_OFFLINE

The environment switch is opt-in and is read before Gradle plugins are resolved.
New dependencies or SDK versions require preparing their artifacts before going
offline. Keep the local Maven files when copying this checkout to another machine;
they do not replace the rest of that machine's Gradle and SDK caches.
