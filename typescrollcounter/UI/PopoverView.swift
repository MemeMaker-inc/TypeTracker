//
//  PopoverView.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import SwiftUI
import Charts

struct PopoverView: View {
    @ObservedObject var statsManager: StatsManager
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Today").tag(0)
                Text("Week").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top)

            if selectedTab == 0 {
                TodayView(statsManager: statsManager)
            } else {
                WeeklyView(statsManager: statsManager)
            }

            Divider()
                .padding(.top, 8)

            HStack {
                Text(todayDateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 320)
    }

    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd (EEE)"
        return formatter.string(from: Date())
    }
}

struct TodayView: View {
    @ObservedObject var statsManager: StatsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            KeystrokeSectionView(keyCount: statsManager.keyCount)

            Divider()

            DistanceSectionView(distanceMM: statsManager.distanceMM)
        }
        .padding()
    }
}

struct KeystrokeSectionView: View {
    let keyCount: Int

    private var milestoneProgress: MilestoneProgress {
        KeystrokeMilestones.getProgress(for: keyCount)
    }

    private var completedCount: Int {
        KeystrokeMilestones.getCompletedMilestones(for: keyCount).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Typing", systemImage: "keyboard")
                    .font(.headline)
                Spacer()
                Text("\(completedCount)/\(KeystrokeMilestones.all.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(formattedKeyCount)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            if let next = milestoneProgress.next {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: next.icon)
                            .foregroundStyle(.blue)
                        Text(next.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(milestoneProgress.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: milestoneProgress.progress)
                        .tint(.blue)

                    Text("Remaining: \(formatNumber(Int(next.value) - keyCount)) keys")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let current = milestoneProgress.current {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Achieved: \(current.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var formattedKeyCount: String {
        "\(formatNumber(keyCount)) keys"
    }

    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }
}

struct DistanceSectionView: View {
    let distanceMM: Double

    private var milestoneProgress: MilestoneProgress {
        DistanceMilestones.getProgress(for: distanceMM)
    }

    private var completedCount: Int {
        DistanceMilestones.getCompletedMilestones(for: distanceMM).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Cursor", systemImage: "cursorarrow.motionlines")
                    .font(.headline)
                Spacer()
                Text("\(completedCount)/\(DistanceMilestones.all.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(formattedDistance)
                .font(.system(size: 28, weight: .bold, design: .rounded))

            if let next = milestoneProgress.next {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: next.icon)
                            .foregroundStyle(.green)
                        Text(next.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(Int(milestoneProgress.progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: milestoneProgress.progress)
                        .tint(.green)

                    Text("Remaining: \(formatDistance(next.value - distanceMM))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if let current = milestoneProgress.current {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Achieved: \(current.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var formattedDistance: String {
        formatDistance(distanceMM)
    }

    private func formatDistance(_ mm: Double) -> String {
        if mm >= 1_000_000 {
            return String(format: "%.2f km", mm / 1_000_000)
        } else if mm >= 1000 {
            return String(format: "%.1f m", mm / 1000)
        } else {
            return String(format: "%.0f mm", mm)
        }
    }
}

struct WeeklyView: View {
    @ObservedObject var statsManager: StatsManager
    private let dataStore = DataStore()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WeeklyChartView(dataStore: dataStore, statsManager: statsManager)

            Divider()

            WeeklySummaryView(dataStore: dataStore)
        }
        .padding()
    }
}

struct WeeklyChartView: View {
    let dataStore: DataStore
    @ObservedObject var statsManager: StatsManager
    @State private var chartMode: ChartMode = .keys

    enum ChartMode: String, CaseIterable {
        case keys = "Keys"
        case distance = "Distance"
    }

    private var weeklyStats: [DailyStats] {
        dataStore.getWeeklyStats()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $chartMode) {
                ForEach(ChartMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if #available(macOS 14.0, *) {
                Chart(weeklyStats, id: \.dateKey) { stat in
                    BarMark(
                        x: .value("Day", shortDayName(stat.date)),
                        y: .value(chartMode == .keys ? "Keys" : "Distance",
                                  chartMode == .keys ? Double(stat.keyCount) : stat.distanceMM / 1000)
                    )
                    .foregroundStyle(chartMode == .keys ? Color.blue : Color.green)
                    .cornerRadius(4)
                }
                .frame(height: 120)
                .chartYAxisLabel(chartMode == .keys ? "keys" : "meters")
            } else {
                SimpleBarChart(
                    stats: weeklyStats,
                    mode: chartMode
                )
                .frame(height: 120)
            }
        }
    }

    private func shortDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct SimpleBarChart: View {
    let stats: [DailyStats]
    let mode: WeeklyChartView.ChartMode

    private var maxValue: Double {
        let values = stats.map { mode == .keys ? Double($0.keyCount) : $0.distanceMM }
        return values.max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(stats, id: \.dateKey) { stat in
                VStack(spacing: 2) {
                    let value = mode == .keys ? Double(stat.keyCount) : stat.distanceMM
                    let height = maxValue > 0 ? (value / maxValue) * 80 : 0

                    RoundedRectangle(cornerRadius: 4)
                        .fill(mode == .keys ? Color.blue : Color.green)
                        .frame(width: 30, height: max(4, height))

                    Text(shortDayName(stat.date))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func shortDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct WeeklySummaryView: View {
    let dataStore: DataStore

    private var totals: (keyCount: Int, distanceMM: Double) {
        dataStore.getWeeklyTotals()
    }

    private var averages: (keyCount: Int, distanceMM: Double) {
        dataStore.getAverageDaily()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)

            HStack {
                StatBox(
                    title: "Total Keys",
                    value: formatNumber(totals.keyCount),
                    icon: "keyboard",
                    color: .blue
                )

                StatBox(
                    title: "Total Distance",
                    value: formatDistance(totals.distanceMM),
                    icon: "cursorarrow.motionlines",
                    color: .green
                )
            }

            if averages.keyCount > 0 {
                Text("Daily Average")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                HStack {
                    Text("\(formatNumber(averages.keyCount)) keys")
                        .font(.caption)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(formatDistance(averages.distanceMM))
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func formatNumber(_ num: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: num)) ?? "\(num)"
    }

    private func formatDistance(_ mm: Double) -> String {
        if mm >= 1_000_000 {
            return String(format: "%.1f km", mm / 1_000_000)
        } else if mm >= 1000 {
            return String(format: "%.0f m", mm / 1000)
        } else {
            return String(format: "%.0f mm", mm)
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    PopoverView(statsManager: StatsManager())
}
