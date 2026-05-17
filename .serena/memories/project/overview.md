# SwiftUI-SotkaApp Overview

## Project Purpose
iOS fitness app (SotkaApp) for tracking 100-day workout programs. Supports iOS 17+ and watchOS.

## Tech Stack
- SwiftUI, SwiftData, Observation
- Xcode project build system
- Local Swift packages in `SwiftUI-SotkaApp/Libraries/`
- Swift Testing for unit tests
- XCTest for UI tests

## Architecture
- MVVM with `@Observable` view models/services
- Client protocols in `Services/Protocols/`
- `SWClient` implements all client protocols
- Offline-first: persist locally first (SwiftData), sync async
- Single-user data model

## Key Files
- Entry: `SwiftUI-SotkaApp/SwiftUI_SotkaAppApp.swift`
- API Client: `SwiftUI-SotkaApp/Services/SWClient.swift`
- Constants: `SwiftUI-SotkaApp/Models/SWSharedModels/Constants.swift`
- Tests: `SwiftUI-SotkaAppTests/`
- UI Tests: `SwiftUI-SotkaAppUITests/`

## Build/Test Commands
- `make format` - Format with swiftformat
- `make build` - Build iOS for simulator
- `make test` - Run iOS unit tests
- `xcodebuild-mcp build_sim` / `test_sim` - Preferred MCP path

## Style
- Max line width: 140
- Wrap: before-first
- No semicolons, no trailing commas
- Russian strings in .strings/.xcstrings files
