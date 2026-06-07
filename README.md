# Alfred Bitwarden

High-performance Alfred workflow for Bitwarden.

This workflow is a complete Swift rewrite of the original [Bitwarden Accelerator](https://github.com/ajrosen/Bitwarden-Accelerator).

## Setup

1. Type `bw` and select **Login**.
2. Master password is saved to **macOS Keychain** for silent re-unlock.
3. Requires **Bitwarden CLI** (`bw`).

## Search & Priority

Results are ranked automatically:
1. **Browser Match**: Matches active tab domain in Safari, Chrome, Firefox, Arc, etc.
2. **Recent**: Last used items.
3. **Favorites**: Items marked ❤️.
4. **Alphabetical**: Rest of the vault.

## Keyboard Shortcuts

| Key         | Action                                                |
| :---------- | :---------------------------------------------------- |
| **Enter**   | Copy Password / Secure Note                           |
| **Control** | Copy Username                                         |
| **Shift**   | Copy TOTP Code                                        |
| **Command** | Copy Notes                                            |
| **Option**  | Open **More Menu** (Favorite, Move, Download, Delete) |
| **Fn**      | Show all fields in dialog                             |

## Management (Option + Enter)

- **Mark Favorite** / **Move to Folder**
- **Download Attachments**
- **Delete Item** (to Trash)

## Background Sync

Lightweight agent keeps vault fresh. Configure interval in Workflow Settings.

---
*Firefox requires [Alfred Integration](https://addons.mozilla.org/en-US/firefox/addon/alfred-launcher-integration) extension.*
