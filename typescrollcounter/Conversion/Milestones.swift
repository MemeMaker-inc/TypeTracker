//
//  Milestones.swift
//  typescrollcounter
//
//  Created by Claude on 2026/02/14.
//

import Foundation

struct Milestone: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let icon: String
    let description: String
}

struct MilestoneProgress {
    let current: Milestone?
    let next: Milestone?
    let progress: Double
    let isCompleted: Bool
}

enum KeystrokeMilestones {
    static let all: [Milestone] = [
        Milestone(name: "Tweet", value: 140, icon: "bubble.left", description: "1 tweet"),
        Milestone(name: "Email", value: 500, icon: "envelope", description: "Short email"),
        Milestone(name: "A4 Page", value: 800, icon: "doc.text", description: "1 A4 page"),
        Milestone(name: "Blog Post", value: 2_000, icon: "newspaper", description: "Blog article"),
        Milestone(name: "Essay", value: 5_000, icon: "doc.richtext", description: "Short essay"),
        Milestone(name: "Short Story", value: 10_000, icon: "book.closed", description: "Short story"),
        Milestone(name: "Report", value: 25_000, icon: "doc.text.magnifyingglass", description: "Business report"),
        Milestone(name: "Thesis Chapter", value: 50_000, icon: "graduationcap", description: "1 chapter"),
        Milestone(name: "Novella", value: 100_000, icon: "books.vertical", description: "Novella"),
        Milestone(name: "Novel", value: 250_000, icon: "book", description: "Short novel"),
        Milestone(name: "HP Book 1", value: 516_000, icon: "wand.and.stars", description: "Harry Potter 1"),
        Milestone(name: "War and Peace", value: 1_200_000, icon: "building.columns", description: "Epic novel"),
        Milestone(name: "HP All Books", value: 6_506_000, icon: "sparkles", description: "All HP books"),
    ]

    static func getProgress(for count: Int) -> MilestoneProgress {
        let countDouble = Double(count)

        var completedMilestone: Milestone?
        var nextMilestone: Milestone?

        for (index, milestone) in all.enumerated() {
            if countDouble >= milestone.value {
                completedMilestone = milestone
                if index + 1 < all.count {
                    nextMilestone = all[index + 1]
                }
            } else {
                if nextMilestone == nil {
                    nextMilestone = milestone
                }
                break
            }
        }

        let progress: Double
        if let next = nextMilestone {
            let base = completedMilestone?.value ?? 0
            progress = (countDouble - base) / (next.value - base)
        } else {
            progress = 1.0
        }

        return MilestoneProgress(
            current: completedMilestone,
            next: nextMilestone,
            progress: min(1.0, max(0, progress)),
            isCompleted: nextMilestone == nil
        )
    }

    static func getCompletedMilestones(for count: Int) -> [Milestone] {
        return all.filter { Double(count) >= $0.value }
    }
}

enum DistanceMilestones {
    static let all: [Milestone] = [
        Milestone(name: "Screen Width", value: 600, icon: "display", description: "27\" display"),
        Milestone(name: "Desk Length", value: 1_500, icon: "desk", description: "Office desk"),
        Milestone(name: "Room", value: 5_000, icon: "square.split.bottomrightquarter", description: "Across a room"),
        Milestone(name: "Hallway", value: 20_000, icon: "arrow.left.and.right", description: "Down the hall"),
        Milestone(name: "100m Sprint", value: 100_000, icon: "figure.run", description: "100m dash"),
        Milestone(name: "Football Field", value: 110_000, icon: "sportscourt", description: "Full field"),
        Milestone(name: "Around the Block", value: 400_000, icon: "map", description: "City block"),
        Milestone(name: "1 km", value: 1_000_000, icon: "flag", description: "1 kilometer"),
        Milestone(name: "Tokyo Tower", value: 3_330_000, icon: "building.2", description: "333m height"),
        Milestone(name: "Mt. Fuji", value: 3_776_000, icon: "mountain.2", description: "3,776m"),
        Milestone(name: "5K Run", value: 5_000_000, icon: "figure.run.circle", description: "5km race"),
        Milestone(name: "10K Run", value: 10_000_000, icon: "medal", description: "10km race"),
        Milestone(name: "Half Marathon", value: 21_097_500, icon: "trophy", description: "21.1km"),
        Milestone(name: "Full Marathon", value: 42_195_000, icon: "trophy.fill", description: "42.195km"),
        Milestone(name: "Ultramarathon", value: 100_000_000, icon: "star.circle", description: "100km"),
        Milestone(name: "Tokyo-Osaka", value: 400_000_000, icon: "car", description: "400km"),
    ]

    static func getProgress(for distanceMM: Double) -> MilestoneProgress {
        var completedMilestone: Milestone?
        var nextMilestone: Milestone?

        for (index, milestone) in all.enumerated() {
            if distanceMM >= milestone.value {
                completedMilestone = milestone
                if index + 1 < all.count {
                    nextMilestone = all[index + 1]
                }
            } else {
                if nextMilestone == nil {
                    nextMilestone = milestone
                }
                break
            }
        }

        let progress: Double
        if let next = nextMilestone {
            let base = completedMilestone?.value ?? 0
            progress = (distanceMM - base) / (next.value - base)
        } else {
            progress = 1.0
        }

        return MilestoneProgress(
            current: completedMilestone,
            next: nextMilestone,
            progress: min(1.0, max(0, progress)),
            isCompleted: nextMilestone == nil
        )
    }

    static func getCompletedMilestones(for distanceMM: Double) -> [Milestone] {
        return all.filter { distanceMM >= $0.value }
    }
}
