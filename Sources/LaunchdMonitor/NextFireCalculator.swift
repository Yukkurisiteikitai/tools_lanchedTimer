import Foundation

/// StartCalendarInterval のセマンティクス（man launchd.plist）に基づき、次回発火日時を計算する。
/// - 省略されたフィールドはワイルドカード（＝どの値でも一致）
/// - Day と Weekday が両方指定されている場合は OR（どちらか一致すれば発火）
/// - それ以外の指定フィールド（Month, Hour, Minute, Day-or-Weekday）は AND
enum NextFireCalculator {
    /// 単一ルールでの次回発火日時。`after` より厳密に後の最初の時刻を返す。
    static func nextFire(for rule: CalendarIntervalRule, after: Date, calendar: Calendar = .current) -> Date? {
        let maxDaysToSearch = 366 * 5 // うるう年条件（2/29指定など）を考慮し最大5年探索

        var dayCursor = calendar.startOfDay(for: after)

        for _ in 0..<maxDaysToSearch {
            defer { dayCursor = calendar.date(byAdding: .day, value: 1, to: dayCursor) ?? dayCursor }

            let comps = calendar.dateComponents([.year, .month, .day, .weekday], from: dayCursor)
            guard let year = comps.year, let month = comps.month, let day = comps.day, let weekdayRaw = comps.weekday else { continue }
            // Foundation の weekday は 1=日曜〜7=土曜。launchd の 0/7=日曜 系に合わせて 0-6 (日=0) に変換。
            let weekday = weekdayRaw - 1

            if let ruleMonth = rule.month, ruleMonth != month { continue }

            switch (rule.day, rule.weekday) {
            case let (d?, w?):
                if day != d && weekday != w && weekday + 7 != w { continue }
            case let (d?, nil):
                if day != d { continue }
            case let (nil, w?):
                if weekday != w && weekday + 7 != w { continue }
            case (nil, nil):
                break
            }

            let hours = rule.hour.map { [$0] } ?? Array(0...23)
            let minutes = rule.minute.map { [$0] } ?? Array(0...59)

            var candidates: [Date] = []
            for h in hours {
                for m in minutes {
                    var c = DateComponents()
                    c.year = year
                    c.month = month
                    c.day = day
                    c.hour = h
                    c.minute = m
                    c.second = 0
                    if let d = calendar.date(from: c), d > after {
                        candidates.append(d)
                    }
                }
            }

            if let earliest = candidates.min() {
                return earliest
            }
        }

        return nil
    }

    /// 複数ルール（配列指定＝OR）の中で最も早い次回発火日時。
    static func nextFire(for rules: [CalendarIntervalRule], after: Date, calendar: Calendar = .current) -> Date? {
        rules.compactMap { nextFire(for: $0, after: after, calendar: calendar) }.min()
    }

    /// StartInterval（秒間隔）ジョブの推定次回発火時刻。
    /// launchd は最終実行時刻を外部に公開しないため、ログファイルの更新日時があればそれを起点に推定する。
    static func estimatedNextFire(intervalSeconds: Int, lastKnownRun: Date?, after: Date) -> Date? {
        guard intervalSeconds > 0 else { return nil }
        guard let lastKnownRun else { return nil }
        var next = lastKnownRun
        while next <= after {
            next = next.addingTimeInterval(TimeInterval(intervalSeconds))
        }
        return next
    }
}
