//
//  HabitHistoryView.swift
//  Checkpoint
//
//  Sheet showing all habit completions for the active goal, grouped by day.
//  Provides access to the Undo action previously on the main habits screen.
//

import SwiftData
import SwiftUI

struct HabitHistoryView: View {
    let goal: HabitGoal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme)     private var theme
    @Environment(\.dismiss)      private var dismiss

    private struct DayGroup: Identifiable {
        let id: Date
        let completions: [HabitCompletion]
    }

    private var sortedCompletions: [HabitCompletion] {
        goal.habits
            .flatMap(\.completions)
            .sorted { $0.completedAt > $1.completedAt }
    }

    private var dayGroups: [DayGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedCompletions) {
            calendar.startOfDay(for: $0.completedAt)
        }
        return grouped.keys
            .sorted(by: >)
            .map { day in DayGroup(id: day, completions: grouped[day] ?? []) }
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if sortedCompletions.isEmpty {
                    emptyState
                } else {
                    historyList
                }
                undoButton
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("History")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(8)
                    .background(.white.opacity(0.08))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No history yet.")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.white.opacity(0.35))
            Spacer()
        }
    }

    // MARK: - History list

    private var historyList: some View {
        List {
            ForEach(dayGroups) { group in
                Section {
                    ForEach(group.completions) { completion in
                        completionRow(completion)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.white.opacity(0.05))
                                    .padding(.vertical, 0.5)
                            )
                            .listRowInsets(EdgeInsets(top: 0.5, leading: 20, bottom: 0.5, trailing: 20))
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    Text(sectionTitle(for: group.id))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                        .textCase(nil)
                        .padding(.leading, 4)
                        .padding(.bottom, 4)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func completionRow(_ completion: HabitCompletion) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(completion.habit?.name ?? "Deleted habit")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.85))
                Text(timeString(for: completion.completedAt))
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
            }
            Spacer()
            Text("+\(formattedCents(completion.amountCents))")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.accent)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    // MARK: - Undo button

    private var undoButton: some View {
        HStack {
            Spacer()
            Button("Undo Last Entry") {
                if let completion = sortedCompletions.first {
                    modelContext.delete(completion)
                }
            }
            .disabled(sortedCompletions.isEmpty)
            Spacer()
        }
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(sortedCompletions.isEmpty ? 0.1 : 0.25))
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func sectionTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private func timeString(for date: Date) -> String {
        date.formatted(.dateTime.hour().minute())
    }

    private func formattedCents(_ cents: Int) -> String {
        let dollars = Double(cents) / 100.0
        return dollars.formatted(.currency(code: "USD"))
    }
}
