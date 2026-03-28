# Checkpoint iOS - Development Guide

## Overview

**Checkpoint** (formerly Kairos) is an iOS app for mindful breathing exercises and habit tracking. It delivers brief, contextual reminders throughout the day without requiring user interaction—users simply receive notifications encouraging them to breathe, practice gratitude, or reflect on the present moment.

- **Bundle ID**: `com.kevinfish.Checkpoint`
- **Deployment Target**: iOS 26.0 (min), iOS 26.2 (SDK)
- **Xcode**: 26.3 (LastUpgradeCheck 2630)
- **Swift Version**: 5.0 with upcoming feature flags enabled
- **Architecture**: SwiftUI (single target, no frameworks)
- **Code Size**: ~2,770 lines of Swift across 20 files
- **Last Major Changes**: Rebranding from Kairos to Checkpoint, orb breathing sync fix

---

## Project Structure

```
checkpoint-ios/
├── Checkpoint.xcodeproj/           # Xcode project (Xcode 26.3)
│   ├── project.pbxproj             # Build config
│   └── project.xcworkspace/        # Workspace (minimal setup)
├── Checkpoint/                      # Main app target (all source)
│   ├── KairosApp.swift              # @main app entry (struct CheckpointApp)
│   ├── ContentView.swift            # Root view (onboarding routing)
│   ├── MainTabView.swift            # Tab bar (Breathe + Habits)
│   ├── Models/                      # SwiftData models
│   │   ├── HabitGoal.swift          # Purchase goal (many habits)
│   │   ├── Habit.swift              # Individual habit/reward
│   │   └── HabitCompletion.swift    # Completion record + amount
│   ├── Assets.xcassets/             # App icon, colors
│   ├── Info.plist                   # Background modes + task identifiers
│   │
│   ├── # Breathing (Breathe tab)
│   ├── BreathingOrbView.swift       # Animated orb (pattern-driven)
│   ├── BreathingPatternSheet.swift  # Pattern selector + custom editor
│   ├── OnboardingView.swift         # First launch (permission request)
│   │
│   ├── # Habits (Habits tab)
│   ├── HabitsView.swift             # Tab root (goal → habit list)
│   ├── CreateGoalView.swift         # Goal creation form
│   ├── AddHabitView.swift           # Add habit to goal
│   ├── EditHabitView.swift          # Edit habit sheet
│   ├── GoalCompletedView.swift      # Celebration overlay
│   │
│   ├── # Notifications & Background
│   ├── NotificationScheduler.swift  # Core scheduling logic (6-day horizon)
│   ├── BackgroundRefresh.swift      # BGAppRefreshTask handler
│   ├── MessagePool.swift            # Notification message pools (4 categories)
│   │
│   ├── # Settings & State
│   ├── Preferences.swift            # UserDefaults-backed prefs (validation)
│   ├── SettingsDrawer.swift         # Settings sheet
│   │
│   ├── # Visual Effects
│   ├── ParticleEmitterView.swift    # Particle animations
│   └── [Other UI views]
│
├── .gitignore                       # Ignores CLAUDE.md, .impeccable.md
└── AppIcon.{html,png}              # App icon assets (external)
```

### Key Observations

- **No external dependencies** — purely SwiftUI + SwiftData
- **No package manager** — no Podfile, Cartfile, or Package.swift
- **Single target** — all code in the Checkpoint folder
- **Modern Xcode format** — uses file system synchronization (`PBXFileSystemSynchronizedRootGroup`)
- **Workspace but minimal** — workspace exists for compatibility, but project is self-contained

---

## Architecture & Patterns

### SwiftUI + SwiftData

The app is **100% SwiftUI** with **SwiftData** for persistence:

```swift
// Models use @Model macro
@Model final class HabitGoal {
    var id: UUID = UUID()
    var name: String = ""
    var targetCents: Int = 0  // Money goal in cents
    var habits: [Habit] = []
    @Relationship(deleteRule: .cascade, inverse: \Habit.goal)
    // ... computed properties (progress, formatting)
}
```

- **No ViewModel layer** — state lives in Views (@State, @Binding, @Environment)
- **No MVVM** — straightforward View → Model access via @Environment(\.modelContext)
- **Data persistence**: SwiftData with automatic migration, container setup in app init

### Key Entry Points

1. **KairosApp.swift** → `CheckpointApp` (@main)
   - Registers background refresh handler synchronously on init
   - Sets up SwiftData model container for HabitGoal
   - Schedules the first background refresh
   - Note: File still named KairosApp.swift but struct is CheckpointApp

2. **ContentView.swift** (root view)
   - Routes to OnboardingView (first launch) or MainTabView (returning)
   - Reschedules notifications when app comes to foreground (scenePhase)
   - Watches Preferences for changes, saves + reschedules

3. **MainTabView.swift** (tab navigation)
   - Two tabs: "Breathe" (BreathingOrbView) and "Habits" (HabitsView)
   - Checks notification auth status on appear and foreground
   - Shows "Notifications off" banner if denied
   - Gear button opens SettingsDrawer with fade-in animation

### Data Flow

```
Preferences (UserDefaults)
  ↓
NotificationScheduler (6-day look-ahead, up to 60 notifications)
  ↓
UNUserNotificationCenter (system APIs)
  ↓
Background refresh every ~12 hours (BGAppRefreshTask)
  ↓
Re-schedule notifications (replace old ones)

HabitGoal ↔ SwiftData
  ↓
Habit (many per goal)
  ↓
HabitCompletion (many per habit, tracks amount_cents)
```

### Color Palette

Colors are defined inline or as local Color extensions:

```swift
// Background
Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)  // dark navy

// Accent (breathing orb glow, button text)
Color(red: 0x6c/255, green: 0xb0/255, blue: 0xe0/255)  // sky blue

// Text opacity hierarchy
.white.opacity(0.88)   // primary text
.white.opacity(0.5)    // secondary
.white.opacity(0.38)   // muted
.white.opacity(0.07)   // divider
```

---

## Core Features

### 1. Breathing Orb (Breathe Tab)

**File**: `BreathingOrbView.swift`

- Animated circle that expands on inhale, contracts on exhale
- Applies scaling (1.0 → 1.2) and glow intensity changes
- Pattern-driven: respects breathing pattern (Box, 4-7-8, Coherent, Energizing, Custom)
- CSS port from the Presence web app
- Cycle phases: inhale → hold-in → exhale → hold-out (with 0-duration skips)
- Stops/starts based on scene phase (active/background) and pattern changes

### 2. Habit Goal Tracking

**Files**: `HabitsView.swift`, `CreateGoalView.swift`, `AddHabitView.swift`, `EditHabitView.swift`

- Goals are financial targets (in cents, displayed as USD)
- Each goal can have multiple habits
- Habits have a "reward" amount (in cents) that accumulates toward the goal
- Progress is `min(1.0, totalEarned / targetAmount)`
- Completion is binary: goal is marked complete when progress >= 100%
- List supports drag-to-reorder and swipe-to-delete

### 3. Notifications & Scheduling

**Files**: `NotificationScheduler.swift`, `BackgroundRefresh.swift`

**Scheduling Algorithm**:
- 6-day look-ahead (up to 60 notifications max per run, iOS limit is 64)
- Random time slots within [start_hour, end_hour] with minimum 15-min gaps
- Messages drawn from three category pools (Gratitude, Body Awareness, Present Moment)
- Pulls proportionally from enabled categories; falls back to all if none enabled
- Optional meditation reminders in separate time window

**Background Refresh**:
- `BGAppRefreshTask` registered on app launch (must be synchronous)
- Scheduled for every 12 hours (minimum delay, iOS decides actual timing)
- Handler reschedules the next refresh before doing work (ensures chain continues)
- If interrupted by iOS expiration, work task cancels gracefully

### 4. Preferences & Validation

**File**: `Preferences.swift`

- Persisted via UserDefaults (JSON-encoded)
- Codable struct with validation logic
- Fields: remindersPerDay (1–50), schedule hours, category toggles, haptic feedback, meditation settings
- `isValid` property checks all constraints
- `validated()` method falls back to safe defaults for invalid values

### 5. Onboarding

**File**: `OnboardingView.swift`

- Shown once on first launch (gated by `@AppStorage("hasCompletedOnboarding")`)
- Requests notification permission via UNUserNotificationCenter
- Runs breathing orb animation during permission request
- On completion: sets onboarding flag, schedules initial notifications, shows main app

---

## Notification System

### Message Categories

All messages defined in `MessagePool.swift`:

1. **Gratitude** (16 messages)
   - "What are you grateful for right now?"
   - "Name something beautiful you noticed today."
   - etc.

2. **Body Awareness** (14 messages)
   - "Notice where your body is holding tension."
   - "Feel the weight of your body now."
   - etc.

3. **Present Moment** (15 messages)
   - "What three things can you see now?"
   - "Right now, this moment is enough."
   - etc.

4. **Meditation** (15 messages)
   - "Close your eyes. Take five slow breaths."
   - "Sit still for one minute. Just breathe."
   - etc.

### Notification Identifiers

- **Regular**: `checkpoint.{dayOffset}.{index}.{UUID}`
- **Meditation**: `checkpoint.med.{dayOffset}.{index}.{UUID}`

Content includes body text, sound (default), and optional haptic interrupt level if enabled.

---

## Build Configuration

### Target Settings

- **Product Name**: Kairos (internal, differs from bundle ID naming)
- **Bundle ID**: com.kevinfish.Checkpoint
- **Team**: (developer's team)
- **iPhone Orientation**: Portrait only (phones); Portrait + Landscape (iPad)
- **UI Launch Screen**: Generated automatically
- **String Catalogs**: Enabled (modern localization)

### Swift Compiler Flags

```
SWIFT_APPROACHABLE_CONCURRENCY = YES          # Concise syntax for structured concurrency
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor     # Default to @MainActor for UI types
SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES  # Future-proof
```

### Deployment

- **iOS 26.0** minimum deployment target
- **iOS 26.2** SDK / build settings for non-release configs
- **Xcode 26.3** (LastUpgradeCheck 2630)
- No code signing overrides visible in pbxproj (uses team defaults)

---

## Info.plist & Capabilities

**Background Modes** (Info.plist):
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>  <!-- Background app refresh -->
</array>

<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.kevinfish.Checkpoint.refresh</string>
</array>
```

---

## Code Style & Conventions

### File Headers
All Swift files include standard header:
```swift
//
//  FileName.swift
//  Checkpoint
//
// [Optional docstring about the file's role]

import SwiftUI
```

### Color Management
Colors hardcoded as hex RGB with comments:
```swift
Color(red: 0x0f/255, green: 0x19/255, blue: 0x23/255)  // dark navy
```

Local Color extensions in views that need them:
```swift
private extension Color {
    static let kBackground   = Color(...)
    static let kAccent       = Color(...)
}
```

### Layout & Styling
- Heavy use of opacity for visual hierarchy
- Tracking (letter-spacing) for typographic refinement
- `.opacity()` and `.offset()` for subtle animations
- Rounded corners: `RoundedRectangle(cornerRadius: 12)`

### State Management
```swift
@State private var variable       // Local view state
@Binding var parent               // Two-way binding to parent
@Environment(\.modelContext)      // SwiftData context
@AppStorage("key")                // UserDefaults backed
@Query                            // SwiftData query (automatic updates)
```

### Async/Await
- Uses `Task { }` for fire-and-forget work from UI
- `async/await` patterns in NotificationScheduler and BackgroundRefresh
- Proper cancellation handling with `Task.isCancelled` checks

---

## Git Configuration

**Repository**: Freshly initialized with rebranding commits

```
833f998 Merge pull request #1 from fresh37/claude/reset-orb-breathing-sync-yYwaN
aaa10b8 Reset orb to resting state when breathing pattern changes
5b3e04c Rebrand - first commit
6fcc701 Initial Commit
```

**.gitignore**:
- `CLAUDE.md` (this file)
- `.impeccable.md` (linting report)

---

## Development Notes

### Likely Pain Points

1. **iOS 26.2 Support** — Project targets a very new iOS version; may need to revisit if supporting older devices
2. **Background Task Timing** — BGAppRefreshTask is not reliable; iOS may delay or not run refresh
3. **Notification Limits** — Hard cap of 64 pending notifications; app caps at 60 to be safe
4. **Message Localization** — All messages hardcoded; no localization infrastructure yet

### Future Enhancements (from TODO comments)

- `MessagePool.swift` has TODO: "Refine all notification messages"
- Consider extracting view colors into a theme system
- SwiftData queries could benefit from more sophisticated sorting/filtering
- Meditation feature is present but may need UX polish

### Testing

- No test targets in current project
- @Preview blocks are used for SwiftUI previews (good for development)
- Manual testing of background refresh and notification scheduling required

---

## Common Tasks

### Adding a New Breathing Pattern

1. Add to `BreathingPattern.presets` in `Preferences.swift`
2. Update `BreathingPatternSheet.swift` to include in selector UI
3. Test breathing cycle in `BreathingOrbView.swift`

### Adding a New Notification Message

1. Add string to appropriate category in `MessagePool.swift`
2. Messages are shuffled and distributed proportionally to enabled categories

### Changing Notification Schedule

1. Adjust Preferences fields: `remindersPerDay`, `startHour`, `endHour`, `activeDays`
2. Notification reschedule happens automatically on pref changes via ContentView's onChange
3. Background refresh also reschedules on the 12-hour cycle

### Creating a New Goal/Habit

1. Create HabitGoal via CreateGoalView form
2. SwiftData handles persistence automatically via modelContext
3. Add Habits via AddHabitView
4. Completions tracked via HabitCompletion records

---

## Quick Reference: Key Files

| File | Purpose | LOC |
|------|---------|-----|
| KairosApp.swift | App entry (`CheckpointApp`), background registration | 28 |
| ContentView.swift | Root view routing, pref change handling | 45 |
| MainTabView.swift | Tab bar, notification status banner | 158 |
| BreathingOrbView.swift | Animated breathing circle | 130 |
| BreathingPatternSheet.swift | Pattern selector + custom editor | 239 |
| HabitsView.swift | Goal + habit list UI | 283 |
| NotificationScheduler.swift | Scheduling algorithm | 183 |
| BackgroundRefresh.swift | 12-hour background task | 68 |
| Preferences.swift | Validated user settings + BreathingPattern | 123 |
| SettingsDrawer.swift | Settings form sheet | 323 |
| MessagePool.swift | Notification message categories | 81 |
| OnboardingView.swift | First-launch flow + permission request | 174 |
| CreateGoalView.swift | Goal creation form | 153 |
| AddHabitView.swift | Add habit to goal | 251 |
| EditHabitView.swift | Edit habit sheet | 220 |
| GoalCompletedView.swift | Celebration overlay | 139 |
| ParticleEmitterView.swift | Particle animations | 74 |
| Models/* | SwiftData models (3 files) | 98 |

---

## Build & Run

```bash
# Open in Xcode
open Checkpoint.xcodeproj

# Or via workspace
open Checkpoint.xcodeproj/project.xcworkspace

# Build (requires valid team/signing)
xcodebuild build -scheme Checkpoint -configuration Debug

# No command-line test target yet; tests must be run in Xcode
```

---

*Last updated: March 28, 2026*
