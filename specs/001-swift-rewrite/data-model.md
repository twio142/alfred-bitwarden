# Data Model: Full Swift Rewrite of Bitwarden Alfred Workflow

All types are `Codable` Swift structs. Types marked **[CACHE]** are written to disk with
sensitive fields stripped. Types marked **[LIVE]** are only ever held in memory, fetched
fresh from `bw serve` as needed.

---

## Bitwarden API Types (decoded from `bw serve` responses)

### `BWItem` [LIVE — never written to disk as-is]

Full item as returned by `bw serve`. Used transiently for write operations and live TOTP
fetch. Never persisted.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `name` | `String` | Display name |
| `type` | `ItemType` | Enum: login=1, secureNote=2, card=3, identity=4 |
| `folderId` | `String?` | nil = no folder |
| `organizationId` | `String?` | nil = personal vault |
| `collectionIds` | `[String]` | May be empty |
| `favorite` | `Bool` | |
| `login` | `BWLoginData?` | Present when type=login |
| `card` | `BWCardData?` | Present when type=card |
| `identity` | `BWIdentityData?` | Present when type=identity |
| `secureNote` | `BWSecureNoteData?` | Present when type=secureNote |
| `notes` | `String?` | Free-form notes |
| `fields` | `[BWCustomField]?` | Custom fields including TOTP fallback |
| `attachments` | `[BWAttachment]?` | |
| `revisionDate` | `String` | ISO 8601 |

### `BWLoginData`

| Field | Type | Notes |
|-------|------|-------|
| `username` | `String?` | |
| `password` | `String?` | **SENSITIVE** — stripped when building `CachedItem` |
| `totp` | `String?` | **SENSITIVE** — stripped; fetched live when needed |
| `uris` | `[BWLoginUri]?` | |

### `BWLoginUri`

| Field | Type | Notes |
|-------|------|-------|
| `uri` | `String?` | Full URL |
| `match` | `URIMatchType?` | 0=domain, 1=host, 2=startsWith, 3=exact, 4=regex, 5=never |

### `BWCardData`

| Field | Type | Notes |
|-------|------|-------|
| `cardholderName` | `String?` | |
| `brand` | `String?` | Visa, Mastercard, etc. |
| `number` | `String?` | **SENSITIVE** — stripped |
| `code` | `String?` | **SENSITIVE** — stripped |
| `expMonth` | `String?` | |
| `expYear` | `String?` | |

### `BWIdentityData`

All fields `String?`. Fields: `title`, `firstName`, `middleName`, `lastName`, `address1`,
`address2`, `address3`, `city`, `state`, `postalCode`, `country`, `company`, `email`,
`phone`, `ssn`, `username`, `passportNumber`, `licenseNumber`.

No fields are sensitive for display purposes; all included in cache.

### `BWCustomField`

| Field | Type | Notes |
|-------|------|-------|
| `name` | `String?` | |
| `value` | `String?` | **SENSITIVE if type=hidden** — stripped from cache |
| `type` | `CustomFieldType` | 0=text, 1=hidden, 2=boolean, 3=linked |

A custom field named `totp` (case-insensitive) with `type=hidden` is treated as the TOTP
secret fallback. Its value is stripped from cache and fetched live when the TOTP action is
triggered.

### `BWAttachment`

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `fileName` | `String?` | |
| `size` | `String?` | Bytes as string |
| `sizeName` | `String?` | Human-readable (e.g. "1.2 MB") |
| `url` | `String?` | Download URL |

---

## Cache Types (written to disk — all sensitive fields stripped)

### `VaultCache` [CACHE]

Stored at `{alfred_workflow_cache}/vault-cache.json`.

| Field | Type | Notes |
|-------|------|-------|
| `schemaVersion` | `Int` | Increment on breaking cache format changes |
| `lastSyncedAt` | `Date` | Unix timestamp of last successful sync |
| `items` | `[CachedItem]` | All items, sensitive fields stripped |
| `folders` | `[CachedFolder]` | |
| `collections` | `[CachedCollection]` | |
| `organizations` | `[CachedOrganization]` | |

### `CachedItem` [CACHE]

Subset of `BWItem` with all sensitive fields omitted.

| Field | Type | Notes |
|-------|------|-------|
| `id` | `String` | |
| `name` | `String` | |
| `type` | `ItemType` | |
| `folderId` | `String?` | |
| `organizationId` | `String?` | |
| `collectionIds` | `[String]` | |
| `favorite` | `Bool` | |
| `login` | `CachedLoginData?` | No password, no TOTP |
| `card` | `CachedCardData?` | No number, no code |
| `identity` | `BWIdentityData?` | All fields safe |
| `notes` | `String?` | |
| `fields` | `[CachedCustomField]?` | Hidden field values stripped |
| `hasAttachments` | `Bool` | True if attachments exist (count not needed) |
| `hasTOTP` | `Bool` | True if native TOTP or a `totp` custom field exists |
| `revisionDate` | `String` | Used to detect stale cache entries |

### `CachedLoginData` [CACHE]

| Field | Type | Notes |
|-------|------|-------|
| `username` | `String?` | Safe to cache |
| `uris` | `[BWLoginUri]?` | Safe to cache (no secrets) |

### `CachedCardData` [CACHE]

| Field | Type | Notes |
|-------|------|-------|
| `cardholderName` | `String?` | |
| `brand` | `String?` | |
| `expMonth` | `String?` | |
| `expYear` | `String?` | |

### `CachedCustomField` [CACHE]

| Field | Type | Notes |
|-------|------|-------|
| `name` | `String?` | |
| `value` | `String?` | nil when `type=hidden`; original value stripped |
| `type` | `CustomFieldType` | |

### `CachedFolder` / `CachedCollection` / `CachedOrganization` [CACHE]

| Field | Type |
|-------|------|
| `id` | `String` |
| `name` | `String` |
| `organizationId` | `String?` (collections only) |

---

## State Types (held in memory or persisted as small preference files)

### `WorkflowPrefs`

Stored at `{alfred_workflow_data}/prefs.json`. User preferences persisted across
invocations.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `defaultOrganizationId` | `String?` | nil = all vaults | |
| `defaultCollectionId` | `String?` | nil = all collections | |
| `defaultFolderId` | `String?` | nil = all folders | Unused in search, used in folder menu |

### `RecencyStore`

Stored at `{alfred_workflow_data}/recency.json`. Tracks the last-selected item for
ranking and field rotation.

| Field | Type | Notes |
|-------|------|-------|
| `lastItemId` | `String?` | Most recently selected item |
| `lastField` | `String?` | Last field copied (`password`, `username`, `totp`, `notes`) |
| `lastCopiedAt` | `Date?` | Timestamp of last copy action |

Field rotation rule: if `lastItemId` == current item AND `lastField` == `"password"` AND
`Date().timeIntervalSince(lastCopiedAt) < 15`, copy TOTP instead of password.

### `ServerState`

In-memory only. Result of `GET /status` from `bw serve`.

| Field | Type | Notes |
|-------|------|-------|
| `serverURL` | `String` | Configured Bitwarden server |
| `userEmail` | `String?` | |
| `status` | `VaultStatus` | Enum: unauthenticated, locked, unlocked |

---

## Alfred Output Types

### `AlfredOutput`

Top-level JSON written to stdout.

| Field | Type | Notes |
|-------|------|-------|
| `items` | `[AlfredItem]` | |
| `variables` | `[String: String]?` | Workflow variables to set |
| `rerun` | `Double?` | Seconds before Alfred re-runs (for loading states) |

### `AlfredItem`

| Field | Type | Notes |
|-------|------|-------|
| `uid` | `String?` | Stable ID for Alfred's history |
| `title` | `String` | |
| `subtitle` | `String?` | |
| `arg` | `String?` | Passed to next action |
| `icon` | `AlfredIcon?` | |
| `valid` | `Bool` | Default true |
| `autocomplete` | `String?` | |
| `mods` | `AlfredMods?` | Per-modifier overrides |
| `text` | `AlfredText?` | Copy/large type text |
| `variables` | `[String: String]?` | Item-level variables |

### `AlfredIcon`

| Field | Type | Notes |
|-------|------|-------|
| `path` | `String?` | Relative path to icon file |
| `type` | `String?` | `"fileicon"` or `"filetype"` |

### `AlfredMods`

| Field | Type |
|-------|------|
| `ctrl` | `AlfredModItem?` |
| `shift` | `AlfredModItem?` |
| `cmd` | `AlfredModItem?` |
| `alt` | `AlfredModItem?` |
| `fn` | `AlfredModItem?` |

### `AlfredModItem`

| Field | Type |
|-------|------|
| `subtitle` | `String?` |
| `arg` | `String?` |
| `valid` | `Bool` |
| `variables` | `[String: String]?` |

### `AlfredText`

| Field | Type |
|-------|------|
| `copy` | `String?` |
| `largetype` | `String?` |

---

## Enums

| Type | Values |
|------|--------|
| `ItemType` | `login=1`, `secureNote=2`, `card=3`, `identity=4` |
| `URIMatchType` | `domain=0`, `host=1`, `startsWith=2`, `exact=3`, `regex=4`, `never=5` |
| `CustomFieldType` | `text=0`, `hidden=1`, `boolean=2`, `linked=3` |
| `VaultStatus` | `unauthenticated`, `locked`, `unlocked` |
