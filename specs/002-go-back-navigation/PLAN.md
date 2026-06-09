# Plan: Go-Back Navigation

## Goal

Each navigation menu shows a "Go Back" item at the bottom when there is a previous menu to return to. The full route is stored as a stack so the user can navigate back through an arbitrarily deep chain without jumping in loops.

## Core Mechanism

The navigation stack is serialized into a single Alfred workflow variable `nav_stack`. Because `passvariables: true` carries all variables across invocations, a stack value set on one item persists into the next menu automatically — the binary just reads it from the environment, modifies it, and writes the result into outgoing items' `variables` dicts.

**Wire format** — a pipe-separated list of command names, newest frame on the left:

```
stack ::= command ("|" command)*
```

Examples:

- `"search"` — navigated forward from search
- `"list_folders"` — navigated forward from list_folders
- `"search|list_folders"` — navigated forward from search, which was itself reached from list_folders

## Files to Create

### `Sources/Alfred/NavStack.swift`

Push/pop over a pipe-delimited string of command names:

```swift
enum NavStack {
    static func push(_ command: String, onto existing: String) -> String
    static func pop(from stack: String) -> (command: String?, remaining: String)
}
```

## Files to Modify

### `Search.swift`

1. **Clearing sentinel** — `folder_id = ""` means "no filter active" (used by Go Back items). `folder_id = "__NULL__"` means "items with no folder assigned" (replaces the current unreachable `folderId.isEmpty` branch):

   ```swift
   if let folderId = env["folder_id"], !folderId.isEmpty {
       if folderId == "__NULL__" {
           items = items.filter { $0.folderId == nil }
       } else {
           items = items.filter { $0.folderId == folderId }
       }
   }
   ```

2. **Push stack in modifiers** — `alt` (list_fields) and `fn` (more) modifier items need `nav_stack` in their variables:

   ```swift
   let pushed = NavStack.push("search", onto: env["nav_stack"] ?? "")
   // add "nav_stack": pushed to alt/fn mod variables
   ```

3. **Go Back item** — if `env["nav_stack"]` is non-empty, append a Go Back item after the results list. Pops the stack, sets `next` to the popped command. No stale vars to clear for transitions back to search.

### `MoreMenu.swift`

1. **Add env fallback for item_id** — add env fallback so Go Back items can reach MoreMenu via `item_id` in variables (same pattern as `SetFolder`/`ListFields`):

   ```swift
   let itemId = args.first ?? env["item_id"] ?? ""
   ```

2. **Push stack in forward items** — "Move to Folder" and "Download Attachment" items need `nav_stack` in their variables:

   ```swift
   let pushed = NavStack.push("more", onto: env["nav_stack"] ?? "")
   // add "nav_stack": pushed to those items' variables
   ```

3. **Go Back item** — append if `env["nav_stack"]` is non-empty. No stale vars to clear for this transition.

### `ListFolders.swift`

1. **Push stack in items** — favorites item and all folder items navigate to `search`. Push current command:

   ```swift
   let pushed = NavStack.push("list_folders", onto: env["nav_stack"] ?? "")
   // add "nav_stack": pushed to each item's variables
   ```

2. **Go Back item** — append if `env["nav_stack"]` is non-empty. Going back from `list_folders` requires clearing `folder_id` and `favorites` (they were set by list_folders items on the way forward and would leak into any subsequent search). Set both to sentinel `""` on the Go Back item.

### Go-Back-only menus

These menus have no forward navigation items, so they only need a Go Back item appended when the stack is non-empty. No stale vars to clear for any of these transitions.

| File                                  | Notes                               |
| ------------------------------------- | ----------------------------------- |
| `ListFields.swift`                    | Stack non-empty → Go Back to search |
| `ListAttachments.swift`               | Stack non-empty → Go Back to more   |
| `SetFolder.swift` (picker phase only) | Stack non-empty → Go Back to more   |
| `SetOrganization.swift`               | Stack non-empty → Go Back           |
| `SetCollection.swift`                 | Stack non-empty → Go Back           |
| `ManageAgent.swift`                   | Stack non-empty → Go Back           |

### `MainMenu.swift`

No changes. Main is keyword-only (`|bw`) and unreachable via `next`, so it never appears on the stack.

## Tests

No existing tests need updating — none cover command logic or filter behaviour.

### New: `Tests/bw-alfredTests/NavStackTests.swift`

`NavStack` is pure logic with no dependencies, so unit tests are straightforward:

- `push("search", onto: "")` → `"search"`
- `push("more", onto: "search")` → `"more|search"`
- `pop(from: "search")` → `("search", "")`
- `pop(from: "more|search")` → `("more", "search")`
- `pop(from: "")` → `(nil, "")`

### New: `Tests/bw-alfredTests/GoBackTests.swift`

Tests for Go Back item construction across the affected menus. Each test sets up a fake environment dict and a minimal vault cache, calls the relevant `makeItems`-style function, and asserts on the output.

- Search with `nav_stack = ""`: no Go Back item in output
- Search with `nav_stack = "list_folders"`: Go Back item present; `variables["next"] == "list_folders"`, `variables["nav_stack"] == ""`
- ListFolders Go Back item: `variables["folder_id"] == ""`, `variables["favorites"] == ""`
- MoreMenu forward items: `variables["nav_stack"] == "more"` (or `"more|<existing>"`)
- MoreMenu Go Back item: `variables["next"]` matches popped command, `variables["nav_stack"]` matches remaining stack
- Deep path (`nav_stack = "search|list_folders"`): Go Back in more sets `nav_stack = "list_folders"`, Go Back in search sets `nav_stack = ""` and clears filter vars
