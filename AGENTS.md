# AGENTS Guide for SwiftUI-SotkaApp

This file is for coding agents working in this repository.
Follow these repo-specific conventions and commands.

## Project Snapshot

- Platform: iOS + watchOS app (SwiftUI, SwiftData, Observation).
- Main app target: `SwiftUI-SotkaApp`.
- iOS unit test target: `SwiftUI-SotkaAppTests`.
- iOS UI test target: `SwiftUI-SotkaAppUITests`.
- Watch app target: `SotkaWatch Watch App`.
- Watch unit test target: `SotkaWatch Watch AppTests`.
- Build system: Xcode project (`SwiftUI-SotkaApp.xcodeproj`).
- Package dependencies are local Swift packages in `SwiftUI-SotkaApp/Libraries/`.

## Source of Truth for Rules

- Primary contributor rules: `.github/CONTRIBUTING.md`.
- Copilot instructions file not found: `.github/copilot-instructions.md` is absent.

## Test Commands

- Test execution priority for agents:
  1) Use `xcodebuildmcp` tools first for build/test/run flows.
  2) If MCP tools are unavailable or fail, use direct `xcodebuild` commands.
  3) Use `make test` / `make test_watch` as convenience fallback for full plans.

## Test Strategy and Framework Conventions

- Unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`).
- UI tests use XCTest and launch app with argument `UITest`.
- The app has DEBUG-only mock bootstrapping for UI tests (`MockSWClient`, `ScreenshotDemoData`).
- Prefer deterministic tests with in-memory `ModelContainer` for SwiftData.
- Use mocks from `SwiftUI-SotkaAppTests/Mocks/` for network/service isolation.

## Architecture and Design Conventions

- Use MVVM with `@Observable` view models/services where appropriate.
- Keep modular structure: `Screens`, `Services`, `Models`, `Extensions`, `PreviewContent`.
- Prefer dependency injection via `Environment` and protocol-based clients.
- Client protocols live under `Services/Protocols/`.
- `SWClient` acts as the concrete API client implementing multiple client protocols.

## Offline-First and Sync Rules

- Offline-first is mandatory for app behavior.
- Persist locally first (SwiftData), then sync asynchronously.
- Sync must be optional and non-blocking for user flows.
- Exception: authentication requires network.
- SwiftData entities used for sync commonly carry flags like `isSynced`, `shouldDelete`, `lastModified/modifyDate`.

## Single-User Data Model Rules

- Assume one active user at a time.
- On login: user data is stored locally.
- On logout: user data must be cleared.

## Swift Style Rules

- Run `make format` after any code changes.
- Keep one primary component per file where practical.
- Name services as `...Service` or `...Manager`.
- Name view models as `...ViewModel`.
- For SwiftUI views:
  - Parameterless view fragments: computed property ending with `View`.
  - Parameterized view fragments: function prefixed with `make`.
  - Use `@ViewBuilder` only for real conditional/multi-view composition.
- Favor small focused extensions and `// MARK:` sections.

## Imports, Types, and Concurrency

- Prefer protocol types for dependencies (`DaysClient`, `StatusClient`, etc.).
- Mark UI/stateful domain objects with `@MainActor` when they mutate UI-related state.
- Adopt `Sendable` where cross-concurrency usage is expected.
- Do not use force unwrapping optionals (`!`) in production code or tests; only allow rare preview/demo stubs where failure is non-user-facing.
- In tests, prefer `try #require(optional)` over force unwrap.

## Error Handling and Logging

- Use `OSLog` (`Logger`) for operational logs and diagnostics.
- Do not leave TODO comments as a substitute for logging/tracking.
- Surface recoverable errors gracefully (alerts, state updates).
- Fail fast only for unrecoverable startup conditions.
- Keep error messages actionable and include context (entity/day/id when possible).

## Naming and Domain Semantics

- Preserve existing domain terminology (`DayActivity`, `UserProgress`, `SyncJournalEntry`).
- Keep API DTO naming aligned with server contracts (`...Request`, `...Response`).
- Keep Russian-localized user strings in localization resources, not hardcoded in logic.

## Agent Workflow Checklist

- Read relevant docs in `docs/` before major edits.
- Make smallest safe change set; avoid unrelated refactors.
- Run `make format` then the most targeted tests first.
- For broad changes, run full test plans (`xcodebuildmcp` preferred; `make test` / `make test_watch` as fallback).
- If you touch UI test flows, validate launch argument `UITest` assumptions.

## Practical File Pointers

- Formatting rules: `.swiftformat`
- Build/test automation: `Makefile`
- Contributor process: `.github/CONTRIBUTING.md`
- App entry point: `SwiftUI-SotkaApp/SwiftUI_SotkaAppApp.swift`
- iOS test plan: `SwiftUI-SotkaAppTests/SwiftUI-SotkaAppTests.xctestplan`
- UI test plan: `SwiftUI-SotkaAppUITests/SwiftUI-SotkaAppUITests.xctestplan`
- Watch test plan: `SotkaWatch Watch AppTests/SotkaWatch-UnitTests.xctestplan`
