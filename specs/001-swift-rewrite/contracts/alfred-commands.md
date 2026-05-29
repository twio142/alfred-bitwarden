# Alfred Command Contracts

The `bw-alfred` binary is invoked by Alfred with:
```
bw-alfred <command> [arg1] [arg2] ...
```

All inputs arrive via `CommandLine.arguments` (positional) and environment variables
(Alfred workflow variables + system env). All output is Alfred script filter JSON written
to stdout. Errors that require user attention are surfaced as Alfred items or osascript
dialogs — never to stderr in production.

---

## Environment Variables (Alfred Workflow Variables)

| Variable | Type | Description |
|----------|------|-------------|
| `bw_email` | String | Bitwarden account email |
| `bw_server` | String | Server URL (default: `https://bitwarden.com`) |
| `bw_login_method` | `password` \| `apikey` | Login method |
| `bw_client_id` | String | API key client ID (apikey mode only) |
| `bw_client_secret` | String | API key client secret (apikey mode only) |
| `bw_2fa_method` | `authenticator` \| `yubikey` \| `email` | 2FA method (password mode) |
| `bw_downloads_folder` | String | Path for attachment downloads; empty = prompt |
| `bw_clipboard_time` | Int (seconds) | Clipboard clear timeout (default: 30) |
| `bw_sync_interval` | Int (minutes) | How often to auto-sync (default: 60) |
| `bw_notifications` | `true` \| `false` | Show copy notifications (default: `true`) |
| `alfred_workflow_cache` | String | Alfred-managed cache directory path |
| `alfred_workflow_data` | String | Alfred-managed data directory path |

---

## Commands

### `main`
**Args**: none
**Reads**: `VaultStatus` (live), `WorkflowPrefs`
**Output**: Alfred item list — state-appropriate menu

State: unauthenticated → items: `[Login, Configure]`
State: locked → items: `[Unlock, Logout, Configure]`
State: unlocked → items: `[Search, Folders, Lock, SetVault, SetCollection, Sync, Logout, Configure]`

---

### `search`
**Args**: `[query]` (optional; empty = list all)
**Reads**: `VaultCache`, `RecencyStore`, `WorkflowPrefs`, browser URL (AppleScript)
**Output**: Alfred item list of matching `CachedItem`s

Ranking order: browser URL match (eTLD+1) → recently selected → favorites → alphabetical.
Filters applied: `defaultOrganizationId`, `defaultCollectionId`.

Each item's modifiers:
- default → copy password (login) / notes (secureNote) / show dialog (card, identity)
- `ctrl` → copy username
- `shift` → copy TOTP (only if `hasTOTP=true`)
- `cmd` → copy notes
- `alt` → open More Menu (`more` command)
- `fn` → show detail dialog (`show_item` command)
- `cmd+alt` → list fields in Alfred (`list_fields` command)

Item variables: `item_id`, `item_type`, `has_totp`

---

### `list_folders`
**Args**: none
**Reads**: `VaultCache`
**Output**: Alfred item list of folders; selecting one runs `search` filtered by folder

---

### `list_fields`
**Args**: `<item_id>`
**Reads**: `VaultCache`
**Output**: Alfred item list of safe (non-sensitive) fields; each item copies its value

---

### `list_attachments`
**Args**: `<item_id>`
**Reads**: `VaultCache`
**Output**: Alfred item list of attachments (name + size); selecting one runs `get_attachment`

---

### `more`
**Args**: `<item_id>`
**Reads**: `VaultCache`
**Output**: Alfred item list: `[SetFavorite, SetFolder, Attachments (if any), Delete]`

---

### `show_item`
**Args**: `<item_id>`
**Reads**: `VaultCache`
**Output**: Opens an osascript dialog showing all cached (non-sensitive) fields for
multi-copy. No Alfred JSON returned for this command.

---

### `get_field`
**Args**: `<item_id> <field>`
**Field values**: `password`, `username`, `totp`, `notes`, `custom:<field_name>`
**Reads**: `VaultCache` for non-sensitive fields; `bw serve` live for `password` and `totp`
**Output**: Writes field value to clipboard; shows macOS notification if enabled; updates `RecencyStore`; starts clipboard-clear timer

For `totp`: fetches `BWItem` live → tries native `login.totp` first → falls back to
`fields[name=totp, type=hidden].value` → computes TOTP code locally.

---

### `next_field`
**Args**: `<item_id>`
**Reads**: `RecencyStore`
**Output**: Delegates to `get_field` with rotated field (`password` → `totp` within 15s window)

---

### `get_attachment`
**Args**: `<item_id> <attachment_id>`
**Reads**: `VaultCache` (for attachment metadata), `bw_downloads_folder` env var
**Output**: Downloads attachment via `bw serve`; saves to downloads folder; shows notification

---

### `set_favorite`
**Args**: `<item_id> <true|false>`
**Reads**: `VaultCache`
**Side effects**: PUT `/object/item/{id}` with updated `favorite`; triggers sync; invalidates cache entry

---

### `set_folder`
**Args**: `<item_id> <folder_id>`
**Side effects**: PUT `/object/item/{id}` with updated `folderId`; triggers sync; invalidates cache entry

---

### `set_organization`
**Args**: `<org_id | "all">`
**Side effects**: Writes `defaultOrganizationId` to `WorkflowPrefs`; resets `defaultCollectionId` to nil

---

### `set_collection`
**Args**: `<collection_id | "all">`
**Side effects**: Writes `defaultCollectionId` to `WorkflowPrefs`

---

### `rm`
**Args**: `<item_id>`
**Side effects**: DELETE `/object/item/{id}`; triggers sync; removes from cache
**Note**: Requires confirmation via osascript dialog before executing

---

### `sync_vault`
**Args**: none
**Side effects**: POST `/sync`; rebuilds `VaultCache` from fresh `GET /list/object/*` calls; strips sensitive fields; writes to disk; updates `lastSyncedAt`

---

### `lock`
**Args**: none
**Side effects**: POST `/lock` to `bw serve`

---

### `logout`
**Args**: none
**Side effects**: POST `/lock`; runs `bw logout` CLI subprocess; clears Keychain entry for email

---

### `login`
**Args**: none
**Side effects**: Prompts for master password (or uses Keychain); runs `bw login` CLI subprocess; stores password to Keychain on success

---

### `unlock`
**Args**: none
**Side effects**: Retrieves master password from Keychain or prompts; POST `/unlock`; stores session token in memory

---

### `start_server`
**Args**: none
**Side effects**: Spawns `bw serve` as detached process; writes PID to `{cacheDir}/bw-serve.pid`; polls `/status` until healthy (3s timeout)

---

### `stop_server`
**Args**: none
**Side effects**: Reads PID from `{cacheDir}/bw-serve.pid`; sends SIGTERM; removes PID file

---

### `install_agent` / `uninstall_agent`
**Args**: none
**Side effects**: Writes/removes plist at `~/Library/LaunchAgents/com.alfred.bw-alfred.sync.plist`; runs `launchctl bootstrap`/`bootout`
