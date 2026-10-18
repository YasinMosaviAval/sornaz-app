# Interval recognition stars and results

Each level shows five stars. Ten consecutive correct answers earn one yellow
star; an incorrect answer resets the streak. The first success unlocks the next
level. Replaying a level earns more stars, up to five displayed stars. Further
attempts remain in the result history. Western and Iranian progress is separate.

Old completion marks become one baseline star. SharedPreferences progress uses a
new per-user/per-music v3 key, preserving the previous v2 data. New awards have
stable run identifiers, so retries cannot award the same success twice.

Hive stores attempt metadata and individual answers, flushes before counting a
win, and repairs an interrupted metadata update from its durable answer records.
Failures offer a retry for the same answer. Results remain locally after upload.
Guest results remain device-local and are never assigned to a signed-in account.

Authenticated users sync queued answers and legacy completion credits using the
existing mobile bearer token. Offline/server errors preserve progress for retry.
Account changes prevent acknowledgements from being applied to the wrong scope.
Server progress restores stars across devices; full answer history stays on the
server and the device where the attempt was taken.

Backend deployment requires the three-table migration, curriculum resource,
services, controller and API routes documented in the web project's
`docs/interval-practice-results.md`. The migration is supplied but has not been
run against production. Local play remains available before backend deployment.

Tests cover stars, old-data migration, restart recovery, answer persistence,
retries, account isolation, synchronization failures and the five-star UI. No
application build is required. Real-device audio and staging MySQL verification
remain deployment checks.

The change adds no package dependency and does not depend on OMR or experimental
performance features. It can be selectively transferred with its shared string
additions and tests; server synchronization additionally requires the matching
web files and database migration. Do not transfer either worktree's AGENTS.md.
