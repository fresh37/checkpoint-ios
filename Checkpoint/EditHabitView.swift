//
//  EditHabitView.swift
//  Checkpoint
//
//  Sheet form for editing an existing habit's name and reward.
//

import SwiftData
import SwiftUI

struct EditHabitView: View {
    let habit: Habit

    @Environment(\.dismiss)  private var dismiss
    @Environment(\.appTheme) private var theme

    @State private var name: String
    @State private var amountText: String
    @State private var showHabitLoop = false
    @State private var cueText: String
    @State private var cravingText: String

    init(habit: Habit) {
        self.habit = habit
        _name = State(initialValue: habit.name)
        let dollars = Double(habit.rewardCents) / 100.0
        _amountText = State(initialValue: String(format: "%.2f", dollars))
        _cueText = State(initialValue: habit.cue)
        _cravingText = State(initialValue: habit.craving)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        habitSection
                        rewardSection
                        habitLoopSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdits() }
                        .foregroundStyle(isValid ? theme.accent : theme.textMuted)
                        .disabled(!isValid)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(theme.background)
    }

    // MARK: - Sections

    private var habitSection: some View {
        SettingsGroup(label: "Habit") {
            TextField("e.g. Meditate 10 min", text: $name)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
        }
    }

    private var rewardSection: some View {
        SettingsGroup(label: "Reward") {
            HStack {
                Text("$")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(theme.textMuted)
                TextField("0.00", text: $amountText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(theme.textPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
    }

    private var habitLoopSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsGroup(label: "Habit Loop") {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showHabitLoop.toggle() }
                } label: {
                    HStack {
                        Text("Think it through")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(theme.textMuted)
                            .rotationEffect(.degrees(showHabitLoop ? 180 : 0))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }

                if showHabitLoop {
                    rowDivider

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CUE")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(theme.textMuted)
                        TextField("After I ___", text: $cueText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(theme.textPrimary)
                        Text("The trigger that reliably precedes this habit")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(theme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    rowDivider

                    VStack(alignment: .leading, spacing: 4) {
                        Text("CRAVING")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(theme.textMuted)
                        TextField("I want to feel ___", text: $cravingText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(theme.textPrimary)
                        Text("The feeling or outcome that motivates this habit")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(theme.textMuted)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                }
            }

            Text("Optional. Mapping the cue and craving behind a habit helps it stick.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(theme.textMuted)
                .padding(.leading, 4)
        }
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(theme.divider)
            .frame(height: 0.5)
            .padding(.leading, 16)
    }

    // MARK: - Validation & save

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountCents != nil
    }

    private var amountCents: Int? {
        guard let value = Double(amountText), value > 0 else { return nil }
        return Int((value * 100).rounded())
    }

    private func saveEdits() {
        guard let cents = amountCents,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        habit.name = name.trimmingCharacters(in: .whitespaces)
        habit.rewardCents = cents
        habit.cue = cueText.trimmingCharacters(in: .whitespaces)
        habit.craving = cravingText.trimmingCharacters(in: .whitespaces)
        dismiss()
    }
}
