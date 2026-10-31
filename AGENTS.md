# Project Rules

- Do not build, package, archive, or generate any application output for any platform unless the user explicitly requests that specific output. This includes APK, AAB, IPA, desktop builds, web builds, installers, and release archives.
- When working on this application project, if completing the task requires modifying the `sornaz-web` project, first retrieve the latest updates for the web project's current branch from GitHub. Perform this synchronization before making any web-project edits, preserve existing uncommitted work, and do not overwrite or discard local changes.
- For every new feature, make all user-facing text follow the font family, size, and weight selected in the application's main appearance settings. Use the shared typography/theme settings instead of isolated hardcoded text styles.
- For every new card, dialog, and button, use the application's configurable corner radius, which defaults to 4dp. Keep the corner-radius control in the main application settings.
- Use `lib/components/app_dialog.dart` for deletion confirmations throughout the app: `showDeleteConfirmation` / `DeleteConfirmationDialog` for yes/no deletion, or `AppDialog` with `AppDialogAction` roles for dialogs with multiple removal choices. Keep the shared 14dp title, 12dp content/actions, red destructive actions and grey cancellation; preserve the selected theme typography and radius. Do not implement another local deletion dialog.
- Keep the application in portrait orientation except on the video playback page. The video player may expose a rotation control and must restore portrait orientation when it closes.
- Do not create page-specific themes. Read colors, typography, shapes, and other appearance values from the application's shared theme and main appearance settings.
- Use the 12dp outer inset of the navigation drawer menu button as the standard horizontal content inset on both sides of application pages, unless the user explicitly requests edge-to-edge content. Video grids, profile post grids, and stage posts are edge-to-edge exceptions.
- Use the video library top bar as the standard for the gap between Back and the page title, the gap between top-bar icons, a 14dp base page-title font size, 24dp top-bar icons, and a 48dp Back button slot. These dimensions must still follow the shared appearance settings.
- Use the video library search expansion animation for search actions on application pages, and keep the expanded search field within the standard horizontal content insets.
- Apply the standard horizontal content inset to the first and last icons of every top bar. Back icons and page titles must share the same size, font style, and theme-derived color throughout the app.
- For expandable folder and playlist rows, show the expanded row's icon in the theme primary color. If its collapsed icon is outlined, use the filled counterpart while expanded.
- Display image and video grids with 1dp of spacing between items and a 1dp inset from every screen edge. This grid rule overrides the standard content inset.

# Shared UI Catalog

- Before implementing a page, search this catalog and the existing component implementation. Reuse the matching shared widget instead of copying its layout, colors, spacing or interaction code into the page.
- If a genuinely new repeated UI pattern is needed, implement or extend its shared widget first, migrate the matching existing consumers, and add its name, path and purpose to this table. Keep data fetching, permissions and mutations in the owning feature; shared UI must not invent API calls or change access rules.
- Read colors, typography, corner radius and direction from the application's theme and locale. Pass translated labels and existing callbacks into components. Preserve disabled states, validation, search/filter state, focus and navigation. Do not introduce a second implementation of the same visual pattern in another module.
- Feature-specific adapters such as `SocialEmpty`, `NoFilesFoundWidget`, `PlayerDialog`, `confirmMediaDelete` and `confirmRecordingDelete` may remain for compatibility, but must delegate to the shared implementation. New screens should prefer the shared component directly.

| Pattern | Shared widget / entry point | File |
| --- | --- | --- |
| Loading, empty data and retryable errors | `AppLoadingIndicator`, `AppEmptyState`, `AppErrorState` | `lib/components/app_async_state.dart` |
| Dialog surface and actions; deletion confirmation | `AppDialog`, `AppDialogAction`, `DeleteConfirmationDialog`, `showDeleteConfirmation` | `lib/components/app_dialog.dart` |
| Rename / create a named item | `AppTextInputDialog`, `showTextInputDialog` (initial value, hint, limit, validator and confirmation label) | `lib/components/app_text_input_dialog.dart` |
| Settings / form boolean switch row | `SettingsSwitchTile`, `SettingsSwitchTile.widgets` | `lib/components/settings_switch_tile.dart` |
| Table/card or table/week view selector | `AppViewModeSelector<T>`, `AppViewMode<T>` | `lib/components/app_view_mode_selector.dart` |
| Page top bar with Back | `SornazAppBar` | `lib/components/app_bar.dart` |
| Main-tab top bar | `HomeTopBar` | `lib/components/home_top_bar.dart` |
| Animated top-bar search | `ExpandingSearchBar` | `lib/components/expanding_search_bar.dart` |
| Scroll-aware page frame | `ScrollAwareScaffold` | `lib/components/scroll_aware_scaffold.dart` |
| Main-tab navigation and retained page state | `MainTabs`, `MainTabsScope`, `MainTabScaffold`, `BottomNavBarWidget` | `lib/components/main_tabs.dart`, `main_tab_scaffold.dart`, `bottom_nav.dart` |
| Drawer item | `AppDrawerItem` | `lib/components/app_drawer_item.dart` |
| Translated text | `AppText` | `lib/components/app_text.dart` |
| Authenticated account avatar | `AccountAvatar` (preserves origin and token checks) | `lib/components/account_avatar.dart` |
| Section heading / collapsible settings group | `SectionTitle`, `SettingsSectionHeader` | `lib/components/section_title.dart`, `settings_section_header.dart` |
| Language / palette controls | `LanguageSwitchTile`, `ColorPalettePicker` | `lib/components/language_switch_tile.dart`, `color_palette_picker.dart` |
| Account-panel frame, modal and editable value row | `PanelScaffold`, `PanelModal`, `PanelValueRow` | `lib/screens/Site/panel_ui.dart` |
| Collapsible panel card and record container | `PanelSectionCard`, `PanelListItem` | `lib/screens/Site/panel_section_card.dart`, `panel_list_item.dart` |
| Schema-driven panel form and field | `PanelFormPage`, `PanelField` | `lib/screens/Site/panel_form.dart` |
| Panel status cell and record details | `PanelStatusCell`, `PanelRecordFields` | `lib/screens/Site/panel_table_contract.dart` |
| Music / recorder playback buttons and timeline | `PlaybackControls`, `PlaybackSpeedButton`, `PlaybackProgress` | `lib/screens/Players/ui/components/audio_controls.dart`, `audio_slider.dart` |
| A–B repeat and sleep-timer controls | `AbRepeatButton`, `AbTrack`, `SleepTimerChrome` | `lib/components/ab_repeat.dart`, `sleep_timer_chrome.dart` |
| Reusable line chart | `AppLineChart` | `lib/components/charts/app_line_chart.dart` |

See `docs/shared-ui-components.fa.md` for the migrated consumers and verification guidance. Domain-specific forms, media permissions and OMR controls must retain their existing behavior; visual reuse does not authorize removing their fields or features.

# Development Worktree

- This worktree is the `main` development environment. Implement new features here first. Do not modify the `release/google-play-v1` worktree unless the user explicitly requests release work.
- Preserve the in-development OMR and experimental performance-analysis features and all uncommitted work. Inspect the relevant architecture and dependencies before editing; avoid unrelated changes and keep feature changes independently transferable to the release branch.
- If a feature shares dependencies with something excluded from the release, identify that dependency in the final report.
- Do not change the application ID, signing configuration, or backend configuration without a task-specific need and the user's approval.
- Run tests appropriate to the change. Do not create a commit or push without the user's explicit approval.
- Report in Persian: changed files, implemented changes, tests and results, remaining issues, and whether the changes are ready for selective transfer to the release worktree.

# Shared Git Worktree Safety

- The development and release worktrees share one Git repository. Transfer changes selectively; never overwrite the other branch's `AGENTS.md` when cherry-picking or merging.
- Avoid large, unrelated commits. If an `AGENTS.md` conflict occurs during a transfer, report the conflict before resolving it.
