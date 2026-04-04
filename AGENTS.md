# AGENTS Guide for SwiftUI-SotkaApp

This file is for coding agents working in this repository.
Follow these repo-specific conventions and commands.

## Project Snapshot

- Platform: iOS 17+ and watchOS app (SwiftUI, SwiftData, Observation).
- Main app target: `SwiftUI-SotkaApp`.
- iOS unit test target: `SwiftUI-SotkaAppTests`.
- iOS UI test target: `SwiftUI-SotkaAppUITests`.
- Watch app target: `SotkaWatch Watch App`.
- Watch unit test target: `SotkaWatch Watch AppTests`.
- Build system: Xcode project (`SwiftUI-SotkaApp.xcodeproj`).
- Package dependencies: local Swift packages in `SwiftUI-SotkaApp/Libraries/`.

## Source of Truth for Rules

- Primary contributor rules: `.github/CONTRIBUTING.md`.
- Project rules: `.agents/rules/` (MDC files with `alwaysApply: true` contain mandatory conventions).

## Build/Lint/Format Commands

- `make setup` - Install all tools (Homebrew, rbenv, Ruby, bundler, fastlane, swiftformat).
- `make format` - Format Swift code with swiftformat + markdown files with markdownlint.
- `make build` - Build iOS project for iPhone 13 Pro Simulator.
- `make test` - Run all iOS unit tests.
- `make test_watch` - Run all watchOS unit tests.

### Single Test Execution

Run a single test class:

```bash
xcodebuild -project SwiftUI-SotkaApp.xcodeproj \
  -scheme SwiftUI-SotkaAppTests \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro,OS=18.6' \
  test -testPlan SwiftUI-SotkaAppTests \
  -only-testing:SwiftUI-SotkaAppTests/WorkoutViewModelTests
```

Run a single test method:

```bash
xcodebuild -project SwiftUI-SotkaApp.xcodeproj \
  -scheme SwiftUI-SotkaAppTests \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 13 Pro,OS=18.6' \
  test -testPlan SwiftUI-SotkaAppTests \
  -only-testing:SwiftUI-SotkaAppTests/WorkoutViewModelTests/testLoadData
```

For watch tests, replace scheme with `SotkaWatch Watch AppTests` and use `-sdk watchsimulator`.

## Test Strategy and Framework Conventions

- Unit tests use Swift Testing (`import Testing`, `@Test`, `#expect`, `#require`).
- UI tests use XCTest and launch app with argument `UITest`.
- DEBUG-only mock bootstrapping for UI tests (`MockSWClient`, `ScreenshotDemoData`).
- Prefer deterministic tests with in-memory `ModelContainer` for SwiftData.
- Use mocks from `SwiftUI-SotkaAppTests/Mocks/` for network/service isolation.
- TDD: Red-Green-Refactor cycle. Write tests before implementation.

## Swift Style Rules (swiftformat)

Key `.swiftformat` settings applied by `make format`:

- Semicolons: never
- Commas: inline
- Trailing commas: never
- Max line width: 140
- Wrap arguments/parameters/collections: before-first
- Type inferred redundancy removal enabled
- Sort imports enabled
- No redundant `self` in init-only contexts

## SwiftUI View Conventions

- Parameterless view fragments: computed property with `View` suffix (e.g., `var emptyStateView: some View`).
- Parameterized view fragments: function with `make` prefix (e.g., `func makeIconButton(for type: IconType) -> some View`).
- Use `@ViewBuilder` only for real conditional/multi-view composition, NOT for simple containers (VStack, HStack).
- Keep one primary component per file.

## Naming Conventions

- ViewModels: `...ViewModel` with `@Observable`
- Services: `...Service` or `...Manager`
- Client protocols: `...Client` (e.g., `DaysClient`, `StatusClient`)
- SwiftData models: PascalCase without suffix
- API DTOs: `...Request`, `...Response`
- Domain terms: `DayActivity`, `UserProgress`, `SyncJournalEntry`
- Russian-localized strings: in `.strings`/`.stringsdict` files, NOT hardcoded

## Architecture and Design

- MVVM with `@Observable` view models/services.
- Modular structure: `Screens`, `Services`, `Models`, `Extensions`, `PreviewContent`.
- Dependency injection via `Environment` and protocol-based clients.
- Client protocols live under `Services/Protocols/`.
- `SWClient` is the concrete API client implementing multiple client protocols.

## Offline-First Rules (Mandatory)

- Offline-first is mandatory for all app behavior.
- Persist locally first (SwiftData), then sync asynchronously.
- Sync must be optional and non-blocking for user flows.
- Exception: authentication requires network.
- SwiftData sync entities carry flags: `isSynced`, `shouldDelete`, `lastModified`/`modifyDate`.

## Single-User Data Model

- One active user at a time.
- On login: user data stored locally.
- On logout: all user data must be cleared.

## Imports, Types, and Concurrency

- Prefer protocol types for dependencies.
- Mark UI/stateful domain objects with `@MainActor`.
- Adopt `Sendable` where cross-concurrency usage is expected.
- No force unwrapping (`!`) in production or tests. Use `try #require(optional)` in tests.

## Error Handling and Logging

- Use `OSLog` (`Logger`) for operational logs and diagnostics.
- No TODO comments as substitute for logging/tracking.
- Surface recoverable errors gracefully (alerts, state updates).
- Fail fast only for unrecoverable startup conditions.
- Error messages must be actionable with context (entity/day/id).

## Code Guidelines

- Use modern SwiftUI + SwiftData + Observation stack.
- Never use UIKit/Core Data unless SwiftUI cannot implement required functionality.
- Never leave unused code after refactoring.
- Never add code without explicit request.
- Add sync flags (`isSynced`, `shouldDelete`, `lastModified`) to all models.
- Always implement local SwiftData persistence first; sync is async and non-blocking.
- Test offline functionality for every feature.

## Agent Workflow Checklist

1. Read relevant docs in `docs/` before major edits.
2. Make smallest safe change set; avoid unrelated refactors.
3. Run `make format` then targeted tests after any code changes.
4. For broad changes, run full test plans.
5. If touching UI test flows, validate launch argument `UITest` assumptions.

## Practical File Pointers

- SwiftFormat config: `.swiftformat`
- Build/test automation: `Makefile`
- Contributor guide: `.github/CONTRIBUTING.md`
- Project rules: `.agents/rules/*.mdc`
- App entry: `SwiftUI-SotkaApp/SwiftUI_SotkaAppApp.swift`
- iOS test plan: `SwiftUI-SotkaAppTests/SwiftUI-SotkaAppTests.xctestplan`
- UI test plan: `SwiftUI-SotkaAppUITests/SwiftUI-SotkaAppUITests.xctestplan`
- Watch test plan: `SotkaWatch Watch AppTests/SotkaWatch-UnitTests.xctestplan`
