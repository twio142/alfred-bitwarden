# Research: Full Swift Rewrite of Bitwarden Alfred Workflow

## 1. TOTP Computation in Swift

**Decision**: Implement TOTP locally using CryptoKit's `HMAC<Insecure.SHA1>` with a
custom Base32 decoder. No third-party libraries.

**Rationale**: RFC 6238 TOTP is straightforward: decode the Base32 secret, compute
`HMAC-SHA1(key, floor(time / 30))`, extract a 6-digit code from the result. CryptoKit
ships with macOS 10.15+ and covers the HMAC. Base32 decoding is ~40 lines of Swift.
Avoids any dependency for a security-sensitive computation.

**Algorithm**:
1. Base32-decode the secret string (strip spaces, uppercase, padding-tolerant)
2. Counter = `UInt64(Date().timeIntervalSince1970 / 30)` as big-endian bytes
3. HMAC-SHA1(key: decodedSecret, data: counterBytes)
4. Dynamic truncation: offset = last nibble of digest; extract 4 bytes at offset,
   mask top bit, modulo 10^6

**Alternatives considered**:
- `SwiftOTP` package: rejected — adds a dependency for ~50 lines of logic
- Calling `bw` CLI for TOTP: viable only when native TOTP field is present (pro feature);
  used as primary path, custom-field computation is fallback

**Custom field name convention**: The field named `totp` (case-insensitive) on a login
item is treated as the TOTP secret for the fallback path.

---

## 2. macOS Keychain Storage

**Decision**: Use `Security.framework` directly (`SecItemAdd`, `SecItemCopyMatching`,
`SecItemUpdate`, `SecItemDelete`). Service name `bw-alfred`, account = user's Bitwarden
email address.

**Rationale**: Security.framework is always available on macOS. No wrapper library
needed. The four CRUD operations cover all required interactions. Storing the master
password as UTF-8 `Data` under a stable service+account key is idiomatic.

**Item attributes**:
```
kSecClass: kSecClassGenericPassword
kSecAttrService: "bw-alfred"
kSecAttrAccount: <email>
kSecValueData: <password as UTF-8 Data>
kSecAttrAccessible: kSecAttrAccessibleWhenUnlocked
```

**Alternatives considered**:
- `KeychainAccess` package: rejected — unnecessary dependency
- Storing session token: rejected — session token is ephemeral and tied to the running
  `bw serve` process; storing it provides no durable value across restarts

---

## 3. eTLD+1 URL Matching

**Decision**: Implement a lightweight heuristic eTLD+1 extractor using a small embedded
list of known multi-part public suffixes (`.co.uk`, `.com.au`, etc.). For everything
else, use the last two domain labels.

**Rationale**: Swift's `URLComponents` gives the full host but no eTLD+1 awareness.
Embedding the full Mozilla Public Suffix List (~250 KB) is disproportionate for a single
matching feature. A curated list of ~50 common second-level TLDs covers the vast majority
of real-world cases. The matching logic compares extracted eTLD+1 of the vault item URI
against the extracted eTLD+1 of the active browser tab URL.

**Algorithm**:
1. Parse host from URL string using `URLComponents`
2. Split host by `.` into labels
3. Check if last two labels form a known compound suffix (e.g. `co.uk`); if so, take
   last three labels as registered domain; otherwise take last two
4. Strip `www.` prefix before comparison

**Edge cases from spec**:
- IP addresses, `localhost`, `file://`, internal hostnames with no public TLD → skip URL
  matching entirely (no crash, no false matches); fall through to standard ranking

**Alternatives considered**:
- Full Public Suffix List: rejected — 250 KB embedded data for marginal accuracy gain
- Exact host match: rejected — misses `www.` and subdomain variants
- URLComponents `.host` substring match: rejected — too loose, would match `evil-mybank.com`

---

## 4. `bw serve` REST API

**Decision**: All vault interactions go through the local `bw serve` HTTP server on
`http://localhost:8087` (default port, configurable via `BW_SERVE_PORT`).

**Key endpoints**:

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/status` | Auth + lock status |
| POST | `/unlock` | Unlock vault; body: `{"password":"..."}` |
| POST | `/lock` | Lock vault |
| POST | `/sync` | Sync from server |
| GET | `/list/object/items` | All items (search with `?search=`) |
| GET | `/list/object/folders` | All folders |
| GET | `/list/object/collections` | All collections |
| GET | `/list/object/organizations` | All organizations |
| GET | `/object/item/{id}` | Single item (used for live TOTP fetch) |
| PUT | `/object/item/{id}` | Update item (favorite, folder) |
| DELETE | `/object/item/{id}` | Delete item (to Trash) |
| GET | `/object/attachment/{id}?itemid={itemId}` | Download attachment |

**Auth header**: `Authorization: Bearer {session_token}` on all requests except
`/status` and `/unlock`.

**Session token**: Returned in the response body of `/unlock` as `{"data":{"raw":"..."}}`.
Also available from `bw unlock` CLI command output.

**Starting `bw serve`**: `bw serve --port 8087` as a detached `Process`. Write PID to
`{cacheDir}/bw-serve.pid`. Health check: poll `GET /status` until 200 or timeout (3s).

**Login flow** (before serve is useful): `bw login <email> --passwordenv BW_PASSWORD`
(or API key variant) via CLI subprocess — `bw serve` handles auth state after login.

---

## 5. Alfred Script Filter Output Format

**Decision**: Swift `Codable` structs encoding to Alfred's script filter JSON schema.
Output via `JSONEncoder` to stdout. All output paths go through a single `AlfredOutput`
top-level type.

**Top-level structure**:
```json
{
  "items": [...],
  "variables": {...},
  "rerun": 0.5
}
```

**Item structure** (all fields optional except `title`):
```json
{
  "uid": "stable-id",
  "title": "Item name",
  "subtitle": "username • mysite.com",
  "arg": "item-id",
  "icon": {"path": "icons/login.png"},
  "valid": true,
  "autocomplete": "",
  "mods": {
    "ctrl": {"subtitle": "Copy username", "arg": "username", "valid": true},
    "shift": {"subtitle": "Copy TOTP", "arg": "totp", "valid": true},
    "cmd": {"subtitle": "Copy notes", "arg": "notes", "valid": true},
    "alt": {"subtitle": "More actions…", "arg": "more", "valid": true},
    "fn": {"subtitle": "Show all fields", "arg": "show", "valid": true}
  },
  "text": {"copy": "value", "largetype": "value"},
  "variables": {"item_id": "...", "last_field": "password"}
}
```

**Variables**: Alfred passes workflow variables via environment. The binary sets
per-item variables using the `variables` key on items to thread state through Alfred's
action chain (e.g., `item_id`, `last_copied_field`, `last_copied_at`).

---

## 6. macOS Launch Agent (Background Sync)

**Decision**: Generate a `launchd` plist at
`~/Library/LaunchAgents/com.alfred.bw-alfred.sync.plist`. Install/uninstall via
`launchctl bootstrap`/`launchctl bootout` (macOS 10.11+ API; avoids deprecated
`load`/`unload`).

**Plist structure**:
```xml
<plist version="1.0">
<dict>
  <key>Label</key><string>com.alfred.bw-alfred.sync</string>
  <key>ProgramArguments</key>
  <array>
    <string>/path/to/bw-alfred</string>
    <string>sync_vault</string>
  </array>
  <key>StartInterval</key><integer>{syncIntervalSeconds}</integer>
  <key>RunAtLoad</key><false/>
</dict>
</plist>
```

**Alternatives considered**:
- `launchctl load/unload`: deprecated since macOS 10.11; avoided
- `NSBackgroundActivityScheduler`: requires an app bundle; not available to CLI binaries

---

## 7. Synchronous HTTP from a CLI Binary

**Decision**: Use `DispatchSemaphore` to block the main thread until
`URLSession.dataTask` completes. All BWClient calls are synchronous from the caller's
perspective.

**Pattern**:
```swift
func get(_ path: String) throws -> Data {
    var result: Result<Data, Error>?
    let sem = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: request) { data, response, error in
        result = ...
        sem.signal()
    }.resume()
    sem.wait()
    return try result!.get()
}
```

**Rationale**: Alfred script filters run synchronously and must write JSON to stdout
then exit. Async/await would require a `@main` actor and RunLoop management — more
complexity than a semaphore for a CLI tool with no UI event loop.

**Timeout**: 5 seconds per request (URLSession `timeoutIntervalForRequest`). Commands
that require a server call show an error item if the timeout is exceeded.
