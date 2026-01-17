# AGENTS

This repo is an Xcode SwiftUI app named staircardio.
Use these notes when editing or adding code.

## Project layout
- `staircardio/` app sources (SwiftUI + model)
- `staircardioTests/` unit tests (XCTest)
- `staircardioUITests/` UI tests
- `staircardio.xcodeproj` Xcode project

## Build, run, lint, test
All commands require Xcode and macOS with iOS simulators installed.

### Build
- `xcodebuild -project staircardio.xcodeproj -scheme staircardio -destination 'platform=iOS Simulator,name=iPhone 15' build`

### Run (from Xcode)
- Open `staircardio.xcodeproj` in Xcode and press `⌘R`.

### Test
- `xcodebuild -project staircardio.xcodeproj -scheme staircardio -destination 'platform=iOS Simulator,name=iPhone 15' test`

### Run a single test
- Single test method:
  `xcodebuild -project staircardio.xcodeproj -scheme staircardio -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:staircardioTests/staircardioTests/testExample test`
- Single test class:
  `xcodebuild -project staircardio.xcodeproj -scheme staircardio -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:staircardioTests/staircardioTests test`
- Single UI test class:
  `xcodebuild -project staircardio.xcodeproj -scheme staircardio -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:staircardioUITests/staircardioUITests test`

### Lint/format
- No lint or formatter is configured in this repo.
- If you add one, prefer SwiftLint + SwiftFormat and document it here.

## Code style guidelines

### General Swift style
- Use 4-space indentation, no tabs.
- Keep lines readable; wrap SwiftUI modifier chains as seen in `ContentView.swift`.
- Use K&R braces: `if condition {`.
- Prefer `guard` for early exits.
- Avoid force unwraps (`!`) unless proven safe.
- Favor `let` and immutability; use `var` when state changes.
- Add `final` to classes unless subclassing is intended.
- Keep helper methods `private` or `fileprivate` when not exported.

### Formatting details
- Use one modifier per line for SwiftUI chains.
- Prefer trailing-closure syntax for SwiftUI views.
- Split long parameter lists across multiple lines.
- Keep blank lines between logical layout sections.
- Align nested stacks with explicit `spacing` when possible.
- Keep computed properties grouped under the `body`.

### Imports
- Import only what you use.
- Order imports alphabetically within system frameworks.
- Keep a blank line between imports and code.

### Naming
- Types use UpperCamelCase.
- Methods/properties use lowerCamelCase.
- Boolean names read as predicates (`isActive`, `hasData`).
- Prefer clear, descriptive names over abbreviations.

### SwiftUI patterns
- Use `@StateObject` for owned observable models.
- Use `@EnvironmentObject` for injected shared models.
- Prefer computed properties for derived values (see `progress` in `ContentView.swift`).
- Use `ViewBuilder`-style layout with explicit spacing and padding.
- Keep view structs small; extract subviews when they grow.
- Avoid side effects in `body` other than SwiftUI declarative code.

### Data and persistence
- Centralize persistence logic in the model (`AppModel` uses `UserDefaults`).
- Persist updates immediately after changing stored values.
- Keep keys as `private let` constants.

### Error handling
- Use `do/try/catch` for throwing APIs.
- Convert recoverable errors into user-friendly UI state.
- For non-fatal issues, log with `print` or `os_log`.

### Concurrency
- Prefer `@MainActor` for UI-bound state.
- Keep async work off the main thread when it can block UI.
- Use `Task` for one-off async actions from views.

### Testing
- Unit tests live in `staircardioTests` and use XCTest.
- Use `setUpWithError` / `tearDownWithError` only when needed.
- Keep tests deterministic and avoid relying on device state.
- Name tests `test_<behavior>` or `testBehavior` consistently.

### File headers
- Existing files include the Xcode header comment; keep it.
- Do not add new headers unless Xcode generated them.

## Agent tips
- Prefer editing existing files over creating new ones.
- Keep changes focused and minimal.
- Update this file when adding tooling or new conventions.

## Cursor/Copilot rules
- None found in `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`.

## Common pitfalls
- `xcodebuild` requires full Xcode, not just CLI tools.
- Ensure the simulator name matches your local install.
- Scheme names might differ; use Xcode > Manage Schemes to confirm.

## Example simulator destinations
- `platform=iOS Simulator,name=iPhone 15`
- `platform=iOS Simulator,name=iPhone 15 Pro`
- `platform=iOS Simulator,name=iPhone SE (3rd generation)`

## Optional quality checks (manual)
- Build in Xcode before shipping changes.
- Run unit tests (`⌘U`) when touching model logic.
- Run UI tests sparingly; they are slower.

## When adding new code
- Keep UI strings user-facing and localizable-ready.
- Avoid global singletons unless required.
- Add preview providers for new views when helpful.
- Use `@Published` for observable state changes.

## Dependency management
- No external package manager detected.
- If adding SPM dependencies, update Xcode project and note here.

## SwiftData usage
- `Item` uses `@Model`; keep models lightweight.
- Store only properties that need persistence.

## UI behavior
- Keep primary actions prominent (see primary button styling).
- Use `Color.accentColor` for theme consistency.

## Accessibility
- Prefer system fonts for Dynamic Type.
- Keep button text concise and readable.

## Version control
- Avoid committing generated build artifacts.
- Keep secrets out of the repo.

## Contact points
- There is no extra tooling or script runner in this repo.
