//
//  OnboardingView.swift
//  Checkpoint
//
//  Shown once on first launch. Requests notification permission, then
//  calls scheduleNotifications() before handing off to the main view.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    @Binding var prefs: Preferences
    @Binding var isComplete: Bool
    @Binding var showWelcome: Bool

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTheme)   private var theme

    @State private var isRequesting = false
    @State private var isExpanded   = false
    @State private var breathTask: Task<Void, Never>?
    @State private var appeared     = false

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Animated orb — same cycle as BreathingOrbView
                Circle()
                    .fill(
                        RadialGradient(
                            stops: [
                                .init(color: theme.orbHighlight, location: 0.00),
                                .init(color: theme.accentLight,  location: 0.30),
                                .init(color: theme.accent,        location: 0.60),
                                .init(color: theme.accentDeep,   location: 0.85),
                                .init(color: theme.orbRim,        location: 1.00),
                            ],
                            center: UnitPoint(x: 0.42, y: 0.36),
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: theme.glowColor.opacity(isExpanded ? 0.40 : 0.25),
                            radius: isExpanded ? 28 : 19)
                    .shadow(color: theme.glowColor.opacity(isExpanded ? 0.15 : 0.08),
                            radius: isExpanded ? 50 : 38)
                    .scaleEffect(isExpanded ? 1.2 : 1.0)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 1.0).delay(0.1), value: appeared)
                    .padding(.bottom, 48)

                // Title
                Text("Checkpoint")
                    .font(.system(size: 46, weight: .ultraLight))
                    .tracking(-0.5)
                    .foregroundColor(.white.opacity(0.92))
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.8).delay(0.45), value: appeared)

                // Subtitle
                Text("Brief pauses, delivered throughout your day.\nNothing to remember. Nothing to open.")
                    .font(.system(size: 16, weight: .light))
                    .tracking(0.1)
                    .foregroundColor(.white.opacity(0.50))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 14)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.8).delay(0.65), value: appeared)

                Spacer()

                // Primary CTA
                Button {
                    requestPermissionAndFinish()
                } label: {
                    Group {
                        if isRequesting {
                            ProgressView()
                                .tint(theme.background)
                        } else {
                            Text("Enable Reminders")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(theme.background)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .disabled(isRequesting)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.8).delay(0.9), value: appeared)

                // Skip link
                Button("Skip for now") {
                    isComplete = true
                }
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.38))
                .padding(.top, 18)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(1.05), value: appeared)
            }
        }
        .onAppear {
            startCycle()
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.05))
                appeared = true
            }
        }
        .onDisappear { breathTask?.cancel() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { startCycle() } else { breathTask?.cancel(); breathTask = nil }
        }
    }

    // MARK: - Breathing cycle
    //
    // Simplified version of BreathingOrbView's cycle — same 4s/4s/4s/4s rhythm,
    // but without phase labels. Pairs inhale+hold and exhale+hold into two 8s sleeps.

    private func startCycle() {
        breathTask?.cancel()
        breathTask = Task { @MainActor in
            while !Task.isCancelled {
                withAnimation(.linear(duration: 4)) { isExpanded = true }
                try? await Task.sleep(for: .seconds(8))   // inhale 4s + hold 4s
                guard !Task.isCancelled else { return }
                withAnimation(.linear(duration: 4)) { isExpanded = false }
                try? await Task.sleep(for: .seconds(8))   // exhale 4s + hold 4s
                guard !Task.isCancelled else { return }
            }
        }
    }

    // MARK: - Permission request

    private func requestPermissionAndFinish() {
        isRequesting = true
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if granted {
                NotificationScheduler.scheduleNotifications(prefs: prefs)
                showWelcome = true
            }
            isComplete = true
        }
    }
}

#Preview {
    OnboardingView(prefs: .constant(Preferences()), isComplete: .constant(false), showWelcome: .constant(false))
}
