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
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()
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
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.appAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { saveGoal() }
                        .foregroundStyle(isValid ? Color.appAccent : Color.appTextMuted)
                        .disabled(!isValid)
                }
            }
        }
        .colorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.appBackground)
    }

    // MARK: - Sections

    private var goalSection: some View {
        SettingsGroup(label: "What are you saving for?") {
            TextField("e.g. New running shoes", text: $name)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
        }
    }

    private var amountSection: some View {
        SettingsGroup(label: "Goal Amount") {
            HStack {
                Text("$")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.appTextMuted)
                TextField("0.00", text: $amountText)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(Color.appTextPrimary)
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
            for (i, habit) in sorted.enumerated() {
                let clone = Habit(name: habit.name, rewardCents: habit.rewardCents, goal: goal)
                clone.order = i
                modelContext.insert(clone)
            }
        }

        dismiss()
    }
}
