import SwiftUI

struct JobRow: View {
    let job: LaunchdJob
    let now: Date
    let showTimerStyle: Bool
    let nextFire: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(job.label)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(scheduleDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(nextFireText)
                    .font(.caption)
                    .foregroundStyle(nextFire == nil ? .secondary : .primary)
                    .monospacedDigit()
            }

            Spacer(minLength: 4)

            Circle()
                .fill(job.isLoaded ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 7, height: 7)
                .help(job.isLoaded ? "ロード済み" : "未ロード")
                .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var iconName: String {
        if job.disabled { return "pause.circle" }
        switch job.scheduleKind {
        case .calendar: return "calendar.badge.clock"
        case .interval: return "timer"
        case .none: return "questionmark.circle"
        }
    }

    private var iconColor: Color {
        job.disabled ? .secondary : .accentColor
    }

    private var scheduleDescription: String {
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

    private var nextFireText: String {
        guard let nextFire else {
            if job.disabled { return "次回時刻: -" }
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
