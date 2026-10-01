# Project Rules

- Do not build, package, archive, or generate any application output for any platform unless the user explicitly requests that specific output. This includes APK, AAB, IPA, desktop builds, web builds, installers, and release archives.
- When working on this application project, if completing the task requires modifying the `sornaz-web` project, first retrieve the latest updates for the web project's current branch from GitHub. Perform this synchronization before making any web-project edits, preserve existing uncommitted work, and do not overwrite or discard local changes.
- For every new feature, make all user-facing text follow the font family, size, and weight selected in the application's main appearance settings. Use the shared typography/theme settings instead of isolated hardcoded text styles.
- For every new card, dialog, and button, use the application's configurable corner radius, which defaults to 4dp. Keep the corner-radius control in the main application settings.
- Keep the application in portrait orientation except on the video playback page. The video player may expose a rotation control and must restore portrait orientation when it closes.
- Do not create page-specific themes. Read colors, typography, shapes, and other appearance values from the application's shared theme and main appearance settings.
- Use the 12dp outer inset of the navigation drawer menu button as the standard horizontal content inset on both sides of application pages, unless the user explicitly requests edge-to-edge content. Video grids, profile post grids, and stage posts are edge-to-edge exceptions.
- Use the video library top bar as the standard for the gap between Back and the page title, the gap between top-bar icons, a 14dp base page-title font size, 24dp top-bar icons, and a 48dp Back button slot. These dimensions must still follow the shared appearance settings.
- Use the video library search expansion animation for search actions on application pages, and keep the expanded search field within the standard horizontal content insets.
- Apply the standard horizontal content inset to the first and last icons of every top bar. Back icons and page titles must share the same size, font style, and theme-derived color throughout the app.
- For expandable folder and playlist rows, show the expanded row's icon in the theme primary color. If its collapsed icon is outlined, use the filled counterpart while expanded.
- Display image and video grids with 1dp of spacing between items and a 1dp inset from every screen edge. This grid rule overrides the standard content inset.
