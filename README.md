# StairCardio

A fitness habit-building app for iOS that uses short stair-climbing sessions distributed throughout the workday to increase daily caloric burn, improve conditioning, and facilitate fat loss.

## What is StairCardio?

StairCardio helps you build a sustainable fitness habit by breaking down your daily exercise into manageable micro-sessions. Instead of long, intimidating workouts, you complete short "stair circuits" throughout your workday—perfect for busy office workers who want to stay active without committing hours at the gym.

### Core Mechanism
- Complete daily "stair circuits" throughout your workday
- Track your progress against a personalized daily target
- Build consistency through distributed effort rather than intensity

## Current Status

**Phase v0.1 — Local MVP ✅ COMPLETE**

The app is currently at v0.1, which provides a complete local MVP with the following features:

### Implemented Features
- ✅ Daily target tracking with per-day circuit count
- ✅ +1 Quick Circuit logging button
- ✅ Auto-create daily log with unique dayKey (yyyy-MM-dd format)
- ✅ Daily auto-reset (automatically creates new DayLog for each new day)
- ✅ SwiftData persistence with CloudKit sync
- ✅ Settings sheet for editing daily target with validation (> 0)
- ✅ Progress display with completed/target fraction, linear progress bar, and dynamic feedback
- ✅ Watch app stub infrastructure (v0.3 in progress)
- ✅ HealthKit integration stubs (v0.4 ready)

### Planned Features (Future Phases)
- 📋 Local notifications during work hours (v0.2)
- ⌚ Watch companion app with quick logging (v0.3)
- 🏃 Workout mode with HealthKit metrics (v0.4)
- 📊 Analytics and weekly trends (v1.0)

## Requirements

- **Xcode 15.0+**
- **iOS 17.0+**
- **watchOS 10.0+** (for Watch companion)
- **Swift 5.9+**

## Installation

### Clone the Repository

```bash
git clone https://github.com/asvirts/staircardio.git
cd staircardio
```

### Open in Xcode

```bash
open staircardio.xcodeproj
```

### Build and Run

1. Select a target device or simulator (e.g., iPhone 15)
2. Press `⌘R` or click the Run button
3. The app will build and launch on the selected device

## Project Structure

```
staircardio/
├── staircardio/                 # Main iOS app
│   ├── Models/
│   │   ├── DayLog.swift         # Daily tracking model
│   │   └── WorkoutLog.swift     # Workout session model
│   ├── Views/
│   │   ├── ContentView.swift   # Main today screen
│   │   ├── WorkoutSessionView.swift
│   │   └── WorkoutHistoryView.swift
│   ├── Managers/
│   │   ├── HealthKitManager.swift
│   │   ├── WatchSyncManager.swift
│   │   ├── NotificationScheduler.swift
│   │   └── CloudKitConfig.swift
│   └── staircardioApp.swift     # App entry point
├── staircardioWatch/             # Watch companion app
├── staircardioTests/            # Unit tests
├── staircardioUITests/          # UI tests
├── prd.md                       # Product Requirements Document
├── PHASES_CHECKLIST.md          # Phase-by-phase roadmap
└── PHASE_V0.1_COMPLETE.md       # v0.1 completion summary
```

## Usage

### Daily Habit Loop

1. Open the app to see today's progress
2. Complete a stair circuit session
3. Tap the **+1 Quick Circuit** button to log it
4. Watch your progress bar update
5. Repeat until you reach your daily target
6. Edit your target anytime via the Settings (gear icon)

### Key Features

**Today Screen**
- Large completion fraction display (e.g., "6/10 circuits")
- Visual progress bar with accent color
- Dynamic feedback (remaining circuits or celebration emoji)
- One-tap circuit logging
- Quick access to settings and history

**Settings**
- Edit your daily target
- Validate changes before saving
- Persistence across app launches

## Development

### Build

```bash
xcodebuild -project staircardio.xcodeproj \
  -scheme staircardio \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### Run Tests

```bash
xcodebuild -project staircardio.xcodeproj \
  -scheme staircardio \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

### Run a Single Test

```bash
xcodebuild -project staircardio.xcodeproj \
  -scheme staircardio \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:staircardioTests/staircardioTests/testExample \
  test
```

## Documentation

- **[Product Requirements Document](prd.md)** — Complete product vision, user workflows, and feature requirements
- **[Phase Checklist](PHASES_CHECKLIST.md)** — Detailed checklist for all development phases (v0.1 through v1.0)
- **[v0.1 Completion Summary](PHASE_V0.1_COMPLETE.md)** — Summary of completed MVP features
- **[AGENTS.md](AGENTS.md)** — Development guidelines and agent instructions

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData with CloudKit
- **Health Integration:** HealthKit
- **Watch Connectivity:** WatchConnectivity framework
- **Notifications:** UserNotifications framework

## Contributing

This is currently a personal project, but pull requests and issues are welcome!

## License

[Add your license here - e.g., MIT License]

## Contact

Andrew - [GitHub](https://github.com/asvirts)

---

**Made with ❤️ for busy humans who want to move more**
