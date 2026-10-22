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

# Google Play Release Worktree

- This worktree is `release/google-play-v1`. Make release-specific changes only here; do not modify the `main` development worktree.
- Keep unfinished OMR and experimental performance analysis out of this release. Keep the Scene tab connected to the existing chat screen and the Profile tab connected to the existing account screen. Preserve completed features and existing authentication and navigation behavior.
- Transfer development changes selectively and review dependencies and conflicts before cherry-picking or merging. Never merge all of `main` into this branch without an explicit user request. Preserve this release-specific `AGENTS.md` during transfers.
- Do not remove a shared dependency without checking its production uses. Do not change the application ID, signing keys or configuration, backend configuration, or sensitive permissions without the user's approval.
- Preserve all important files and uncommitted work. Avoid unnecessary architecture changes; release stability takes priority over adding features.
- The Release black-screen startup issue has not yet been confirmed fixed on an Android device. Do not call the app ready for publication until relevant tests and real Android startup have been verified.
- Do not create a commit or push without the user's explicit approval. Report work and test results in Persian.

# Shared Git Worktree Safety

- Both worktrees share one Git repository. Avoid large, unrelated commits and do not replace the other branch's `AGENTS.md` during a transfer.
- If an `AGENTS.md` conflict occurs during a cherry-pick or merge, report the conflict before resolving it.
