//
//  MenuBarView.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var statsManager: StatsManager
    @State private var hasPermission: Bool = EventMonitor.checkPermission()
    @State private var permissionCheckTimer: Timer?

    var body: some View {
        Group {
            if hasPermission {
                PopoverView(statsManager: statsManager)
            } else {
                PermissionView(
                    onRequestPermission: requestPermission,
                    onOpenSettings: openSystemSettings
                )
            }
        }
        .onAppear {
            checkPermissionAndStart()
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
        }
    }

    private func checkPermissionAndStart() {
        hasPermission = EventMonitor.checkPermission()
        if hasPermission {
            statsManager.startMonitoring()
        } else {
            startPermissionCheckTimer()
        }
    }

    private func startPermissionCheckTimer() {
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let newPermission = EventMonitor.checkPermission()
            if newPermission != hasPermission {
                hasPermission = newPermission
                if newPermission {
                    permissionCheckTimer?.invalidate()
                    statsManager.startMonitoring()
                }
            }
        }
    }

    private func requestPermission() {
        EventMonitor.requestPermission()
    }

    private func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }
}
