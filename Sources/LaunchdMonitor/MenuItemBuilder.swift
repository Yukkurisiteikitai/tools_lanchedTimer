import AppKit

enum MenuItemBuilder {
    static func icon(for job: LaunchdJob) -> NSImage? {
        let symbolName: String
        if job.disabled {
            symbolName = "pause.circle"
        } else {
            switch job.scheduleKind {
            case .calendar: symbolName = "calendar.badge.clock"
            case .interval: symbolName = "timer"
            case .none: symbolName = "questionmark.circle"
            }
        }
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: job.label)
        image?.isTemplate = true
        return image
    }

    static func attributedTitle(for job: LaunchdJob, now: Date, nextFire: Date?, showTimerStyle: Bool) -> NSAttributedString {
        let result = NSMutableAttributedString()

        let dotColor: NSColor = job.isLoaded ? .systemGreen : .tertiaryLabelColor
        result.append(NSAttributedString(string: "● ", attributes: [
            .foregroundColor: dotColor,
            .font: NSFont.systemFont(ofSize: 10)
        ]))

        result.append(NSAttributedString(string: job.label, attributes: [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium)
        ]))

        result.append(NSAttributedString(string: "\n" + scheduleDescription(for: job), attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor
        ]))

        result.append(NSAttributedString(string: "\n" + nextFireText(job: job, now: now, nextFire: nextFire, showTimerStyle: showTimerStyle), attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: nextFire == nil ? NSColor.secondaryLabelColor : NSColor.labelColor
        ]))

        return result
    }

    private static func scheduleDescription(for job: LaunchdJob) -> String {
        if job.disabled { return "無効化されています" }
        switch job.scheduleKind {
        case .calendar:
            return job.calendarRules.map { $0.summary }.joined(separator: " / ")
        case .interval:
            return "\(job.startIntervalSeconds ?? 0)秒ごと"
        case .none:
            return "スケジュールなし"
        }
    }

    private static func nextFireText(job: LaunchdJob, now: Date, nextFire: Date?, showTimerStyle: Bool) -> String {
        guard let nextFire else {
            if job.scheduleKind == .interval { return "次回時刻: 推定不可（未実行のため）" }
            return "次回時刻: -"
        }
        if showTimerStyle {
            return "あと " + TimeFormatting.verboseCountdown(to: nextFire, from: now)
        } else {
            return "次回: " + nextFire.formatted(date: .abbreviated, time: .shortened)
        }
    }
}
