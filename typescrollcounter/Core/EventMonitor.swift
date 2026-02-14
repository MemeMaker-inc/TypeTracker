//
//  EventMonitor.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import Foundation
import CoreGraphics

final class EventMonitor: @unchecked Sendable {

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRunning = false

    private var previousMouseLocation: CGPoint?
    private var accumulatedDistance: Double = 0.0
    private var batchTimer: Timer?

    var onKeyDown: ((Int) -> Void)?
    var onMouseMoved: ((Double) -> Void)?

    private let batchInterval: TimeInterval = 0.1

    func startMonitoring() {
        guard !isRunning else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue) |
                                     (1 << CGEventType.mouseMoved.rawValue) |
                                     (1 << CGEventType.leftMouseDragged.rawValue) |
                                     (1 << CGEventType.rightMouseDragged.rawValue) |
                                     (1 << CGEventType.otherMouseDragged.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<EventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                monitor.handleEvent(type: type, event: event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            print("Failed to create event tap. Check Input Monitoring permission.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        if let source = runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            isRunning = true

            startBatchTimer()
        }
    }

    func stopMonitoring() {
        guard isRunning else { return }

        batchTimer?.invalidate()
        batchTimer = nil

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
        isRunning = false
        previousMouseLocation = nil
    }

    private func startBatchTimer() {
        batchTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            self?.flushBatch()
        }
    }

    private func flushBatch() {
        if accumulatedDistance > 0 {
            let distance = accumulatedDistance
            accumulatedDistance = 0
            DispatchQueue.main.async { [weak self] in
                self?.onMouseMoved?(distance)
            }
        }
    }

    private func handleEvent(type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            DispatchQueue.main.async { [weak self] in
                self?.onKeyDown?(1)
            }

        case .mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged:
            let currentLocation = event.location

            if let previous = previousMouseLocation {
                let dx = currentLocation.x - previous.x
                let dy = currentLocation.y - previous.y
                let distanceInPoints = sqrt(dx * dx + dy * dy)

                if distanceInPoints < 500 {
                    let distanceMM = convertPointsToMM(distanceInPoints)
                    accumulatedDistance += distanceMM
                }
            }

            previousMouseLocation = currentLocation

        default:
            break
        }
    }

    private func convertPointsToMM(_ points: Double) -> Double {
        let displayID = CGMainDisplayID()
        let physicalSize = CGDisplayScreenSize(displayID)
        let bounds = CGDisplayBounds(displayID)

        guard bounds.width > 0 else { return 0 }

        let mmPerPoint = physicalSize.width / bounds.width
        return points * mmPerPoint
    }

    static func checkPermission() -> Bool {
        return CGPreflightListenEventAccess()
    }

    static func requestPermission() {
        CGRequestListenEventAccess()
    }
}
