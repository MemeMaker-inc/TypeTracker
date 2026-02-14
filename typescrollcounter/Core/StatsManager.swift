//
//  StatsManager.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import Foundation
import Combine
import AppKit

@MainActor
final class StatsManager: ObservableObject {

    @Published private(set) var keyCount: Int = 0
    @Published private(set) var distanceMM: Double = 0.0

    private let eventMonitor = EventMonitor()
    private let dataStore = DataStore()
    private var midnightTimer: Timer?
    private var lastRecordedDate: Date?

    init() {
        loadTodayStats()
        setupEventCallbacks()
        setupMidnightTimer()
        setupNotifications()
    }

    func startMonitoring() {
        eventMonitor.startMonitoring()
    }

    func stopMonitoring() {
        eventMonitor.stopMonitoring()
        saveCurrentStats()
    }

    private func setupEventCallbacks() {
        eventMonitor.onKeyDown = { [weak self] count in
            Task { @MainActor in
                self?.keyCount += count
                self?.saveCurrentStats()
            }
        }

        eventMonitor.onMouseMoved = { [weak self] distanceMM in
            Task { @MainActor in
                self?.distanceMM += distanceMM
                self?.saveCurrentStats()
            }
        }
    }

    private func loadTodayStats() {
        if let stats = dataStore.loadTodayStats() {
            keyCount = stats.keyCount
            distanceMM = stats.distanceMM
            lastRecordedDate = stats.date
        } else {
            keyCount = 0
            distanceMM = 0.0
            lastRecordedDate = Date()
        }
    }

    private func saveCurrentStats() {
        let stats = DailyStats(
            date: Date(),
            keyCount: keyCount,
            distanceMM: distanceMM
        )
        dataStore.saveDailyStats(stats)
    }

    private func setupMidnightTimer() {
        scheduleMidnightTimer()
    }

    private func scheduleMidnightTimer() {
        midnightTimer?.invalidate()

        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return
        }

        let timeInterval = midnight.timeIntervalSinceNow

        midnightTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.resetForNewDay()
                self?.scheduleMidnightTimer()
            }
        }
    }

    private func resetForNewDay() {
        saveCurrentStats()
        keyCount = 0
        distanceMM = 0.0
        lastRecordedDate = Date()
        saveCurrentStats()
    }

    func checkAndResetIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastRecordedDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            if lastDay < today {
                resetForNewDay()
            }
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveCurrentStats()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndResetIfNeeded()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAndResetIfNeeded()
            }
        }
    }

    var distanceFormatted: String {
        if distanceMM >= 1_000_000 {
            return String(format: "%.1f km", distanceMM / 1_000_000)
        } else if distanceMM >= 1000 {
            return String(format: "%.1f m", distanceMM / 1000)
        } else {
            return String(format: "%.0f mm", distanceMM)
        }
    }

    var keyCountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: keyCount)) ?? "\(keyCount)"
    }
}
