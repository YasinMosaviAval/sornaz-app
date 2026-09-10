# UI and media revision — 2026-09-10

The app now offers the original palette plus indigo, emerald, rose and amber,
persisted independently of language and brightness. Startup, authentication,
drawer navigation, home sections and music tools navigation have been updated.

Music and recordings include expanding search, A–B playback, quieter row borders,
and updated file controls. Recording bookmarks enforce a one-second separation;
the waveform player supports bookmark names, navigation and Android recording
overwrite. Android's document tree picker controls the recording destination.

Course metadata uses an account- and locale-specific cache with background
refresh. Downloaded course media uses authenticated AES-GCM chunks in private
application storage and is opened inside the app. This is application-level
protection, not a guarantee against a compromised device. Matching website
changes include community ordering and authorized resource metadata.

Validation: 27 related Flutter tests passed; Dart analysis reported no errors or
warnings (style infos remain); modified PHP passed syntax checks. Android Kotlin
release sources compiled without assembling an APK. Playback notifications,
document-tree access and audio overwrite still need physical-device verification.
The server changes have not been deployed by this task.

No APK or other distributable was generated. Generate one only on an explicit
user request.
