import Foundation
import Combine

final class StreakService: ObservableObject {
    static let shared = StreakService()

    @Published private(set) var streakCount: Int = 0
    @Published private(set) var lastCheckDate: Date = Date(timeIntervalSince1970: 0)

    private let streakKey = "streak.count"
    private let lastDateKey = "streak.lastDate"

    private init() {
        let d = UserDefaults.standard
        streakCount = d.integer(forKey: streakKey)
        if let last = d.object(forKey: lastDateKey) as? Date {
            lastCheckDate = last
        }
        // Ensure state is coherent on launch
        _ = updateIfNeeded(now: Date())
    }

    @discardableResult
    func updateIfNeeded(now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let lastDay = calendar.startOfDay(for: lastCheckDate)
        let today = calendar.startOfDay(for: now)

        if lastDay == today {
            return false // already counted today
        }

        // If user missed at least one full day, reset; otherwise increment
        if let diff = calendar.dateComponents([.day], from: lastDay, to: today).day, diff > 1 {
            streakCount = 1 // new streak starts today
        } else {
            streakCount = max(0, streakCount) + 1
        }
        lastCheckDate = now
        persist()
        objectWillChange.send()
        return true
    }

    private func persist() {
        let d = UserDefaults.standard
        d.set(streakCount, forKey: streakKey)
        d.set(lastCheckDate, forKey: lastDateKey)
    }
}


