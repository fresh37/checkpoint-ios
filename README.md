# Checkpoint

A mindfulness and habit-tracking iOS app that delivers brief, guided mindfulness moments throughout your day via notifications. Combine breathing exercises with habit tracking to build positive routines while earning progress toward personal goals.

*Brief pauses, delivered throughout your day. Nothing to remember. Nothing to open.*

## Features

### Breathing Exercises
- Animated breathing orb with real-time phase labels (inhale, hold, exhale)
- Preset patterns: Box (4-4-4-4), 4-7-8 Relaxation, Coherent (5-5), Energizing (6-2-2)
- Custom pattern editor with adjustable timing (1-12s per phase)

### Smart Notifications
- Configurable reminders per day with start/end time windows
- Day-of-week filtering
- Three mindfulness categories: Gratitude, Body Awareness, Present Moment
- Optional meditation reminders with separate scheduling
- Background refresh keeps notifications queued up to 6 days ahead

### Habit & Goal Tracking
- Set financial savings goals and attach habits with monetary rewards
- Log completions to earn progress toward your goal
- Habit Loop support (cue, craving, response, reward) based on habit formation science
- Goal completion celebration with animations and haptic feedback
- Habits carry over automatically when starting a new goal

## Tech Stack

- **SwiftUI** - Declarative UI
- **SwiftData** - Persistent storage
- **UserNotifications** - Local notification scheduling
- **BackgroundTasks** - Background refresh for notification queuing
- **os.Logger** - System logging
- No external dependencies

## Requirements

- iOS 26.0+
- Xcode 26+
- Swift 5.0+

## Building

1. Clone the repository
2. Open `Checkpoint.xcodeproj` in Xcode
3. Select a target device or simulator
4. Build and run (Cmd+R)

No dependency installation needed -- the project uses only Apple frameworks.

## Project Structure

```
Checkpoint/
  KairosApp.swift              App entry point
  ContentView.swift            Root navigation & onboarding router
  MainTabView.swift            Tab bar (Breathe + Habits)
  Theme.swift                  Shared color palette & reusable components
  Models/
    HabitGoal.swift            Goal data model
    Habit.swift                Habit data model
    HabitCompletion.swift      Completion event model
  Preferences.swift            Settings with validation & UserDefaults persistence
  NotificationScheduler.swift  Notification scheduling algorithm
  MessagePool.swift            Mindfulness message collections (61 messages)
  BackgroundRefresh.swift      BGAppRefreshTask management
  BreathingOrbView.swift       Animated breathing visualization
  BreathingPatternSheet.swift  Pattern selector & custom editor
  HabitsView.swift             Habit list, progress card, completions
  OnboardingView.swift         First-launch flow & permission request
  SettingsDrawer.swift         Preferences editor
  AddHabitView.swift           Add habit form
  EditHabitView.swift          Edit habit form
  CreateGoalView.swift         Create goal form
  GoalCompletedView.swift      Goal completion celebration
  ParticleEmitterView.swift    Celebration particle effects
```

## License

All rights reserved.
