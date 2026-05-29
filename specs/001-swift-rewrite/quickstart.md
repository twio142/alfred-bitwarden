# Quickstart: Building and Testing bw-alfred

## Prerequisites

- Xcode 15+ (provides Swift 5.9 and `swift` CLI)
- Bitwarden CLI (`bw`) installed: `brew install bitwarden-cli`
- `jq` installed: `brew install jq`
- A Bitwarden account for integration testing

## Build

```bash
# From the repo root (where Package.swift lives)
swift build -c release

# Binary is at:
.build/release/bw-alfred
```

## Development Build (debug symbols, faster compile)

```bash
swift build
# Binary at .build/debug/bw-alfred
```

## Run Tests

```bash
swift test
```

## Install into Alfred Workflow

```bash
# Copy the release binary to the workflow directory
cp .build/release/bw-alfred /path/to/alfred/workflow/
```

Alfred's workflow objects call `./bw-alfred <command>` with the binary placed at the
workflow root.

## Manual Command Testing

Test any command by invoking the binary directly. Alfred environment variables must be
set manually:

```bash
export alfred_workflow_cache="$HOME/.cache/bw-alfred-dev"
export alfred_workflow_data="$HOME/.local/share/bw-alfred-dev"
export bw_email="you@example.com"
export bw_server="https://bitwarden.com"
export bw_login_method="password"
export bw_clipboard_time="30"
export bw_sync_interval="60"
export bw_notifications="true"
mkdir -p "$alfred_workflow_cache" "$alfred_workflow_data"

# Show main menu
.build/debug/bw-alfred main | jq .

# Search vault (requires unlocked vault)
.build/debug/bw-alfred search "github" | jq .

# Check server status
.build/debug/bw-alfred main | jq '.items[].title'
```

## Cache Inspection

```bash
# View cache (sensitive fields should be absent)
jq . "$alfred_workflow_cache/vault-cache.json"

# Verify no passwords in cache
jq '[.items[].login.password // empty]' "$alfred_workflow_cache/vault-cache.json"
# Expected: []

# Verify no TOTP secrets in cache
jq '[.items[].login.totp // empty]' "$alfred_workflow_cache/vault-cache.json"
# Expected: []

# Verify no hidden custom field values in cache
jq '[.items[].fields[]? | select(.type == 1) | .value // empty]' \
  "$alfred_workflow_cache/vault-cache.json"
# Expected: []
```

## Keychain Inspection

```bash
# Check if master password is stored (should show entry after first unlock)
security find-generic-password -s "bw-alfred" -a "you@example.com"

# Delete stored password (to test fresh-login flow)
security delete-generic-password -s "bw-alfred" -a "you@example.com"
```

## Validate Alfred JSON Output

Every command must produce valid Alfred JSON. Quick check:

```bash
.build/debug/bw-alfred search "" | jq 'if .items then "OK: \(.items | length) items" else "FAIL: \(.)" end'
```

## Testing TOTP Fallback

1. Create a test login item in Bitwarden with a custom field named `totp` (hidden type)
   containing a valid Base32 TOTP secret (e.g. from a test account at
   https://totp.app/)
2. Sync vault
3. Verify the secret is NOT in cache: `jq '.items[] | select(.name=="Test TOTP") | .fields' cache.json`
4. Copy TOTP: `.build/debug/bw-alfred get_field <item_id> totp`
5. Verify a 6-digit code is placed on the clipboard

## bw serve Lifecycle Testing

```bash
# Start server manually
.build/debug/bw-alfred start_server

# Check PID file
cat "$alfred_workflow_cache/bw-serve.pid"

# Kill server manually to test crash recovery
kill $(cat "$alfred_workflow_cache/bw-serve.pid")

# Next command should restart server transparently
.build/debug/bw-alfred search "" | jq '.items | length'

# Stop server cleanly
.build/debug/bw-alfred stop_server
```
