# StairCardio — All Phases Checklist

---

## Phase v0.1 — Local MVP
**Goal:** Make the app usable for 1 user for 30 days.

### Core Features
- [x] Daily target tracking (DayLog model with per-day circuit target)
- [x] +1 Quick Circuit logging (button to increment completed count)
- [x] Auto-create daily log (uses dayKey format yyyy-MM-dd)
- [x] Daily auto-reset (creates new DayLog for each day automatically)
- [x] Persistence (SwiftData with modelContainer)
- [x] Settings: daily target (editable via Settings sheet with validation > 0)
- [x] Progress display (completed/target fraction + linear bar + remaining text)

### Models
- [x] DayLog SwiftData model with unique dayKey
- [x] Properties: dayKey, completed, target
- [x] Auto-create logic in ContentView

### UI Components
- [x] Today Screen with title, big fraction, progress bar, remaining text
- [x] +1 Quick Circuit button
- [x] Start Stair Session button (stub)
- [x] Reset Today button (debug)
- [x] Gear icon for Settings
- [x] Settings sheet with target text field, number pad, save/cancel, validation

### App Structure
- [x] SwiftData modelContainer setup in App entry
- [x] NavigationStack wrapper
- [x] ModelContext environment
- [x] Query for today's log
- [x] Preview provider

### Cleanup
- [x] Remove unused Item.swift (Xcode template)
- [x] Add unit tests for model logic
- [ ] Add app icon (optional)
- [ ] Add LaunchScreen (optional)

**Phase v0.1 Status:** ✅ COMPLETE - MVP ready for testing

**Phase v0.2 Status:** ✅ COMPLETE - weekday reminders implemented

---

## Phase v0.2 — Reminders
**Goal:** Add local notifications to prompt users during work hours (weekdays only).

### Core Features
- [x] Request notification permissions when enabling reminders
- [x] Configurable workday hours (default 9am–5pm)
- [x] Configurable notification interval (default 90 minutes)
- [x] Schedule local notifications during workday window
- [x] Suppress notifications once target is reached for the day
- [x] Resume notifications automatically on new day

### Settings UI
- [x] Add notification settings to Settings sheet
- [x] Toggle: Enable/Disable notifications
- [x] Work hours start time picker
- [x] Work hours end time picker
- [x] Notification interval picker
- [x] Validation: start < end time

### Notification Logic
- [x] Schedule notifications on app launch/settings change
- [x] Cancel/reschedule when settings change
- [x] Check target completion before showing notifications
- [x] Reset notification schedule for new day

### User Experience
- [x] Onboarding prompt for notification permissions (on toggle)
- [x] Notification content: "Time for a stair circuit"
- [x] Deep link to app on notification tap

---

## Phase v0.3 — Watch Companion
**Goal:** Add watchOS app for frictionless micro-logging.

### Watch App Structure
- [ ] Create watchOS target in Xcode project
- [ ] Watch App entry point
- [ ] Basic UI setup (WatchKit)

### Watch Connectivity
- [ ] Add WatchConnectivity framework to iOS app
- [ ] Add WCSession delegate to iOS app
- [ ] Sync fields: completed, target, dayKey
- [ ] Bi-directional sync (Watch → Phone, Phone → Watch)

### Watch UI
- [ ] Today's summary (completed / target)
- [ ] Progress indicator (ring or bar)
- [ ] +1 Quick Circuit button
- [ ] Refresh button for manual sync

### Watch UX
- [ ] Haptic feedback on +1 tap
- [ ] Sync status indicator (synced/syncing/error)
- [ ] Auto-sync on circuit completion

### Phone App Changes
- [ ] WatchConnectivity session setup
- [ ] Data sync observers
- [ ] Update UI when data changes from Watch

---

## Phase v0.4 — Workout Mode
**Goal:** Add HealthKit workout capture for accurate metrics.

### HealthKit Integration
- [x] Add HealthKit framework to iOS app
- [ ] Add HealthKit usage descriptions to Info.plist
- [ ] Request HealthKit permissions on first launch
- [x] Permission types: Active Energy, Heart Rate, Steps, Floors Climbed

### Watch Workout Mode
- [ ] "Start Stair Session" button on Watch
- [x] HKWorkoutSession setup for stair climbing
- [x] Live metrics display during workout:
  - [x] Duration timer
  - [x] Floors climbed
  - [x] Current heart rate
  - [x] Calories burned
- [x] End workout button
- [ ] Workout summary screen

### Auto-Conversion Logic
- [x] Convert floors climbed to circuit count (configurable ratio)
- [ ] Option to adjust circuit count after workout

### Phone App Integration
- [x] HealthKit data query for past workouts
- [x] Display workout history
- [ ] Manual circuit adjustment from workout data

### Persistence
- [x] Store workout references in DayLog
- [x] Fetch workout details from HealthKit

---

## Phase v1.0 — Health + Insights
**Goal:** Add analytics, trends, advanced health metrics, and iCloud sync.

### Analytics & Trends
- [ ] Weekly summary screen
- [ ] Monthly summary screen
- [ ] Charts:
  - [ ] Circuits per day (line chart)
  - [ ] Completion rate (bar chart)
  - [ ] Streak calendar
- [ ] Statistics:
  - [ ] Total circuits completed
  - [ ] Longest streak
  - [ ] Average circuits per workday
  - [ ] Goal achievement rate

### Health Metrics
- [ ] Fetch VO₂ max from HealthKit
- [ ] Fetch resting heart rate from HealthKit
- [ ] Correlate circuit frequency with health improvements
- [ ] Display trends over time

### Behavioral Features
- [ ] Plateau detection (no progress for X days)
- [ ] Behavioral nudges based on patterns
- [ ] Suggested target adjustments
- [ ] Weekly achievement badges

### Advanced Settings
- [ ] Target auto-adjustment (smart or manual)
- [ ] Workday customization (different days/hours)
- [ ] Circuit definition (floors per circuit)
- [ ] Data export option

### iCloud Sync (New)
- [x] Enable CloudKit sync for SwiftData
- [x] Show iCloud sync status in Settings
- [ ] Validate CloudKit setup on real devices

### Backend (Optional)
- [ ] Push notification support
- [ ] Server-side analytics
- [ ] Account system (if needed)

### Premium Features (Optional)
- [ ] Subscription tier system
- [ ] Advanced insights
- [ ] Personalized coaching
- [ ] Integration with other wearables (Oura, Whoop)

---

## Cross-Phase Infrastructure

### Code Quality
- [ ] Unit tests for model logic
- [ ] UI tests for critical flows
- [ ] Error handling and logging
- [ ] Code documentation

### Accessibility
- [ ] VoiceOver support for all screens
- [ ] Dynamic Type support
- [ ] Color contrast compliance
- [ ] Accessibility labels for all interactive elements

### Localization
- [ ] String localization setup
- [ ] English base language
- [ ] Consider major markets for translation

### App Store
- [ ] App icon (all sizes)
- [ ] Screenshots
- [ ] App Store description
- [ ] Privacy policy
- [ ] Terms of use
- [ ] Age rating

---

## Future Opportunities (Post-v1.0)
- [ ] Office building gamification (team challenges)
- [ ] Corporate health partnerships
- [ ] Integration with Oura, Whoop
- [ ] Personalized pacing (VO₂ max correlated)
- [ ] Subscription for insights
- [ ] Desktop reminders (MenuBar app)
- [ ] Web dashboard
- [ ] Android support

---

## Tracking Notes
- Last updated: 2026-01-17
- Current phase: v0.1 (Local MVP)
- Next phase: v0.2 (Reminders)
