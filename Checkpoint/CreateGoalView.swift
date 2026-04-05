//
//  CreateGoalView.swift
//  Checkpoint
//
//  Sheet form for creating a new purchase goal.
//

import SwiftData
import SwiftUI

// MARK: - View

struct CreateGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(\.appTheme)     private var theme

    @State private var name = ""
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        goalSection
                        amountSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("New Goal")
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
                    Button("Create") { saveGoal() }
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

    private var goalSection: some View {
        SettingsGroup(label: "What are you saving for?") {
            TextField("e.g. New running shoes", text: $name)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
        }
    }

    private var amountSection: some View {
        SettingsGroup(label: "Goal Amount") {
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

    // MARK: - Validation & save

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && amountCents != nil
    }

    private var amountCents: Int? {
        guard let value = Double(amountText), value > 0 else { return nil }
        return Int((value * 100).rounded())
    }

    private func saveGoal() {
        guard let cents = amountCents,
              !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let goal = HabitGoal(name: name.trimmingCharacters(in: .whitespaces), targetCents: cents)
        modelContext.insert(goal)

        // Clone habits from the most recent previous goal
        let descriptor = FetchDescriptor<HabitGoal>(
            predicate: #Predicate { !$0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        if let previousGoal = try? modelContext.fetch(descriptor).first {
            let sorted = previousGoal.habits.sorted { $0.order < $1.order }
            for (index, habit) in sorted.enumerated() {
                let clone = Habit(name: habit.name, rewardCents: habit.rewardCents, goal: goal)
                clone.order = index
                modelContext.insert(clone)
            }
        }

        dismiss()
    }
}
