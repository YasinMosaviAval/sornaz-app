# Academy registration and private session attachments

Development worktree only. No new dependency, application ID, signing or backend URL changes. No release worktree changes and no application build is required to validate these changes.

Academy registration finishes after the academy is saved. The completion screen links authenticated users to the Organization branch page; guests sign in first. Legacy `choice`/`branch` registration responses are treated as completion. Main and subsidiary branches remain available through Organization.

`PanelSessionFiles` uses the shared panel modal, theme, typography and configurable radius. Session attachments can be opened from session details, term attendance, term session lists and enrolled classroom details. Upload and deletion buttons follow live server permissions. Students download only; no permissions are inferred from a displayed role.

The web API must be deployed first. The schedules catalog exposes four hidden member operations:

| Operation | Method | Parameters |
| --- | --- | --- |
| `session-files` | GET | `id` (session ID) |
| `session-file-upload` | POST multipart | `id`, `file` upload |
| `session-file-download` | GET | `id`, `file` (file ID) |
| `session-file-delete` | POST | `id`, `file` (file ID) |

File lists bypass both memory and persistent offline caches. Downloads use the authenticated panel proxy, refuse redirects and non-attachment responses, stream into a temporary file, check account identity during transfer and remove the temporary copy afterwards. Server-side access checks remain authoritative. Never open a supplied public media URL for these attachments.

The backend reuses `media_files`; no migration is required. Its private storage root must be outside the web document root and project folder. Full deployment order, exact web files, rollback and server smoke checks are in the web repository's `docs/session-files-deployment.fa.md`.

Validation: `flutter test --no-pub test/academy_registration_test.dart test/panel_session_files_test.dart test/panel_database_management_test.dart test/native_panel_test.dart`. These are fixture tests, not a production server or device transfer test. The change is independently transferable to the release branch after the backend is available; it has no experimental OMR dependency.
