<!--
Sync Impact Report
==================
Version change: [placeholder] → 1.0.0 (initial constitution)
Bump type: MINOR (first real population of all sections)

Added sections:
  - Core Principles I–V (Swift-Native, Alfred Protocol, Credential Security,
    Cache-First Performance, Simplicity)
  - Security & Privacy
  - Development Workflow
  - Governance

Removed sections: N/A (initial creation from template)

Templates requiring updates:
  - .specify/templates/plan-template.md ✅ (Constitution Check updated with real gates)
  - .specify/templates/spec-template.md ✅ (no constitution-specific changes needed)
  - .specify/templates/tasks-template.md ✅ (no constitution-specific changes needed)

Follow-up TODOs: None — all placeholders resolved.
-->

# Alfred Bitwarden Constitution

## Core Principles

### I. Swift-Native, macOS-First

The workflow is written entirely in Swift 6+ targeting macOS 15.0+. No scripting
languages, interpreted runtimes, or bundled language environments are permitted.
Native Apple frameworks (Security, Foundation, UserNotifications) MUST be preferred
over third-party dependencies. External packages require explicit justification.

**Rationale**: A native binary delivers the sub-100ms cold-start performance Alfred
users expect and eliminates the Python/Node version fragility that plagued earlier
workflow generations.

### II. Alfred Protocol Compliance

All user-facing output MUST conform to the Alfred JSON Script Filter format. Every
result item MUST include `uid`, `title`, `subtitle`, `arg`, and `icon` fields.
Modifier keys (`cmd`, `ctrl`, `shift`, `alt`, `fn`) MUST be declared explicitly where
supported. Output is written to stdout; errors and diagnostics go to stderr. No output
format other than Alfred JSON is produced by the main executable.

**Rationale**: Strict protocol adherence ensures Alfred controls sorting, history, and
learning. Deviation breaks Alfred's built-in features silently.

### III. Credential Security (NON-NEGOTIABLE)

Secrets (master password, session token, TOTP seeds) MUST be stored in macOS Keychain
only. They MUST NOT be written to files, environment variables, Alfred workflow
variables, or any cache layer. TOTP seeds fetched at runtime MUST NOT be persisted
to disk. Clipboard operations that copy secrets MUST schedule a clear-and-restore after
the configured timeout.

**Rationale**: Bitwarden's value proposition is protecting credentials. Writing secrets
outside the Keychain defeats the purpose of a password manager workflow.

### IV. Cache-First Performance

The vault MUST be served from an on-disk cache (JSON, never SQLite or a database server)
to guarantee Alfred results appear within 100ms. Network calls to the Bitwarden CLI are
deferred entirely to the background sync agent (LaunchAgent). Cache invalidation is
explicit and triggered by user action or sync completion, never automatic on read. Cache
MUST NOT store TOTP seeds or any secret material.

**Rationale**: `bw` CLI startup time is 200–800ms. An in-process JSON cache read is
<5ms. User-perceived latency is the primary quality metric.

### V. Simplicity & Minimal Footprint

The project MUST compile to a single executable target. Commands are discrete entry
points dispatched from `main.swift`. No shared mutable global state is permitted across
commands. The optional LaunchAgent sync agent is the only permitted long-running process.
Abstractions require a concrete second use case before introduction. If a change can be
done in 50 lines, a 200-line version requires justification.

**Rationale**: Fewer moving parts mean fewer failure modes and easier community
maintenance. Complexity must earn its place.

## Security & Privacy

- The workflow MUST request only the macOS permissions it actually uses.
- No telemetry, analytics, or network calls to non-Bitwarden endpoints are permitted.
- The `bw` CLI binary path MUST be configurable; the workflow MUST NOT assume a
  hardcoded path (e.g., `/usr/local/bin/bw`).
- Clipboard timeout MUST default to 45 seconds and MUST be user-configurable.
- Error dialogs MUST NOT display raw credential values or session tokens.

## Development Workflow

- Swift Package Manager is the sole build system. No Xcode project files are required
  in the repository.
- The `swift-testing` framework is used for all tests. XCTest is not added as a
  dependency.
- Tests MUST pass (`swift test`) before any commit that touches `Sources/`.
- The compiled binary is checked into the repository at `bw-alfred` for distribution
  without requiring end-users to build from source.
- `info.plist` is the Alfred workflow manifest; it MUST stay in sync with the binary's
  command interface.

## Governance

This constitution supersedes all other practices documented in this repository. When
a CLAUDE.md rule or ad-hoc convention conflicts with a principle here, this document
wins. Amendments require:

1. A PR describing the change and its motivation.
2. A version bump following the rules below.
3. An update to this file's Sync Impact Report comment.

**Versioning policy**:
- MAJOR: Removal or redefinition of an existing principle.
- MINOR: New principle or section added.
- PATCH: Clarifications, wording, or non-semantic refinements.

All PRs and code reviews MUST verify compliance with Principles I–V. Complexity
violations (Principle V) MUST be recorded in the plan's Complexity Tracking table with
explicit justification.

**Version**: 1.0.0 | **Ratified**: 2026-06-09 | **Last Amended**: 2026-06-09