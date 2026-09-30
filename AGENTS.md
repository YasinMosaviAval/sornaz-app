# Project Rules

- Do not build, package, archive, or generate any application output for any platform unless the user explicitly requests that specific output. This includes APK, AAB, IPA, desktop builds, web builds, installers, and release archives.
- When working on this application project, if completing the task requires modifying the `sornaz-web` project, first retrieve the latest updates for the web project's current branch from GitHub. Perform this synchronization before making any web-project edits, preserve existing uncommitted work, and do not overwrite or discard local changes.
- For every new feature, make all user-facing text follow the font family, size, and weight selected in the application's main appearance settings. Use the shared typography/theme settings instead of isolated hardcoded text styles.
- For every new card, dialog, and button, use the application's configurable corner radius, which defaults to 4dp. Keep the corner-radius control in the main application settings.
- Keep the application in portrait orientation except on the video playback page. The video player may expose a rotation control and must restore portrait orientation when it closes.
- Do not create page-specific themes. Read colors, typography, shapes, and other appearance values from the application's shared theme and main appearance settings.
