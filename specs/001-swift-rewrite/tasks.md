# Tasks: Full Swift Rewrite of Bitwarden Alfred Workflow

**Input**: Design documents from `specs/001-swift-rewrite/`

**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/alfred-commands.md ✅, quickstart.md ✅

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete sibling tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)

---

## Phase 1: Setup

**Purpose**: Swift Package scaffold — no logic, just structure.

- [ ] T001 Create `Package.swift` declaring executable target `bw-alfred` with sources in `Sources/`, test target `bw-alfredTests` with sources in `Tests/bw-alfredTests/`
- [ ] T002 Create empty directory structure: `Sources/Alfred/`, `Sources/BWServer/`, `Sources/BWClient/`, `Sources/Cache/`, `Sources/Keychain/`, `Sources/TOTP/`, `Sources/URLMatching/`, `Sources/Notifications/`, `Sources/LaunchAgent/`, `Sources/Commands/`, `Tests/bw-alfredTests/`

---

## Phase 2: Foundational — Shared Infrastructure

**Purpose**: All types, HTTP plumbing, server lifecycle, cache, and Keychain that every user story depends on. No story can begin until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T003 [P] Create Alfred output types (`AlfredOutput`, `AlfredItem`, `AlfredIcon`, `AlfredMods`, `AlfredModItem`, `AlfredText`) as `Codable` structs with snake_case `CodingKeys` in `Sources/Alfred/AlfredOutput.swift`
- [ ] T004 [P] Create Alfred helper functions (`AlfredOutput.error(_:)`, `AlfredOutput.loading(_:)`, `AlfredOutput.single(_:)`) in `Sources/Alfred/AlfredHelpers.swift` — depends on T003
- [ ] T005 [P] Create `bw serve` response types (`BWItem`, `BWLoginData`, `BWLoginUri`, `BWCardData`, `BWIdentityData`, `BWCustomField`, `BWAttachment`, `BWSecureNoteData`) as `Codable` structs matching `bw serve` JSON in `Sources/BWClient/BWModels.swift`; include `ItemType`, `URIMatchType`, `CustomFieldType`, `VaultStatus` enums
- [ ] T006 [P] Create cache types (`CachedItem`, `CachedLoginData`, `CachedCardData`, `CachedCustomField`, `CachedFolder`, `CachedCollection`, `CachedOrganization`, `VaultCache`) as `Codable` structs in `Sources/Cache/CacheModels.swift`; include `schemaVersion: Int`, `lastSyncedAt: Date` on `VaultCache`
- [ ] T007 [P] Implement synchronous HTTP base client using `DispatchSemaphore` + `URLSession.dataTask` in `Sources/BWClient/BWClient.swift`; expose `get(_:)`, `post(_:body:)`, `put(_:body:)`, `delete(_:)` → `Data`; default base URL `http://localhost:8087`; 5-second timeout; `Authorization: Bearer {token}` header injection
- [ ] T008 [P] Implement `Keychain.swift` with `save(password:for:)`, `load(for:)`, `delete(for:)` using `SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate`, `SecItemDelete`; service name `"bw-alfred"` in `Sources/Keychain/Keychain.swift`
- [ ] T009 [P] Implement `WorkflowPrefs` (`defaultOrganizationId`, `defaultCollectionId`) with `load()` / `save()` reading from `alfred_workflow_data`/`prefs.json` in `Sources/Cache/WorkflowPrefs.swift`
- [ ] T010 [P] Implement `RecencyStore` (`lastItemId`, `lastField`, `lastCopiedAt`) with `load()` / `save()` / `shouldRotateToTOTP(for:)` (15-second window check) reading from `alfred_workflow_data`/`recency.json` in `Sources/Cache/RecencyStore.swift`
- [ ] T011 Implement `GET /status` → `ServerState` (`userEmail`, `status: VaultStatus`) in `Sources/BWClient/BWStatus.swift` — depends on T005, T007
- [ ] T012 [P] Implement `bw login` and `bw logout` CLI subprocess wrappers in `Sources/BWClient/BWAuth.swift`; handle API key and password login modes using `ProcessInfo.processInfo.environment` for `bw_login_method`, `bw_client_id`, `bw_client_secret`; parse session token from stdout
- [ ] T013 Implement `POST /unlock` (body: `{"password":"..."}` → session token) and `POST /lock` REST calls in `Sources/BWClient/BWAuth.swift` — extends T012, depends on T007
- [ ] T014 [P] Implement `BWServer`: start `bw serve` as detached `Process`, write PID to `{alfred_workflow_cache}/bw-serve.pid`; stop: read PID, send SIGTERM, delete file in `Sources/BWServer/BWServer.swift`
- [ ] T015 Implement `ensureUnlocked()` in `Sources/BWServer/EnsureUnlocked.swift`: (1) check PID → start server if needed, (2) poll `GET /status` up to 3s, (3) if unauthenticated → login flow, (4) if locked → read Keychain → `POST /unlock` → fallback to osascript dialog if Keychain empty — depends on T008, T011, T012, T013, T014
- [ ] T016 Implement `CacheBuilder.build(from: BWItem) -> CachedItem` stripping `login.password`, `login.totp`, `card.number`, `card.code`, all `fields` entries with `type == .hidden` (set `value = nil`); set `hasTOTP = true` if native totp present or a hidden field named `"totp"` exists in `Sources/Cache/CacheBuilder.swift` — depends on T005, T006
- [ ] T017 Implement `VaultCache`: `load() -> VaultCache?`, `save(_ cache: VaultCache)`, `isStale(interval: Int) -> Bool` reading/writing `{alfred_workflow_cache}/vault-cache.json`; use `JSONEncoder.dateEncodingStrategy = .secondsSince1970` in `Sources/Cache/VaultCache.swift` — depends on T006, T016
- [ ] T018 Create `Sources/main.swift` with a `switch CommandLine.arguments.dropFirst().first ?? ""` dispatcher routing all ~25 command names to stub `fatalError("not implemented")` placeholders; include `default:` case emitting an error Alfred item

**Checkpoint**: Foundation complete — all infrastructure in place; every command stub compilable.

---

## Phase 3: User Story 1 — Unlock and Search Vault (Priority: P1) 🎯 MVP

**Goal**: Invoke the workflow and see a live, ranked vault item list; vault unlocks/authenticates transparently using the Keychain.

**Independent Test**: Set env vars per `quickstart.md`; run `.build/debug/bw-alfred main`; verify Alfred JSON output reflects vault state. Run `.build/debug/bw-alfred search "github"` with unlocked vault; verify items returned and ranked correctly.

- [ ] T019 [P] [US1] Implement `GET /list/object/items`, `GET /list/object/folders`, `GET /list/object/collections`, `GET /list/object/organizations` in `Sources/BWClient/BWItems.swift` — depends on T005, T007
- [ ] T020 [P] [US1] Implement eTLD+1 extractor: parse host via `URLComponents`, strip `www.`, check embedded compound-suffix list (~50 entries), return registered domain; return `nil` for IPs, `localhost`, non-HTTP schemes in `Sources/URLMatching/URLMatcher.swift`
- [ ] T021 [P] [US1] Implement `URLMatcher.browserURL() -> String?` using `Process` + inline AppleScript to get frontmost browser tab URL; handle all browsers from spec (Safari, Firefox, Chrome, Edge, Opera, Brave, Vivaldi, Ghost, Arc); return `nil` for non-browser frontmost apps in `Sources/URLMatching/URLMatcher.swift` — extends T020
- [ ] T022 [US1] Implement `MainMenu` command: call `BWStatus.get()`, emit state-appropriate Alfred item list (unauthenticated: Login+Configure; locked: Unlock+Logout+Configure; unlocked: full menu) in `Sources/Commands/MainMenu.swift` — depends on T003, T004, T011
- [ ] T023 [US1] Implement `Search` command: load `VaultCache`, apply `WorkflowPrefs` filters, call `URLMatcher.browserURL()`, rank results (URL match → recency → favorites → alpha), emit `AlfredItem` per `CachedItem` with correct mods per `contracts/alfred-commands.md`; set `item_id`, `item_type`, `has_totp` variables in `Sources/Commands/Search.swift` — depends on T003, T009, T017, T020, T021
- [ ] T024 [P] [US1] Implement `ListFolders` command: load `VaultCache.folders`, emit Alfred item list; each item's `arg` triggers `search` filtered by folder in `Sources/Commands/ListFolders.swift` — depends on T003, T017
- [ ] T025 [US1] Implement `Login` command: run `ensureUnlocked()` (which internally handles login), then emit success item or re-run `main`; osascript password dialog with hidden answer if Keychain empty; store to Keychain on success in `Sources/Commands/Login.swift` — depends on T008, T015
- [ ] T026 [US1] Implement `Unlock` command: retrieve master password from Keychain → `POST /unlock` → on failure prompt via osascript; update Keychain on success; emit Alfred item confirming unlock in `Sources/Commands/Unlock.swift` — depends on T008, T013, T015
- [ ] T027 [P] [US1] Implement `LockVault` command: `POST /lock`; emit Alfred item confirming lock in `Sources/Commands/LockVault.swift` — depends on T013
- [ ] T028 [P] [US1] Implement `Logout` command: `POST /lock`; run `bw logout` subprocess; delete Keychain entry for `bw_email`; emit Alfred item confirming logout in `Sources/Commands/Logout.swift` — depends on T008, T012, T013
- [ ] T029 [US1] Wire T022–T028 into `main.swift` dispatcher (replace stubs for: `main`, `search`, `list_folders`, `login`, `unlock`, `lock`, `logout`) — depends on T018, T022–T028

**Checkpoint**: User Story 1 independently functional — invoke workflow, browse, search, unlock transparently.

---

## Phase 4: User Story 2 — Copy Vault Item Fields (Priority: P1) 🎯 MVP

**Goal**: Select a vault item and copy any field to the clipboard; TOTP computed locally or fetched live; clipboard auto-restores; field rotation works; notifications shown.

**Independent Test**: Run `.build/debug/bw-alfred get_field <id> password`; verify clipboard populated and restored after timeout. Run `.build/debug/bw-alfred get_field <id> totp`; verify 6-digit code on clipboard without the secret appearing in cache.

- [ ] T030 [P] [US2] Implement `Base32.decode(_ string: String) -> Data?` (case-insensitive, padding-tolerant, strips spaces) in `Sources/TOTP/Base32.swift`
- [ ] T031 [US2] Implement `TOTPGenerator.generate(secret: Data, digits: Int = 6, period: Int = 30) -> String?` using `CryptoKit.HMAC<Insecure.SHA1>` + dynamic truncation per RFC 6238 in `Sources/TOTP/TOTPGenerator.swift` — depends on T030
- [ ] T032 [P] [US2] Implement `Notifier.notify(title:message:)` checking `bw_notifications` env var; use `NSUserNotification` (deprecated but available) or spawn `osascript` notification in `Sources/Notifications/Notifier.swift`
- [ ] T033 [P] [US2] Implement `GET /object/item/{id}` in `Sources/BWClient/BWItems.swift` (live single-item fetch for TOTP and password) — extends T019
- [ ] T034 [US2] Implement `GetField` command: for `password` → fetch live via `GET /object/item/{id}`; for `totp` → fetch live item, try `login.totp` first, fallback to `fields[name="totp", type=hidden].value`, compute via `TOTPGenerator`; for `username`/`notes` → read from `VaultCache`; for `custom:<name>` → read from cache (type=text only); write to `NSPasteboard`, save previous contents, schedule restore after `bw_clipboard_time` seconds, call `Notifier.notify`, update `RecencyStore` in `Sources/Commands/GetField.swift` — depends on T003, T010, T017, T031, T032, T033
- [ ] T035 [US2] Implement `NextField` command: load `RecencyStore`, call `shouldRotateToTOTP(for:)`, delegate to `GetField` with appropriate field in `Sources/Commands/NextField.swift` — depends on T010, T034
- [ ] T036 [P] [US2] Implement `ShowItem` command: load `CachedItem` from `VaultCache`; compose osascript `display dialog` showing all non-sensitive fields per item type; run via `Process` in `Sources/Commands/ShowItem.swift` — depends on T017
- [ ] T037 [P] [US2] Implement `ListFields` command: load `CachedItem` from `VaultCache`; emit Alfred items for each non-sensitive field (username, notes, non-hidden custom fields); arg = field name for `GetField` in `Sources/Commands/ListFields.swift` — depends on T003, T017
- [ ] T038 [P] [US2] Implement `ListAttachments` command: load `CachedItem.hasAttachments`; if true emit Alfred items per attachment (name + sizeName); arg = attachment_id for `GetAttachment` in `Sources/Commands/ListAttachments.swift` — depends on T003, T017
- [ ] T039 [US2] Wire T034–T038 into `main.swift` dispatcher (replace stubs for: `get_field`, `next_field`, `show_item`, `list_fields`, `list_attachments`) — depends on T018, T034–T038

**Checkpoint**: User Stories 1 and 2 fully functional — complete search-and-copy workflow including TOTP and field rotation.

---

## Phase 5: User Story 3 — Manage Vault Items (Priority: P2)

**Goal**: Mark favorites, move to folders, download attachments, delete items — all syncing after each change.

**Independent Test**: Run `.build/debug/bw-alfred more <id>`; select "Mark as Favorite"; run `search`; verify item shows `favorite=true`.

- [ ] T040 [P] [US3] Implement `PUT /object/item/{id}` and `DELETE /object/item/{id}` in `Sources/BWClient/BWItems.swift` (accepts full `BWItem` body for PUT) — extends T019, T033
- [ ] T041 [P] [US3] Implement `GET /object/attachment/{id}?itemid={itemId}` downloading attachment bytes in `Sources/BWClient/BWAttachments.swift` — depends on T007
- [ ] T042 [P] [US3] Implement `MoreMenu` command: emit Alfred items [SetFavorite label, SetFolder, Download Attachments (if `hasAttachments`), Delete] reading item from `VaultCache` in `Sources/Commands/MoreMenu.swift` — depends on T003, T017
- [ ] T043 [P] [US3] Implement `SetFavorite` command: fetch live `BWItem`, toggle `favorite`, `PUT /object/item/{id}`, invalidate `VaultCache` entry, call `SyncVault.run()` in `Sources/Commands/SetFavorite.swift` — depends on T033, T040
- [ ] T044 [P] [US3] Implement `SetFolder` command: load `VaultCache.folders`, if no arg emit folder list Alfred items; if folder_id given fetch live item, set `folderId`, `PUT`, invalidate cache, sync in `Sources/Commands/SetFolder.swift` — depends on T017, T033, T040
- [ ] T045 [US3] Implement `GetAttachment` command: if `bw_downloads_folder` empty prompt via osascript; download via `BWAttachments`; save to resolved folder; notify in `Sources/Commands/GetAttachment.swift` — depends on T032, T041
- [ ] T046 [US3] Implement `DeleteItem` command: show osascript confirmation dialog ("THIS ACTION CANNOT BE UNDONE — item will be moved to Trash"); on confirm `DELETE /object/item/{id}`, remove from `VaultCache`, call `SyncVault.run()` in `Sources/Commands/DeleteItem.swift` — depends on T040
- [ ] T047 [US3] Wire T042–T046 into `main.swift` dispatcher (replace stubs for: `more`, `set_favorite`, `set_folder`, `get_attachment`, `rm`) — depends on T018, T042–T046

**Checkpoint**: User Story 3 independently functional — full item management cycle works end-to-end.

---

## Phase 6: User Story 4 — Vault Sync and Background Agent (Priority: P2)

**Goal**: Manual sync refreshes cache; background Launch Agent syncs automatically on interval.

**Independent Test**: Run `.build/debug/bw-alfred sync_vault`; inspect `vault-cache.json` `lastSyncedAt` is updated. Run `install_agent`; verify plist written and `launchctl` loaded.

- [ ] T048 [P] [US4] Implement `POST /sync` → rebuild `VaultCache` by calling all `GET /list/object/*` endpoints, run each through `CacheBuilder`, write to disk in `Sources/BWClient/BWSync.swift` — depends on T007, T016, T017, T019
- [ ] T049 [P] [US4] Implement `LaunchAgent`: generate plist XML with `Label`, `ProgramArguments`, `StartInterval` from `bw_sync_interval`; `install()` writes to `~/Library/LaunchAgents/com.alfred.bw-alfred.sync.plist` + runs `launchctl bootstrap`; `uninstall()` runs `launchctl bootout` + deletes plist in `Sources/LaunchAgent/LaunchAgent.swift`
- [ ] T050 [US4] Implement `SyncVault` command: call `ensureUnlocked()`, run `BWSync.sync()`, emit Alfred item confirming sync + `lastSyncedAt` timestamp in `Sources/Commands/SyncVault.swift` — depends on T015, T048
- [ ] T051 [P] [US4] Implement `ManageAgent` command: emit two Alfred items (Install Auto Sync / Uninstall Auto Sync) based on whether plist exists; arg triggers `install_agent` or `uninstall_agent` in `Sources/Commands/ManageAgent.swift` — depends on T049
- [ ] T052 [P] [US4] Implement `install_agent` and `uninstall_agent` command handlers calling `LaunchAgent.install()` / `LaunchAgent.uninstall()` in `Sources/Commands/ManageAgent.swift` — extends T051
- [ ] T053 [US4] Wire T050–T052 into `main.swift` dispatcher (replace stubs for: `sync_vault`, `install_agent`, `uninstall_agent`) — depends on T018, T050–T052

**Checkpoint**: User Story 4 independently functional — manual and automatic sync work.

---

## Phase 7: User Story 5 — Filter by Vault and Collection (Priority: P3)

**Goal**: User sets a default vault or collection; searches return only matching items.

**Independent Test**: Run `.build/debug/bw-alfred set_organization <org_id>`; verify `prefs.json` updated; run `search ""`; verify only items from that org returned.

- [ ] T054 [P] [US5] Implement `SetOrganization` command: if no arg emit Alfred item list of organizations from `VaultCache`; if org_id given write `defaultOrganizationId` to `WorkflowPrefs`, reset `defaultCollectionId` to nil in `Sources/Commands/SetOrganization.swift` — depends on T009, T017
- [ ] T055 [P] [US5] Implement `SetCollection` command: if no arg emit Alfred item list of collections for current `defaultOrganizationId` from `VaultCache`; if collection_id given write `defaultCollectionId` to `WorkflowPrefs` in `Sources/Commands/SetCollection.swift` — depends on T009, T017
- [ ] T056 [US5] Wire T054–T055 into `main.swift` dispatcher (replace stubs for: `set_organization`, `set_collection`) — depends on T018, T054, T055

**Checkpoint**: All user stories complete and independently functional.

---

## Phase 8: Polish and Cross-Cutting Concerns

**Purpose**: Unit tests for pure-logic modules; stale cache auto-sync; edge case hardening.

- [ ] T057 [P] Write `TOTPGeneratorTests`: known TOTP vectors (RFC 6238 Appendix B SHA-1 test values), valid + invalid Base32 input in `Tests/bw-alfredTests/TOTPGeneratorTests.swift`
- [ ] T058 [P] Write `Base32Tests`: decode standard vectors, padding variants, invalid chars, empty input in `Tests/bw-alfredTests/Base32Tests.swift`
- [ ] T059 [P] Write `URLMatcherTests`: eTLD+1 extraction for common domains, `.co.uk`-style compounds, IP addresses, `localhost`, `file://` URLs, `nil` cases in `Tests/bw-alfredTests/URLMatcherTests.swift`
- [ ] T060 [P] Write `CacheBuilderTests`: verify `password`, `totp`, `card.number`, `card.code`, and hidden custom field `value` are nil in output; verify `hasTOTP` flag set correctly; verify text custom fields retained in `Tests/bw-alfredTests/CacheBuilderTests.swift`
- [ ] T061 [P] Write `AlfredOutputTests`: encode `AlfredItem` with mods and variables, verify JSON keys are snake_case, verify `valid` defaults to `true` in `Tests/bw-alfredTests/AlfredOutputTests.swift`
- [ ] T062 Add stale-cache background sync trigger to `Search` command: after emitting results, if `VaultCache.isStale(interval: bw_sync_interval)` run `BWSync.sync()` asynchronously via `DispatchQueue.global().async` in `Sources/Commands/Search.swift`
- [ ] T063 Handle `bw_serve.pid` pointing to a dead process in `BWServer.start()`: check process existence before deciding to start; clean up stale PID file in `Sources/BWServer/BWServer.swift`
- [ ] T064 Validate all Alfred JSON output with `swift test`; verify `quickstart.md` cache inspection commands produce expected empty arrays (no sensitive fields)

---

## Dependencies and Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **blocks all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 — no other story dependencies
- **US2 (Phase 4)**: Depends on Phase 2 — no US1 dependency; can start in parallel with US1
- **US3 (Phase 5)**: Depends on Phase 2 + `VaultCache` from US1 foundation (T017); can start once Phase 2 complete
- **US4 (Phase 6)**: Depends on Phase 2; US4's `SyncVault` also needs `CacheBuilder` (T016) — start after Phase 2
- **US5 (Phase 7)**: Depends on Phase 2 (`WorkflowPrefs` T009); minimal — can start after Phase 2
- **Polish (Phase 8)**: Depends on all user stories complete

### Within Each Phase

- All tasks marked [P] within a phase can run in parallel
- Tasks without [P] have sequential dependencies noted inline

---

## Parallel Execution Examples

### Phase 2: Foundational

```
Parallel group A (no dependencies):
  T003 Alfred model types       T005 BWClient model types
  T004 Alfred helpers            T006 Cache model types
  T007 BWClient base HTTP        T008 Keychain
  T009 WorkflowPrefs             T010 RecencyStore
  T014 BWServer + PID            T018 main.swift skeleton

Sequential after group A:
  T011 BWStatus (needs T007)
  T012 + T013 BWAuth (needs T007)
  T016 CacheBuilder (needs T005, T006)
  T017 VaultCache (needs T006, T016)
  T015 ensureUnlocked (needs T008, T011, T012, T013, T014)
```

### Phase 3: US1

```
Parallel group:
  T019 BWItems list ops         T020 + T021 URLMatcher
  T024 ListFolders               T027 LockVault
  T028 Logout

Sequential:
  T022 MainMenu (needs T011)
  T023 Search (needs T017, T020, T021)
  T025 Login (needs T015)
  T026 Unlock (needs T015)
  T029 main.swift wiring (needs T022–T028)
```

### Phase 4: US2

```
Parallel group:
  T030 Base32                   T032 Notifier
  T033 GET /object/item          T036 ShowItem
  T037 ListFields                T038 ListAttachments

Sequential:
  T031 TOTPGenerator (needs T030)
  T034 GetField (needs T031, T032, T033)
  T035 NextField (needs T034)
  T039 main.swift wiring (needs T034–T038)
```

---

## Implementation Strategy

### MVP (User Stories 1 + 2 — both P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (**critical — blocks everything**)
3. Complete Phase 3: User Story 1 (search + auth)
4. Complete Phase 4: User Story 2 (copy fields + TOTP)
5. **STOP and VALIDATE**: run `quickstart.md` manual tests end-to-end
6. Install binary in Alfred workflow, test with real vault

### Incremental Delivery After MVP

- Add Phase 5 (US3: manage items) → test favorites, folders, delete
- Add Phase 6 (US4: sync + agent) → test manual sync and Launch Agent
- Add Phase 7 (US5: filter) → test org/collection filtering
- Add Phase 8 (polish + tests) → run `swift test`, verify cache safety

### Parallel Strategy (if working across sessions)

Once Phase 2 is complete:
- Session A: US1 (search + auth)
- Session B: US2 (copy + TOTP) — independent of US1
- These can proceed simultaneously; only `main.swift` wiring at end needs both
