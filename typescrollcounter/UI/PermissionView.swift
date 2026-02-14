//
//  PermissionView.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import SwiftUI

struct PermissionView: View {
    var onRequestPermission: () -> Void
    var onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.badge.eye")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Input Monitoring Required")
                .font(.headline)

            Text("TypeTracker needs Input Monitoring permission to count keystrokes and track cursor movement.\n\nNo content is recorded - only counts.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 12) {
                Button(action: onRequestPermission) {
                    Text("Grant Permission")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onOpenSettings) {
                    Text("Open System Settings")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .padding()
        .frame(width: 280)
    }
}

#Preview {
    PermissionView(
        onRequestPermission: {},
        onOpenSettings: {}
    )
}
