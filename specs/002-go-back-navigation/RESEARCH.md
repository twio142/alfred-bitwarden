# Research: Go-Back Navigation

> **Note for planning/implementation agents:** This document captures everything relevant from `info.plist`. Do not read that file — it is large, mostly UI layout data, and all workflow mechanics that matter for this feature are summarized here. Focus on the Swift source files under `Sources/`.

## 0. Process Model

The Swift binary (`bw-alfred`) is not a persistent process. It is invoked once per Alfred node execution, produces output (JSON to stdout), and exits. There is no in-memory state between invocations. The only data flowing between invocations are the `arg` and `variables` fields carried by each `AlfredItem`. When the user selects an item, Alfred passes that item's `arg` and `variables` to the next node — nothing else.

## 1. Current Navigation Architecture

### Entry Points

The workflow defines three keyword-triggered script filters in `info.plist`:

| UID        | Keyword | Script                        | Default command    |           |
| ---------- | ------- | ----------------------------- | ------------------ | --------- |
| `2B043930` | `bw`    | `./bw-alfred ${next:-search}` | `search`           |           |
| `399BC9FC` | `bwf`   | `./bw-alfred list_folders`    | hardcoded          |           |
| `DBCCD868` | `\      | bw`                           | `./bw-alfred main` | hardcoded |

`bwf` and `|bw` are direct entry points whose commands are hardcoded. Only the primary `bw` filter is driven by the `next` variable.

### Workflow Object Graph

After an item is selected in the primary filter (`2B043930`), the connection graph is:

```
2B043930 (primary filter)
    └─► 8BB7F5BA (conditional: is {var:action} non-empty?)
            ├─► [yes] 90B0D388 (action runner: ./bw-alfred $action "$@")
            │         + C9F69C59 (HideAlfred, unstackview: false)
            └─► [no]  3E0C6408 (CallExternalTrigger → "bitwarden" = 2B043930, passvariables: true)
```

`399BC9FC` (folders filter) connects directly to `2B043930` with `vitoclose: true`, which runs the primary filter as a follow-up after a folder is selected.

### The `next` Variable

`next` is an Alfred workflow variable. When a user selects an item whose `variables` dict contains `"next": "some_command"`, Alfred stores that as a workflow variable. On re-invocation via CallExternalTrigger, the script `./bw-alfred ${next:-search}` expands to that command.

The conditional node (`8BB7F5BA`) checks whether `{var:action}` is non-empty:

- If `action` is set → the action runner fires (`./bw-alfred $action "$@"`) and Alfred is hidden.
- If `action` is absent → the CallExternalTrigger fires, re-invoking the primary filter with all current variables intact (`passvariables: true`).

### Variable Persistence

`CallExternalTrigger` is configured with `passvariables: true` (`info.plist:244`). This means **all** current Alfred workflow variables survive across menu transitions. Concretely:

- A menu at depth 2 can still read `item_id` that was set at depth 1.
- Variables are never explicitly cleared; old values persist until overwritten.

Variables are read in Swift via `ProcessInfo.processInfo.environment`.

## 2. All Navigation Commands

The command router lives in `Sources/main.swift:3-56`. Commands split into two categories:

### Navigation commands (output a script filter menu)

These produce an `AlfredOutput` with items for further user interaction. They are the commands that would display a "Go Back" item.

| Command            | File                    | Reached via                                                                     |                           |
| ------------------ | ----------------------- | ------------------------------------------------------------------------------- | ------------------------- |
| `search`           | `Search.swift`          | Default (`bw` keyword), or `variables["next": "search", ...]` from folders/main |                           |
| `main`             | `MainMenu.swift`        | `\                                                                              | bw` keyword (direct only) |
| `list_folders`     | `ListFolders.swift`     | `bwf` keyword, or `variables["next": "list_folders"]` from main                 |                           |
| `more`             | `MoreMenu.swift`        | `variables["next": "more", "item_id": id]` (fn modifier in search)              |                           |
| `list_fields`      | `ListFields.swift`      | `variables["next": "list_fields", "item_id": id]` (alt modifier in search)      |                           |
| `list_attachments` | `ListAttachments.swift` | `variables["next": "list_attachments", "item_id": id]` (from `more`)            |                           |
| `set_folder`       | `SetFolder.swift`       | `variables["next": "set_folder", "item_id": id]` (from `more`)                  |                           |
| `set_organization` | `SetOrganization.swift` | `variables["next": "set_organization"]` (from main)                             |                           |
| `set_collection`   | `SetCollection.swift`   | `variables["next": "set_collection"]` (from main)                               |                           |
| `manage_agent`     | `ManageAgent.swift`     | `variables["next": "manage_agent"]` (from main)                                 |                           |

### Action commands (execute and close Alfred)

These run a side-effect and do not display a menu. Back navigation is not relevant here.

`get_field`, `get_attachment`, `set_favorite`, `set_folder` (when called with a folder arg), `delete_item`, `sync_vault`, `lock`, `logout`, `login`, `unlock`, `start_server`, `stop_server`, `install_agent`, `uninstall_agent`.

Note: `set_folder` doubles as both a navigation command (when called with only `item_id`) and an action command (when called with both `item_id` and `folder_id`). In `SetFolder.swift`, `showFolderList(for:)` emits `variables["action": "set_folder"]` on each item, so the final folder selection goes through the action path.

## 3. Menu Item Construction

### `AlfredItem` and `AlfredModItem` structures (`AlfredOutput.swift:38-74`)

```swift
struct AlfredItem: Codable {
    var uid: String?
    var title: String
    var subtitle: String?
    var arg: AlfredArg?
    var icon: AlfredIcon?
    var valid: Bool = true
    var autocomplete: String?
    var mods: AlfredMods?
    var text: AlfredText?
    var variables: [String: String]?
    var quicklookurl: String?
}

struct AlfredModItem: Codable {
    var subtitle: String?
    var arg: AlfredArg?
    var valid: Bool = true
    var variables: [String: String]?
}
```

Navigation items use `variables: ["next": "target"]` with no `action` key. Action items use `variables: ["action": "cmd"]`. Both types carry extra context keys (`item_id`, `folder_id`, `favorites`, etc.) in the same `variables` dict.

### How context keys are consumed

Each command reads its inputs from the environment:

```swift
// MoreMenu.swift:5-6 — positional arg from item.arg
let args = Array(CommandLine.arguments.dropFirst(2))
guard let itemId = args.first else { ... }

// ListFields.swift:7 — prefers positional arg, falls back to env var
let itemId = args.first ?? env["item_id"] ?? ""

// Search.swift:6, 62-69 — reads filter state from env
let env = ProcessInfo.processInfo.environment
if let folderId = env["folder_id"] { ... }
if env["favorites"] == "true" { ... }
```

`MoreMenu` receives `item_id` as a positional CLI argument (passed from the item's `arg` field), not an environment variable. `ListFields` and `SetFolder` accept either source.

## 4. Context Variables in the Environment

The full set of navigation-relevant variables currently in use:

| Variable        | Set by                         | Consumed by                                             |
| --------------- | ------------------------------ | ------------------------------------------------------- |
| `next`          | Any navigation item            | Primary script filter (`${next:-search}`)               |
| `action`        | Any action item                | Conditional node + action runner                        |
| `item_id`       | `search` (fn/alt mods), `more` | `more`, `list_fields`, `list_attachments`, `set_folder` |
| `folder_id`     | `list_folders` items           | `search` (filter)                                       |
| `favorites`     | `list_folders` favorites item  | `search` (filter)                                       |
| `org_id`        | `set_organization` items       | `set_organization` (self, on next invocation)           |
| `collection_id` | `set_collection` items         | `set_collection` (self, on next invocation)             |

Because `passvariables: true`, all of these persist in the environment until explicitly overwritten. A newly set variable value replaces the old one; variables are never deleted, only shadowed.

## 5. Navigation Paths and State Required for Back

The following table shows each navigation edge, and what state would need to be saved to reconstruct the "from" menu when pressing back:

| From menu                     | To menu               | State to restore "from"                 |
| ----------------------------- | --------------------- | --------------------------------------- |
| `search` (unfiltered)         | `more`                | `next=search`                           |
| `search` (unfiltered)         | `list_fields`         | `next=search`                           |
| `search` (filtered by folder) | `more`                | `next=search`, `folder_id=<id>`         |
| `search` (filtered by folder) | `list_fields`         | `next=search`, `folder_id=<id>`         |
| `search` (favorites)          | `more`                | `next=search`, `favorites=true`         |
| `more`                        | `list_attachments`    | `next=more`, `item_id=<id>` (arg-based) |
| `more`                        | `set_folder` (picker) | `next=more`, `item_id=<id>`             |
| `list_folders`                | `search` (filtered)   | `next=list_folders`                     |
| `main`                        | `list_folders`        | `next=main`                             |
| `main`                        | `set_organization`    | `next=main`                             |
| `main`                        | `set_collection`      | `next=main`                             |
| `main`                        | `manage_agent`        | `next=main`                             |

`main` cannot appear as a "to" menu via the `next` mechanism (it is only triggered by the `|bw` keyword), so it has no "Go Back" needed.

## 6. Back Stack Serialization Constraints

Alfred workflow variables are plain strings. There is no native Alfred API for arrays or structured data in variables. A navigation stack must therefore be serialized into a single string variable.

Because `passvariables: true` carries all current variables forward, a stack variable set during one invocation will persist into subsequent ones unless explicitly overwritten. However, each navigation item that moves forward must explicitly set the updated stack value in its own `variables` dict, since `passvariables` only preserves the value from the previous step — it does not update it.

Concretely:

- Each forward-navigation item (one with `"next": "..."` in its variables) must set the stack variable to the new value — with the current menu's state pushed onto it.
- The "Go Back" item must set the stack variable to the popped value, and set `next` and any context keys to the previous menu's state.
- The Swift process reads the incoming stack string from its environment (`ProcessInfo.processInfo.environment`), modifies it, and writes the result into the outgoing items' `variables` dicts before printing JSON and exiting.

## 7. Context Variable Cleanup on Back Navigation

Because stale variables persist via `passvariables: true`, a "Go Back" item must explicitly clear any context variables that are no longer valid for the destination menu. The table below identifies which variables need clearing per back transition.

| Back transition                | Variables to clear       |
| ------------------------------ | ------------------------ |
| `search` → `list_folders`      | `folder_id`, `favorites` |
| `list_folders` → `main`        | `folder_id`, `favorites` |
| `more` → `search`              | none                     |
| `list_fields` → `search`       | none                     |
| `list_attachments` → `more`    | none                     |
| `set_folder` (picker) → `more` | none                     |
| `set_organization` → `main`    | none                     |
| `set_collection` → `main`      | none                     |
| `manage_agent` → `main`        | none                     |

**Why `folder_id` and `favorites` require cleanup:**
Both are set by `list_folders` items and consumed by `search`. If they persist past a `list_folders` node on the way back, any subsequent unrelated navigation to `search` (e.g. from `main → "Search Vault"`) would silently apply the stale filter. Concretely:

```
main → list_folders → search (folder_id=X) → back → list_folders → back → main → search
```

Without cleanup, the final `search` sees `folder_id=X` and filters incorrectly.

**Why `item_id` does not require cleanup:**
`item_id` is only consumed by `more`, `list_fields`, `list_attachments`, and `set_folder` — all of which are always reached by fresh forward navigation that sets a new `item_id`. No menu reads a stale `item_id` by accident.

**Why `org_id` and `collection_id` do not require cleanup:**
`SetOrganization` and `SetCollection` read their input from positional CLI arguments, not from the environment. A stale env value is never acted on.

**Sentinel value for clearing:**
Alfred has no mechanism to delete a variable; it can only be overwritten. The "Go Back" item must set `folder_id` and `favorites` to a value that `Search.swift` treats as "no filter." Currently `search` uses `if let folderId = env["folder_id"]` — any non-nil value, including `""`, triggers the filter branch. The clearing sentinel and any corresponding guard in `search` need to be agreed upon during implementation.

## 8. Which Menus Need "Go Back"

A menu needs a "Go Back" item if and only if it can be reached via the `next` variable (as opposed to a direct keyword). Based on the connection table:

**Always need back** (only reachable via `next`):

- `more`
- `list_fields`
- `list_attachments`
- `set_folder` (picker phase)
- `set_organization`
- `set_collection`
- `manage_agent`

**Conditionally need back** (reachable both by keyword and by `next`):

- `search` — reached by keyword (`bw`) with no stack, or via `next=search` with a stack (e.g., from `list_folders`)
- `list_folders` — reached by keyword (`bwf`) or via `next=list_folders` from `main`

The presence of a non-empty stack variable is the signal that "Go Back" should be shown.
