# Android story editor

Android story publishing opens a native-gallery-backed Flutter composer. Other
platforms retain the existing file publishing flow.

- Gallery media is read in pages of 60 with thumbnails loaded for visible tiles.
- Camera output and selected media copies live only in private story-drafts cache.
  Closing the editor removes its files; a new activity clears abandoned drafts.
- Only Save writes a designed image/video into public Pictures/Sornaz or
  Movies/Sornaz. Android media permission denial and limited access are handled.
- Captions, selected member avatars/names and movable text are rendered into the
  exported media. Mentions are visual labels, not notifications or profile links.
- Image output uses the Flutter canvas; video uses Media3 Transformer with the
  same overlay and retains audio. No upload occurs until Publish is selected.
- Color sampling uses a paused video frame or image, accounting for fit/crop.
- The old viewer caption is left empty to avoid duplicating the rendered caption.

Verification: story_composer_test.dart covers gallery shape, duration labels,
camera selection, local cleanup, caption, explicit Save/Publish, mention search
debouncing and color sampling/modes. Story playback regression tests also pass.
Android Kotlin compilation was checked for arm64 without packaging an APK.
Camera, permissions, MediaStore and hardware video export still need an on-device
smoke test; no physical-device test or APK build was performed.
