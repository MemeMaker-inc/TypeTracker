//
//  DataStore.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import Foundation

struct DailyStats: Codable {
    let date: Date
    let keyCount: Int
    let distanceMM: Double

    var dateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

final class DataStore {

    private let userDefaults = UserDefaults.standard

    private enum Keys {
        static let todayKeyCount = "todayKeyCount"
        static let todayDistanceMM = "todayDistanceMM"
        static let todayDateKey = "todayDateKey"
        static let historyData = "historyData"
    }

    private var todayDateKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func saveDailyStats(_ stats: DailyStats) {
        let currentDateKey = todayDateKey
        let savedDateKey = userDefaults.string(forKey: Keys.todayDateKey)

        if savedDateKey != currentDateKey {
            if let oldDateKey = savedDateKey {
                archiveOldStats(dateKey: oldDateKey)
            }
            userDefaults.set(currentDateKey, forKey: Keys.todayDateKey)
        }

        userDefaults.set(stats.keyCount, forKey: Keys.todayKeyCount)
        userDefaults.set(stats.distanceMM, forKey: Keys.todayDistanceMM)
    }

    func loadTodayStats() -> DailyStats? {
        let savedDateKey = userDefaults.string(forKey: Keys.todayDateKey)
        let currentDateKey = todayDateKey

        if savedDateKey != currentDateKey {
            if let oldDateKey = savedDateKey {
                archiveOldStats(dateKey: oldDateKey)
            }
            userDefaults.set(currentDateKey, forKey: Keys.todayDateKey)
            userDefaults.set(0, forKey: Keys.todayKeyCount)
            userDefaults.set(0.0, forKey: Keys.todayDistanceMM)
            return nil
        }

        let keyCount = userDefaults.integer(forKey: Keys.todayKeyCount)
        let distanceMM = userDefaults.double(forKey: Keys.todayDistanceMM)

        return DailyStats(date: Date(), keyCount: keyCount, distanceMM: distanceMM)
    }

    private func archiveOldStats(dateKey: String) {
        let keyCount = userDefaults.integer(forKey: Keys.todayKeyCount)
        let distanceMM = userDefaults.double(forKey: Keys.todayDistanceMM)

        var history = loadHistory()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateKey) {
            let stats = DailyStats(date: date, keyCount: keyCount, distanceMM: distanceMM)
            history.append(stats)

            if history.count > 365 {
                history = Array(history.suffix(365))
            }

            saveHistory(history)
        }
    }

    func loadHistory() -> [DailyStats] {
        guard let data = userDefaults.data(forKey: Keys.historyData) else {
            return []
        }

        do {
            let history = try JSONDecoder().decode([DailyStats].self, from: data)
            return history
        } catch {
            print("Failed to decode history: \(error)")
            return []
        }
    }

    private func saveHistory(_ history: [DailyStats]) {
        do {
            let data = try JSONEncoder().encode(history)
            userDefaults.set(data, forKey: Keys.historyData)
        } catch {
            print("Failed to encode history: \(error)")
        }
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: Keys.todayKeyCount)
        userDefaults.removeObject(forKey: Keys.todayDistanceMM)
        userDefaults.removeObject(forKey: Keys.todayDateKey)
        userDefaults.removeObject(forKey: Keys.historyData)
    }

    func getWeeklyStats() -> [DailyStats] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: today) else {
            return []
        }

        let history = loadHistory()
        let todayStats = loadTodayStats()

        var weeklyStats: [DailyStats] = []

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: weekAgo) else {
                continue
            }

            let targetDay = calendar.startOfDay(for: targetDate)

            if calendar.isDate(targetDay, inSameDayAs: today), let stats = todayStats {
                weeklyStats.append(stats)
            } else if let found = history.first(where: { calendar.isDate($0.date, inSameDayAs: targetDay) }) {
                weeklyStats.append(found)
            } else {
                weeklyStats.append(DailyStats(date: targetDate, keyCount: 0, distanceMM: 0))
            }
        }

        return weeklyStats
    }

    func getWeeklyTotals() -> (keyCount: Int, distanceMM: Double) {
        let weekly = getWeeklyStats()
        let totalKeys = weekly.reduce(0) { $0 + $1.keyCount }
        let totalDistance = weekly.reduce(0.0) { $0 + $1.distanceMM }
        return (totalKeys, totalDistance)
    }

    func getAverageDaily() -> (keyCount: Int, distanceMM: Double) {
        let history = loadHistory()
        guard !history.isEmpty else { return (0, 0) }

        let totalKeys = history.reduce(0) { $0 + $1.keyCount }
        let totalDistance = history.reduce(0.0) { $0 + $1.distanceMM }

        return (totalKeys / history.count, totalDistance / Double(history.count))
    }
}
