# Feature Specification: Full Swift Rewrite of Bitwarden Alfred Workflow

**Feature Branch**: `001-swift-rewrite`

**Created**: 2026-05-29

**Status**: Draft

**Input**: User description: "the full rewrite in Swift"

## Clarifications

### Session 2026-05-29

- Q: How should TOTP codes be served given TOTP secrets are stripped from cache? → A: Fetch live from the server at copy time. Native Bitwarden TOTP is the primary path; a custom field containing the TOTP secret is the fallback (workaround for no premium subscription), with codes computed locally at runtime. Secrets never written to disk.
- Q: Should the master password or session token be persisted in the Keychain for silent re-unlock? → A: Persist the master password in the Keychain (Option A) for fully automatic unlock after first login.
- Q: How should the workflow notify the user when a field is copied to the clipboard? → A: Show a macOS notification on clipboard copy; configurable off via workflow settings (Option A). Error conditions (failed unlock, sync failure) use a modal dialog.
- Q: How should browser URL matching work? → A: Registered domain (eTLD+1) match — e.g. `mybank.com` matches `login.mybank.com` and `www.mybank.com` (Option B). Protocol is ignored.

## User Scenarios & Testing

### User Story 1 - Unlock and Search Vault (Priority: P1)

A user invokes the workflow (via hotkey or keyword) and immediately sees a filtered list
of vault items matching their query. If the vault is locked or the user is unauthenticated,
they are prompted to unlock or log in before the list appears.

**Why this priority**: This is the primary daily interaction. Every other feature is
secondary to fast, reliable vault search.

**Independent Test**: Invoke the workflow with no browser context; type a search query;
verify matching items appear within a reasonable response time. Can be validated end-to-end
as a standalone user journey.

**Acceptance Scenarios**:

1. **Given** the vault is unlocked, **When** the user invokes the workflow and types a
   query, **Then** matching items are listed in Alfred sorted by recency, browser URL match,
   and favorites.
2. **Given** the vault is locked, **When** the user invokes the workflow, **Then** they are
   prompted for their master password and the vault unlocks before showing results.
3. **Given** the user is unauthenticated, **When** the user invokes the workflow, **Then**
   they are prompted to log in and the vault is accessible after successful authentication.
4. **Given** a browser window is in the foreground, **When** the workflow loads, **Then**
   items matching the active tab's domain are ranked first.

---

### User Story 2 - Copy Vault Item Fields (Priority: P1)

After selecting an item from the list, the user can copy a specific field (password,
username, TOTP code, or notes) to the clipboard. The clipboard is cleared after a
configurable timeout and the previous clipboard contents are restored.

**Why this priority**: Copying credentials is the core value delivery action; inseparable
from search in the primary workflow.

**Independent Test**: Select a login item; verify default action copies the password;
verify modifier keys copy username, TOTP, and notes; verify clipboard is restored after
the configured timeout.

**Acceptance Scenarios**:

1. **Given** a login item is selected, **When** the user presses Enter, **Then** the
   password is copied and the clipboard restores after the configured timeout.
2. **Given** a login item is selected, **When** the user holds Control and presses Enter,
   **Then** the username is copied.
3. **Given** a login item with a TOTP secret is selected, **When** the user holds Shift
   and presses Enter, **Then** the current TOTP code is fetched live and copied.
4. **Given** a login item was copied within the last 15 seconds and the password was the
   last field copied, **When** the same item is selected again, **Then** the TOTP code is
   fetched live and copied instead of the password (automatic field rotation).
5. **Given** a secure note is selected, **When** the user presses Enter, **Then** the note
   content is copied to the clipboard.

---

### User Story 3 - Manage Vault Items (Priority: P2)

The user can perform management actions on vault items: mark/unmark as favorite, move to a
folder, download attachments, and delete items. Changes are synced to the Bitwarden server
after each action.

**Why this priority**: Useful but not daily; users can fall back to the Bitwarden app or
web vault for management until this is implemented.

**Independent Test**: Select a login item; open the More Menu; mark it as a favorite;
verify the item appears with a favorite indicator on the next search.

**Acceptance Scenarios**:

1. **Given** an item is selected and the More Menu is opened, **When** the user chooses
   "Mark as Favorite", **Then** the item is marked and the vault is synced.
2. **Given** an item is selected and the More Menu is opened, **When** the user chooses
   "Move to Folder", **Then** a folder list is shown and the item is moved to the selected
   folder after confirmation.
3. **Given** an item with attachments is selected, **When** the user chooses "Download
   Attachment", **Then** the attachment is saved to the configured downloads folder.
4. **Given** an item is selected, **When** the user chooses "Delete Item" and confirms,
   **Then** the item is moved to the vault's Trash and the vault is synced.

---

### User Story 4 - Vault Sync and Background Agent (Priority: P2)

The vault is kept up to date with the Bitwarden server. The user can trigger a manual sync
or configure an automatic background sync on a set interval.

**Why this priority**: Stale vault data causes missed credentials; automated sync reduces
friction significantly.

**Independent Test**: Trigger a manual sync from the main menu; verify the cached data is
updated with any server-side changes.

**Acceptance Scenarios**:

1. **Given** the vault is unlocked, **When** the user selects "Sync Vault" from the main
   menu, **Then** the local cache is refreshed from the server.
2. **Given** the sync interval has elapsed since the last sync, **When** the workflow is
   invoked, **Then** a background sync is triggered without blocking the item list.
3. **Given** Auto Sync is enabled, **When** the configured interval elapses, **Then** the
   background sync agent contacts the server and updates the cache automatically.

---

### User Story 5 - Filter by Vault and Collection (Priority: P3)

The user can restrict searches to a specific vault (organization) or collection to reduce
noise in multi-vault or multi-collection setups and prevent unintentional shoulder-surfing.

**Why this priority**: Only relevant to users with multiple organizations or collections;
a nice-to-have that does not block primary workflows.

**Independent Test**: Set a default vault in the main menu; run a search; verify only
items from that vault appear in results.

**Acceptance Scenarios**:

1. **Given** the user sets a default vault, **When** they search, **Then** only items from
   that vault are shown.
2. **Given** the user sets a default collection, **When** they search, **Then** only items
   in that collection are shown.
3. **Given** the user resets to "All Vaults", **When** they search, **Then** all vault
   items are shown again.

---

### Edge Cases

- What happens when `bw serve` crashes mid-session? The workflow must detect the
  unreachable server and restart it transparently on the next invocation.
- What happens when Keychain access is denied or the stored password is wrong? The workflow
  must fall back to prompting the user and update the Keychain entry on success.
- What happens when neither a native TOTP field nor a custom TOTP field exists for an item?
  The TOTP action must surface a clear "no TOTP configured" message rather than silently
  failing.
- What happens when the downloads folder is not configured? The workflow must prompt the
  user to choose a folder at download time.
- What happens when the Bitwarden CLI or `jq` is not installed? The workflow must detect
  their absence and offer installation via Homebrew or MacPorts.
- How does the workflow behave when concurrent Alfred invocations read the cache
  simultaneously? Cache reads must not produce partial or corrupt results.
- What happens when the active browser tab has a non-standard URL (IP address, localhost,
  `file://`, internal domain without a public TLD)? URL matching must degrade gracefully
  with no crash and no false matches.

## Requirements

### Functional Requirements

- **FR-001**: The workflow MUST compile to a single native macOS binary invoked by Alfred
  with a command name as its first argument.
- **FR-002**: The binary MUST dispatch to the appropriate handler based on the command
  argument without launching additional helper scripts.
- **FR-003**: The workflow MUST support authentication via password login and API Key,
  with optional two-step login (Authenticator app, YubiKey OTP, Email).
- **FR-004**: The workflow MUST maintain an on-disk vault cache; sensitive fields
  (passwords, TOTP secrets — whether in the native TOTP field or a custom field — card
  numbers, and CVCs) MUST be stripped before writing to cache.
- **FR-005**: All read operations (search, list, show, get field) MUST be served from the
  on-disk cache; only explicit sync operations and live TOTP fetches may contact the server.
- **FR-006**: The workflow MUST surface vault items ranked by: browser URL match, recency,
  favorites, then alphabetical name. URL matching MUST use registered domain (eTLD+1)
  comparison — a vault item's stored URL matches the active tab if they share the same
  registered domain (e.g. `mybank.com` matches `login.mybank.com`). Protocol is ignored.
- **FR-007**: Selecting a login item MUST copy its password by default; modifier keys MUST
  copy username (Control), TOTP code (Shift), and notes (Command). The TOTP code MUST be
  fetched live from the server at copy time — never from cache. The workflow MUST first
  attempt the item's native Bitwarden TOTP field; if absent, it MUST fall back to a custom
  field containing a TOTP secret and compute the code locally at runtime.
- **FR-008**: The workflow MUST implement automatic field rotation: if the same login item
  is selected within 15 seconds of copying its password, the TOTP code MUST be copied
  instead.
- **FR-009**: The clipboard MUST be restored to its previous contents after a configurable
  timeout.
- **FR-010**: The workflow MUST manage the background server process using a PID file
  stored in the cache directory; process detection via system inspection tools is not
  permitted.
- **FR-011**: Every command requiring vault access MUST execute an unlock-check sequence:
  start server if unreachable, authenticate if needed, unlock if needed — in that order.
  The master password MUST be stored in the macOS Keychain after first entry and retrieved
  silently for all subsequent unlock and authentication operations. The user MUST only be
  prompted for their password when no Keychain entry exists or Keychain access is denied.
- **FR-012**: The workflow MUST support: marking/unmarking items as favorites, moving
  items to folders, downloading attachments, and deleting items (soft-delete to Trash).
- **FR-013**: The workflow MUST support filtering searches by organization (vault) and
  collection, with preferences persisted across invocations.
- **FR-014**: The workflow MUST include a background sync agent installable as a macOS
  Launch Agent that runs on a configurable interval.
- **FR-015**: The workflow MUST detect missing runtime dependencies and offer to install
  them via Homebrew or MacPorts.
- **FR-016**: Cards and identity items MUST display all fields in a dialog window by
  default when selected.
- **FR-017**: Any vault item MUST be viewable in a detail dialog window for multi-field
  copy/paste without leaving Alfred.
- **FR-018**: The workflow MUST display a macOS notification confirming which field was
  copied to the clipboard. Notifications MUST be suppressible via a workflow setting.
  Errors requiring user action (unlock failure, sync failure) MUST be surfaced as modal
  dialogs, not notifications.

### Key Entities

- **VaultItem**: A single Bitwarden item (login, secure note, card, identity). Attributes:
  id, name, type, folderId, organizationId, collectionIds, favorite flag, type-specific
  fields. Sensitive fields are stripped from the on-disk cache.
- **Folder**: A named grouping for vault items. Attributes: id, name.
- **Organization**: A Bitwarden shared vault. Attributes: id, name.
- **Collection**: A sub-grouping within an organization. Attributes: id, name,
  organizationId.
- **VaultCache**: On-disk store of all vault data with a `lastSyncedAt` timestamp and
  stripped sensitive fields.
- **SyncAgent**: Background process responsible for periodic vault refresh on a
  configurable interval.
- **AlfredItem**: Output representation of a vault item formatted for Alfred's script
  filter JSON protocol, including modifiers and subtitle fields.

## Success Criteria

### Measurable Outcomes

- **SC-001**: The item list appears in Alfred within 500ms of invocation when the vault is
  unlocked and the cache is fresh.
- **SC-002**: A user can complete the full search-and-copy workflow (invoke, search,
  select, clipboard populated) in under 5 seconds under normal conditions.
- **SC-003**: Sensitive fields are absent from all on-disk cache files upon inspection
  after any sync operation.
- **SC-004**: The workflow recovers from a crashed background server process without user
  intervention on the next invocation.
- **SC-005**: All item types (login, secure note, card, identity) display and copy
  correctly for 100% of their supported fields.
- **SC-006**: Background sync completes without interrupting an in-progress Alfred session.
- **SC-007**: The delivered binary is a single file requiring no additional install steps
  beyond placing it in the workflow directory.

## Assumptions

- Target platform is macOS only; iOS and other platforms are out of scope.
- The Bitwarden CLI (`bw`) and `jq` are runtime dependencies; they are not bundled.
- Alfred 5+ is required; older versions are out of scope.
- SSO login is out of scope (not supported by the Bitwarden CLI).
- FIDO2 and Duo two-step login methods are out of scope (not supported by the CLI).
- Firefox browser integration requires the Alfred Integration extension and alfred-firefox
  workflow to be pre-installed by the user.
- Recovering items from the vault Trash is out of scope.
- Creating new vault items is out of scope; management actions are limited to existing
  items (favorite, move, download, delete).
- Homebrew or MacPorts is already installed when the user triggers dependency installation.
- The user stores TOTP secrets as a custom item field as a workaround for lacking a
  Bitwarden premium subscription. Native Bitwarden TOTP (premium feature) is supported as
  the primary path; the custom-field approach is the fallback.
