//
//  AddHabitView.swift
//  Checkpoint
//
//  Sheet form for adding a habit to the active goal.
//

import SwiftData
import SwiftUI

// MARK: - View

struct AddHabitView: View {
    let goal: HabitGoal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.appTheme)     private var theme

    @State private var name = ""
    @State private var amountText = ""
    @State private var showHabitLoop = false
    @State private var cueText = ""
    @State private var cravingText = ""

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
            .navigationTitle("Add Habit")
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
                    Button("Add") { saveHabit() }
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
            textFieldRow(placeholder: "e.g. Meditate 10 min", text: $name)
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

                    rowDivider

                    readOnlyRow(label: "Response", value: name)

                    rowDivider

                    readOnlyRow(label: "Reward", value: amountCents != nil ? "$\(amountText)" : "")
                }
            }

            Text("Optional. Mapping the cue and craving behind a habit helps it stick. Saved with the habit.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(theme.textMuted)
                .padding(.leading, 4)
        }
    }

    // MARK: - Row types

    private func textFieldRow(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 17, weight: .regular))
            .foregroundStyle(theme.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
    }

    private func readOnlyRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    // MARK: - Divider

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

    private func saveHabit() {
        guard let cents = amountCents,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let habit = Habit(
            name: name.trimmingCharacters(in: .whitespaces),
            rewardCents: cents,
            goal: goal
        )
        habit.order = goal.habits.count
        habit.cue = cueText.trimmingCharacters(in: .whitespaces)
        habit.craving = cravingText.trimmingCharacters(in: .whitespaces)
        modelContext.insert(habit)
        dismiss()
    }
}
