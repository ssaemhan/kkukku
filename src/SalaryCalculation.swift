import Foundation

func parseWorkTime(_ text: String, allowEndOfDay: Bool = false) -> Int? {
    let parts = text.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":", omittingEmptySubsequences: false)
    guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]), m >= 0, m < 60 else { return nil }
    if allowEndOfDay && h == 24 && m == 0 { return 1440 }
    guard h >= 0, h < 24 else { return nil }
    return h * 60 + m
}
func workTimeLabel(_ minutes: Int) -> String { String(format: "%02d:%02d", minutes / 60, minutes % 60) }
func earnedSalary(monthly: Double, now: Date, weekdays: Set<Int>, startMinute: Int = 0, endMinute: Int = 1440, calendar: Calendar = .current) -> Int {
    guard let month = calendar.dateInterval(of: .month, for: now), startMinute != endMinute else { return 0 }
    var day = calendar.date(byAdding: .day, value: -1, to: month.start)!
    var total: TimeInterval = 0
    var elapsed: TimeInterval = 0
    while day < month.end {
        guard let next = calendar.date(byAdding: .day, value: 1, to: day), next > day else { break }
        if weekdays.contains(calendar.component(.weekday, from: day)) {
            let start = calendar.date(bySettingHour: startMinute / 60, minute: startMinute % 60, second: 0, of: day)!
            let endDay = endMinute <= startMinute || endMinute == 1440 ? next : day
            let end = calendar.date(bySettingHour: (endMinute / 60) % 24, minute: endMinute % 60, second: 0, of: endDay)!
            let clippedStart = max(start, month.start)
            let clippedEnd = min(end, month.end)
            let duration = max(0, clippedEnd.timeIntervalSince(clippedStart))
            total += duration
            elapsed += max(0, min(duration, now.timeIntervalSince(clippedStart)))
        }
        day = next
    }
    guard total > 0 else { return 0 }
    return Int((monthly * max(0, min(1, elapsed / total))).rounded(.down))
}

