//
//  BreathingPatternSheet.swift
//  Checkpoint
//
//  Pattern selector sheet for the Breathe tab.
//  Presents preset patterns and a custom timing editor.
//

import SwiftUI

private let patternDescriptions: [String: String] = [
    "box":        "Focus & balance",
    "478":        "Relaxation & sleep",
    "coherent":   "Heart rate balance",
    "energizing": "Alertness & energy",
    "custom":     "Your own rhythm",
]

struct BreathingPatternSheet: View {
    @Binding var pattern: BreathingPattern
    @Environment(\.dismiss)   private var dismiss
    @Environment(\.appTheme)  private var theme

    // Local draft for custom pattern edits
    @State private var customDraft: BreathingPattern = .custom
    @State private var showCustomEditor = false

    var body: some View {
        NavigationView {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        sectionHeader("PATTERN")

                        VStack(spacing: 0) {
                            ForEach(BreathingPattern.presets) { preset in
                                patternRow(preset)
                            }
                            customRow
                        }
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)

                        if showCustomEditor {
                            timingSection
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Breathing Pattern")
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
        .onAppear {
            if !pattern.isPreset {
                customDraft = pattern
                showCustomEditor = true
            }
        }
    }

    // MARK: - Rows

    private func patternRow(_ p: BreathingPattern) -> some View {
        let isSelected = pattern.id == p.id
        return Button {
            pattern = p
            showCustomEditor = false
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(p.name)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.textPrimary)
                    Text(patternDescriptions[p.id] ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(theme.muted)
                }
                Spacer()
                Text(p.ratio)
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

    private var customRow: some View {
        let isSelected = pattern.id == "custom"
        return Button {
            if !isSelected {
                // Apply default custom or existing custom draft
                pattern = customDraft
            }
            withAnimation(.easeInOut(duration: 0.25)) {
                showCustomEditor.toggle()
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Custom")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(theme.textPrimary)
                    Text(patternDescriptions["custom"] ?? "")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(theme.muted)
                }
                Spacer()
                if isSelected {
                    Text(pattern.ratio)
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

    // MARK: - Custom Timing Editor

    private var timingSection: some View {
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
        .onChange(of: customDraft) {
            pattern = customDraft
        }
    }

    private func stepperRow(
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

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
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
}

extension BreathingPattern: Identifiable {}

#Preview {
    BreathingPatternSheet(pattern: .constant(.box))
}
