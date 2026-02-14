//
//  typescrollcounterApp.swift
//  typescrollcounter
//
//  Created by Yuki Takatsu on 2026/02/14.
//

import SwiftUI

@main
struct typescrollcounterApp: App {
    @StateObject private var statsManager = StatsManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(statsManager: statsManager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                Text(statsManager.keyCountFormatted)
                Image(systemName: "cursorarrow.motionlines")
                Text(statsManager.distanceFormatted)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
