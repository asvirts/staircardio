# StairCardio — Product Requirements Document (PRD)

**Product Name (working):** StairCardio  
**Owner:** Andrew  
**Version:** v0.1 MVP  
**Last updated:** YYYY-MM-DD  

---

## 1. Product Overview

**What it is:**  
StairCardio is a fitness habit-building app that uses short stair-climbing sessions distributed throughout the workday to increase daily caloric burn, improve conditioning, and facilitate fat loss — without requiring a gym or long workouts.

**Primary mechanism of change:**  
Completing daily "stair circuits" throughout the workday.

**Core metric:**  
`circuits_completed_today`

**Why this matters:**  
Short bursts of stair cardio can produce:
- Measurable daily caloric output
- Cardiovascular benefit
- Improved energy
- Reduced friction compared to full workouts

---

## 2. Target Users

**Primary user archetype:**
- Office/desk workers
- Has access to stairs (home or office)
- Wants to lose weight, improve energy, or build fitness habits
- Time-poor & work-focused

**Secondary archetypes:**
- Remote workers
- Students
- People attempting NEAT (non-exercise activity thermogenesis) strategies

---

## 3. Core Problem

Modern users struggle to:
- Fit workouts into daily schedules
- Sustain habit formation
- Maintain movement during work hours

Meanwhile:
- Sedentary workdays contribute to negative health outcomes
- Short, distributed activity is under-utilized

---

## 4. Solution Summary

StairCardio provides:
1. A **daily target** habit loop (circuits)
2. Simple **logging and tracking**
3. **Reminders** during work hours to trigger action
4. Optional **Watch integration** for frictionless micro-logging
5. **Health metrics** (later phases) for accountability

---

## 5. Product Principles

- **Zero friction:** Starting a session should be 1–2 taps
- **Distributed effort beats intensity**
- **Non-disruptive:** Fits into work life
- **Data-backed:** Uses real metrics when available (HR, calories, VO₂ max)
- **Positive reinforcement, low shame**

---

## 6. Core User Workflows (MVP)

### 6.1. Daily Habit Loop
User wakes → works → at intervals performs stair circuits until target completed.

**Loop:**
1. User receives reminder
2. User completes circuits
3. User logs them (manual or via Watch)
4. Target bar progresses
5. Reward feedback when completed

---

## 7. Feature Requirements (MVP)

### 7.1 Core Features

| Feature | Status | Notes |
|---|---|---|
| Daily target tracking | v0.1 | User has a per-day circuit target |
| +1 Quick Circuit logging | v0.1 | Button to increment |
| Auto-create daily log | v0.1 | Uses `dayKey` |
| Daily auto-reset | v0.1 | Reset based on date change |
| Persistence | v0.1 | SwiftData |
| Settings: daily target | v0.1 | Editable via Settings sheet |
| Progress display | v0.1 | `completed / target` + bar |
| Local notifications | v0.2 | Workday reminders until goal hit |
| Watch quick logging | v0.3 | `+1` action on Watch |
| Watch stair session | v0.4 | HealthKit workout capture |
| HealthKit integration | v0.4 | Calories, resting HR, VO₂ max |
| Push notifications | v1.0 | Server-driven (optional) |
| Analytics / Trends | v1.0 | Weekly/monthly summary |

---

## 8. Phase Breakdown

### Phase v0.1 — **Local MVP**
Scope:
- Daily logs persisted with SwiftData
- Manual `+1` logging
- Daily target
- Reset + Settings screen
- Local UI only

Goal:
> Make the app usable for 1 user for 30 days.

### Phase v0.2 — **Reminders**
Adds:
- Local notifications during work hours
- Configurable hours
- Stop reminders once target hit

### Phase v0.3 — **Watch Companion**
Adds:
- Watch app
- `+1 Quick Circuit`
- Today's summary
- Haptics
- Watch <-> Phone sync

### Phase v0.4 — **Workout Mode**
Adds:
- "Start Stair Session" on Watch
- Captures:
  - Duration
  - Floors climbed
  - HR zones
  - Calories
- Auto-converts floors to circuits
- Ends with confirmation

### Phase v1.0 — **Health + Insights**
Adds:
- Weekly trends
- VO₂ max + resting HR tracking
- Plateau detection
- Behavioral nudges
- Push notifications (optional backend)
- Possibly subscription or premium layer

---

## 9. Technical Requirements

### 9.1 Platform Choices
- **iOS (first)**
- **watchOS (phase 0.3+)**
- Later: Web dashboard or Android optional

### 9.2 Storage Model (SwiftData)

```swift
@Model
class DayLog {
    var dayKey: String          // yyyy-MM-dd
    var completed: Int
    var target: Int
}
```

### 9.3 Model Behaviors
- Unique dayKey ensures 1 per day
- Auto-create DayLog for new days
- Editable target
- Aggregatable for trends later

### 9.4 Notification Rules

(Not in v0.1, in v0.2)
- Workday window (default 9am–5pm)
- Interval (default 90 mins)
- Suppress if completed >= target
- Resume next day

### 9.5 Watch Connectivity (v0.3)
- Use WatchConnectivity
- Sync fields:
  - completed
  - target
  - dayKey

---

## 10. UX Requirements

### 10.1 Today Screen (v0.1)

Components:
- Title
- Big completion fraction
- Linear progress bar
- Remaining text
- +1 Quick Circuit button
- Secondary "Start Stair Session" (stub)
- Reset (debug)
- Gear icon (Settings)

### 10.2 Settings Screen (v0.1)

Allows editing target with:
- Validation: must be > 0
- Save / Cancel

### 10.3 Empty States
- Not applicable, auto-creates daily entry

---

## 11. Success Metrics

Short-term activation metrics:
- Day 1 install → Day 2 retention
- Manual circuits logged

Medium-term habit metrics:
- Weekly completion rate
- Streaks
- Days with completed >= target

Phase v0.1 success criteria:

User can use the app every workday for 30 days without quitting due to friction.

---

## 12. Non-Goals (for clarity)

The following are explicitly not in MVP:
- Diet tracking
- Social features
- Leaderboards
- Coaching / AI feedback
- Gamification beyond simple progress
- Cloud sync
- Multi-user features
- Paid tiers or billing
- Android support

These may appear in future phases.

---

## 13. Risks & Assumptions

Risks
- User may ignore reminders
- Access to stairs may vary
- HealthKit integration complexity
- Watch app complexity

Assumptions
- Many users have an Apple Watch (optional but assumed for advanced features)
- HealthKit permissions are granted
- Workday movement is acceptable to user

---

## 14. Future Opportunities (Post-v1.0)
- Office building gamification (e.g., team challenges)
- Corporate health partnerships
- Integration with Oura, Whoop
- Personalized pacing (VO₂ max correlated)
- Smart adjustment of targets
- Subscription for insights
- Desktop reminders (MenuBar app)
- Web dashboard

---

## 15. Open Questions
- Should Watch app require iPhone pairing or support standalone logging?
- Should notifications vibrate watch or only phone?
- When calculating calories:
  - Use HealthKit or estimate from circuits?

---

## 16. Appendix

Source behavior protocol: "Workday Stair Cardio Plan" (PDF)
Includes:
- Phase structure (Phase 1–3)
- Expected targets
- Health metrics
- Results timelines

---

If you want I can also generate:

✅ a **Roadmap**  
✅ a **Figma wireframe set**  
✅ a **GitHub README**  
✅ an **App Store spec**  
✅ a **user onboarding flow**  
or convert into a `docs/` folder for your repo.

Just say the word.
