import Foundation

/// launchd.plist の StartCalendarInterval 1件分（Minute/Hour/Day/Weekday/Month はすべて省略可＝ワイルドカード）
struct CalendarIntervalRule: Hashable {
    var minute: Int?
    var hour: Int?
    var day: Int?
    var weekday: Int?
    var month: Int?

    /// 人が読める短い説明（例: "毎日 09:00"）
    var summary: String {
        var parts: [String] = []

        if let month {
            parts.append("\(month)月")
        }

        switch (day, weekday) {
        case let (d?, w?):
            parts.append("\(d)日 または \(Self.weekdayName(w))")
        case let (d?, nil):
            parts.append("\(d)日")
        case let (nil, w?):
            parts.append("毎週\(Self.weekdayName(w))")
        case (nil, nil):
            break
        }

        let h = hour.map { String(format: "%02d", $0) } ?? "**"
        let m = minute.map { String(format: "%02d", $0) } ?? "**"
        parts.append("\(h):\(m)")

        return parts.isEmpty ? "(不明なスケジュール)" : parts.joined(separator: " ")
    }

    static func weekdayName(_ w: Int) -> String {
        // launchd: 0 と 7 はどちらも日曜日
        let names = ["日", "月", "火", "水", "木", "金", "土", "日"]
        guard w >= 0, w <= 7 else { return "?" }
        return names[w] + "曜"
    }
}

enum LaunchdDomain: String {
    case userAgent = "ユーザーAgent"
    case globalAgent = "共通Agent"
    case globalDaemon = "共通Daemon"
}

struct LaunchdJob: Identifiable, Hashable {
    var label: String
    var plistPath: String
    var domain: LaunchdDomain
    var calendarRules: [CalendarIntervalRule]
    var startIntervalSeconds: Int?
    var disabled: Bool
    var isLoaded: Bool
    /// StandardOutPath/StandardErrorPath の更新日時から推定した最終実行時刻（StartInterval ジョブの目安計算用）
    var lastKnownRun: Date?

    var id: String { plistPath }

    var scheduleKind: ScheduleKind {
        if !calendarRules.isEmpty { return .calendar }
        if startIntervalSeconds != nil { return .interval }
        return .none
    }

    enum ScheduleKind {
        case calendar
        case interval
        case none
    }
}
