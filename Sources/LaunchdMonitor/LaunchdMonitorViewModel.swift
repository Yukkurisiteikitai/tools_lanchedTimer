import Foundation
import Combine

@MainActor
final class LaunchdMonitorViewModel: ObservableObject {
    @Published var jobs: [LaunchdJob] = []
    @Published var lastRefreshed: Date = Date()
    @Published var showTimerStyle: Bool = false
    /// 1秒ごとに更新される「現在時刻」。カウントダウン表示の駆動に使う。
    @Published var now: Date = Date()

    private var refreshTimer: Timer?
    private var clockTimer: Timer?

    init() {
        refresh()

        let refreshTimer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(refreshTimer, forMode: .common)
        self.refreshTimer = refreshTimer

        let clockTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        RunLoop.main.add(clockTimer, forMode: .common)
        self.clockTimer = clockTimer
    }

    func refresh() {
        jobs = LaunchdScanner.scanAll()
        lastRefreshed = Date()
    }

    func nextFire(for job: LaunchdJob, after now: Date) -> Date? {
        guard !job.disabled else { return nil }
        switch job.scheduleKind {
        case .calendar:
            return NextFireCalculator.nextFire(for: job.calendarRules, after: now)
        case .interval:
            return NextFireCalculator.estimatedNextFire(
                intervalSeconds: job.startIntervalSeconds ?? 0,
                lastKnownRun: job.lastKnownRun,
                after: now
            )
        case .none:
            return nil
        }
    }

    /// 全ジョブの中で最も早い次回発火（メニューバー表示用）
    func nearestUpcoming(after now: Date) -> (job: LaunchdJob, date: Date)? {
        jobs.compactMap { job -> (LaunchdJob, Date)? in
            guard let date = nextFire(for: job, after: now) else { return nil }
            return (job, date)
        }.min { $0.1 < $1.1 }
    }
}
