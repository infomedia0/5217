import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: TimerModel
    private let accent = Color(red: 0.82, green: 0.96, blue: 0.44)
    private var days: [FocusDay] { FocusHistorySummary.days(containing: model.historyWeek, sessions: model.focusSessions) }
    private var weekMinutes: Int { days.reduce(0) { $0 + $1.minutes } }
    private var weekTitle: String {
        let calendar = FocusHistorySummary.calendar
        return "Week \(calendar.component(.weekOfYear, from: model.historyWeek)) · \(calendar.component(.yearForWeekOfYear, from: model.historyWeek))"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Focus history").font(.system(size: 25, weight: .semibold))
                    Text("\(model.focusSessions.count) completed sessions · \(FocusHistorySummary.duration(model.focusSessions.count * 52)) total")
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
                Spacer()
                Button("Back") { model.screen = .timer }.keyboardShortcut(.cancelAction)
            }
            if let error = model.historyError { Text(error).font(.caption).foregroundColor(.orange) }
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button { moveWeek(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Previous week")
                    VStack(spacing: 3) {
                        Text(weekTitle).font(.headline)
                        if let first = days.first, let last = days.last {
                            Text("\(first.date.formatted(.dateTime.month(.abbreviated).day())) – \(last.date.formatted(.dateTime.month(.abbreviated).day()))")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }.frame(maxWidth: .infinity)
                    Button { moveWeek(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(FocusHistorySummary.calendar.isDate(model.historyWeek, equalTo: Date(), toGranularity: .weekOfYear))
                        .accessibilityLabel("Next week")
                    Button("This week") { model.historyWeek = Date() }
                }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(days) { day in
                        VStack(spacing: 7) {
                            Text(FocusHistorySummary.duration(day.minutes)).font(.system(size: 11, design: .monospaced))
                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.04))
                                RoundedRectangle(cornerRadius: 5).fill(accent)
                                    .frame(height: day.count == 0 ? 0 : max(4, 110 * Double(day.count) / Double(max(1, days.map(\.count).max() ?? 1))))
                            }.frame(height: 110)
                            Text(day.date.formatted(.dateTime.weekday(.abbreviated))).font(.caption)
                            Text(day.date.formatted(.dateTime.day())).font(.caption2).foregroundColor(.secondary)
                        }.frame(maxWidth: .infinity)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(day.date.formatted(date: .complete, time: .omitted)): \(day.count) focus sessions, \(FocusHistorySummary.duration(day.minutes))")
                    }
                }
                Text("Week total: \(FocusHistorySummary.duration(weekMinutes)) · \(weekMinutes / 52) sessions")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(accent)
                Text("Monday–Sunday · Sessions count on their completion day.")
                    .font(.caption2).foregroundColor(.secondary)
            }.padding(16).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            HStack {
                Text("ALL COMPLETED FOCUS SESSIONS").font(.system(size: 10, weight: .semibold)).tracking(1)
                Spacer()
                Text("52m each").font(.caption).foregroundColor(.secondary)
            }
            if model.focusSessions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.badge.checkmark").font(.largeTitle).foregroundColor(accent)
                    Text("Your focus history starts here").font(.headline)
                    Text("Finish a 52-minute focus timer to add a session. Breaks and skipped timers aren’t included.")
                        .font(.system(size: 13)).foregroundColor(.secondary).multilineTextAlignment(.center)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.focusSessions) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.completedAt.formatted(date: .abbreviated, time: .omitted)).font(.system(size: 13, weight: .medium))
                                    Text("Completed at \(session.completedAt.formatted(date: .omitted, time: .shortened))")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("52m").font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(accent)
                            }.padding(.vertical, 11)
                            Divider()
                        }
                    }
                }
            }
            Text("Saved on this Mac as JSON. Available history from earlier versions is imported automatically.")
                .font(.caption2).foregroundColor(.secondary)
        }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(red: 0.075, green: 0.09, blue: 0.085)).preferredColorScheme(.dark)
    }
    private func moveWeek(_ amount: Int) {
        if let date = FocusHistorySummary.calendar.date(byAdding: .weekOfYear, value: amount, to: model.historyWeek) { model.historyWeek = date }
    }
}
