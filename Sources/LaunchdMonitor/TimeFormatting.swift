import Foundation

enum TimeFormatting {
    /// "1:23:45" 形式（1時間未満なら "23:45"）
    static func compactCountdown(to date: Date, from now: Date) -> String {
        let remaining = max(0, Int(date.timeIntervalSince(now)))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    /// "1時間23分45秒" 形式
    static func verboseCountdown(to date: Date, from now: Date) -> String {
        let remaining = max(0, Int(date.timeIntervalSince(now)))
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        if h > 0 {
            return String(format: "%d時間%02d分%02d秒", h, m, s)
        } else if m > 0 {
            return String(format: "%d分%02d秒", m, s)
        } else {
            return String(format: "%d秒", s)
        }
    }
}
