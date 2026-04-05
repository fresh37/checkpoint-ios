//
//  BreathingTimerSheet.swift
//  Checkpoint
//
//  Configuration sheet for a timed breathing session.
//  Lets the user pick session duration, interval bells, and a per-session pattern.
//

import SwiftUI

struct BreathingTimerSheet: View {
    let initialPattern: BreathingPattern
    /// Called when the user taps "Start Session".
    let onStart: (_ durationSeconds: Int, _ bellIntervalSeconds: Int?, _ pattern: BreathingPattern) -> Void

    @Environment(\.dismiss)  private var dismiss
    @Environment(\.appTheme) private var theme

    // MARK: - Duration

    private let durationOptions: [(label: String, minutes: Int)] = [
        ("5 min", 5),
        ("10 min", 10),
        ("15 min", 15),
        ("20 min", 20),
        ("30 min", 30)
    ]

    @State private var selectedMinutes = 10
    @State private var useCustomDuration = false
    @State private var customMinutes = 10

    // MARK: - Interval Bells

    private let bellOptions: [(label: String, minutes: Int)] = [
        ("Every 1 min", 1),
        ("Every 2 min", 2),
        ("Every 5 min", 5),
        ("Every 10 min", 10)
    ]

    @State private var bellsEnabled = false
    @State private var bellIntervalMinutes = 5

    // MARK: - Pattern

    @State private var localPattern: BreathingPattern
    @State private var showCustomEditor = false
    @State private var customDraft: BreathingPattern = .custom

    init(
        initialPattern: BreathingPattern,
        onStart: @escaping (_ durationSeconds: Int, _ bellIntervalSeconds: Int?, _ pattern: BreathingPattern) -> Void
    ) {
        self.initialPattern = initialPattern
        self.onStart = onStart
        _localPattern = State(initialValue: initialPattern)
        if !initialPattern.isPreset {
            _customDraft = State(initialValue: initialPattern)
            _showCustomEditor = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: Duration
                        sectionHeader("DURATION")

                        VStack(spacing: 0) {
                            ForEach(durationOptions.indices, id: \.self) { index in
                                let opt = durationOptions[index]
                                let isSelected = !useCustomDuration && selectedMinutes == opt.minutes
                                durationRow(label: opt.label, isSelected: isSelected) {
                                    useCustomDuration = false
                                    selectedMinutes = opt.minutes
                                }
                            }

                            // Custom duration row with inline stepper
                            customDurationRow
                        }
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                        // MARK: Interval Bells
                        sectionHeader("INTERVAL BELLS")

                        VStack(spacing: 0) {
                            // Toggle row
                            HStack {
                                Text("Interval Bells")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(theme.textPrimary)
                                Spacer()
                                Toggle("", isOn: $bellsEnabled)
                                    .labelsHidden()
                                    .tint(theme.accent)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                            .overlay(alignment: .bottom) {
                                if bellsEnabled {
                                    theme.divider.frame(height: 0.5).padding(.leading, 16)
                                }
                            }

                            if bellsEnabled {
                                ForEach(bellOptions.indices, id: \.self) { index in
                                    let opt = bellOptions[index]
                                    let isSelected = bellIntervalMinutes == opt.minutes
                                    let isLast = index == bellOptions.count - 1
                                    durationRow(
                                        label: opt.label,
                                        isSelected: isSelected,
                                        isLast: isLast
                                    ) {
                                        bellIntervalMinutes = opt.minutes
                                    }
                                }
                            }
                        }
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.2), value: bellsEnabled)

                        // MARK: Pattern
                        sectionHeader("BREATHING PATTERN")

                        VStack(spacing: 0) {
                            ForEach(BreathingPattern.presets) { preset in
                                patternRow(preset)
                            }
                            customPatternRow
                        }
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                        if showCustomEditor {
                            timingSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // MARK: Start Button
                        Button {
                            let duration = useCustomDuration ? customMinutes * 60 : selectedMinutes * 60
                            let bellInterval = bellsEnabled ? bellIntervalMinutes * 60 : nil
                            onStart(duration, bellInterval, localPattern)
                            dismiss()
                        } label: {
                            Text("Start Session")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(theme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(theme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Session Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.textPrimary)
                }
            }
        }
    }

    // MARK: - Duration Rows

    private func durationRow(
        label: String, isSelected: Bool, isLast: Bool = false, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if !isLast {
                theme.divider.frame(height: 0.5).padding(.leading, 16)
            }
        }
    }

    private var customDurationRow: some View {
        Button {
            useCustomDuration = true
        } label: {
            HStack {
                Text("Custom")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                if useCustomDuration {
                    Text("\(customMinutes) min")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(theme.muted)
                        .padding(.trailing, 8)
                    Stepper("", value: $customMinutes, in: 1...90)
                        .labelsHidden()
                        .tint(theme.muted)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(theme.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func patternRow(_ pattern: BreathingPattern) -> some View {
        let isSelected = localPattern.id == pattern.id
        return Button {
            localPattern = pattern
            showCustomEditor = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(pattern.name)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.textPrimary)
                    Text(patternDescription(for: pattern.id))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(theme.muted)
                }
                Spacer()
                Text(pattern.ratio)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.muted)
                    .padding(.trailing, isSelected ? 8 : 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            theme.divider.frame(height: 0.5).padding(.leading, 16)
        }
    }
}

private extension BreathingTimerSheet {
    var customPatternRow: some View {
        let isSelected = localPattern.id == "custom"
        return Button {
            if !isSelected { localPattern = customDraft }
            withAnimation(.easeInOut(duration: 0.25)) { showCustomEditor.toggle() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Custom")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.textPrimary)
                    Text("Your own rhythm")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(theme.muted)
                }
                Spacer()
                if isSelected {
                    Text(localPattern.ratio)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(theme.muted)
                        .padding(.trailing, 8)
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.accent)
                        .padding(.trailing, 8)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(theme.muted)
                    .rotationEffect(.degrees(showCustomEditor ? 180 : 0))
                    .animation(.easeInOut(duration: 0.25), value: showCustomEditor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var timingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("TIMING")
            VStack(spacing: 0) {
                stepperRow(label: "Inhale", value: $customDraft.inhale, range: 1...12)
                stepperRow(label: "Hold", value: $customDraft.holdIn, range: 0...12, zeroLabel: "skip")
                stepperRow(label: "Exhale", value: $customDraft.exhale, range: 1...12)
                stepperRow(label: "Hold", value: $customDraft.holdOut, range: 0...12, zeroLabel: "skip", isLast: true)
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 20)
        }
        .onChange(of: customDraft) { localPattern = customDraft }
    }

    func stepperRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        zeroLabel: String? = nil,
        isLast: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            if let zeroLabel, value.wrappedValue == 0 {
                Text(zeroLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.muted)
                    .padding(.trailing, 6)
            } else {
                Text("\(value.wrappedValue)s")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(theme.muted)
                    .padding(.trailing, 6)
            }
            Stepper("", value: value, in: range)
                .labelsHidden()
                .tint(theme.muted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if !isLast {
                theme.divider.frame(height: 0.5).padding(.leading, 16)
            }
        }
    }

    func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .regular))
                .tracking(11 * 0.08)
                .foregroundStyle(theme.muted)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            Spacer()
        }
    }
    func patternDescription(for id: String) -> String {
        switch id {
        case "box":        return "Focus & balance"
        case "478":        return "Relaxation & sleep"
        case "coherent":   return "Heart rate balance"
        case "energizing": return "Alertness & energy"
        default:           return "Your own rhythm"
        }
    }
}

#Preview {
    BreathingTimerSheet(initialPattern: .box) { _, _, _ in }
}
