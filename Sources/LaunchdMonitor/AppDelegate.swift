import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var jobs: [LaunchdJob] = []
    private var lastRefreshed = Date()
    private var showTimerStyle = false

    private var clockTimer: Timer?
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let icon = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: "Launchd Monitor")
        icon?.isTemplate = true
        item.button?.image = icon
        item.button?.imagePosition = .imageLeading
        statusItem = item

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        refresh()

        let refreshTimer = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(refreshTimer, forMode: .common)
        self.refreshTimer = refreshTimer

        // NOTE: 常時1秒間隔で駆動している。メニューが閉じていてタイマー表示もOFFの間は
        // 本来更新不要 -- 「開いている間・ON中だけ動かす」への切り替えは次回対応予定。
        let clockTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateStatusItemTitle()
        }
        RunLoop.main.add(clockTimer, forMode: .common)
        self.clockTimer = clockTimer

        updateStatusItemTitle()
    }

    private func refresh() {
        jobs = LaunchdScanner.scanAll()
        lastRefreshed = Date()
    }

    private func nextFire(for job: LaunchdJob, after now: Date) -> Date? {
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

    private func nearestUpcoming(after now: Date) -> (job: LaunchdJob, date: Date)? {
        jobs.compactMap { job -> (LaunchdJob, Date)? in
            guard let date = nextFire(for: job, after: now) else { return nil }
            return (job, date)
        }.min { $0.1 < $1.1 }
    }

    private func updateStatusItemTitle() {
        guard showTimerStyle, let nearest = nearestUpcoming(after: Date()) else {
            statusItem.button?.title = ""
            return
        }
        statusItem.button?.title = " " + TimeFormatting.compactCountdown(to: nearest.date, from: Date())
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        refresh()
        rebuild(menu)
    }

    private func rebuild(_ menu: NSMenu) {
        menu.removeAllItems()

        let header = NSMenuItem(title: "Launchd 次回発火監視", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        let now = Date()
        if jobs.isEmpty {
            let empty = NSMenuItem(
                title: "launchd ジョブが見つかりませんでした",
                action: nil,
                keyEquivalent: ""
            )
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for job in jobs {
                let fire = nextFire(for: job, after: now)
                let item = NSMenuItem(title: job.label, action: #selector(noop), keyEquivalent: "")
                item.target = self
                item.attributedTitle = MenuItemBuilder.attributedTitle(
                    for: job, now: now, nextFire: fire, showTimerStyle: showTimerStyle
                )
                item.image = MenuItemBuilder.icon(for: job)
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        let toggle = NSMenuItem(title: "タイマー表示（カウントダウン）", action: #selector(toggleTimerStyle), keyEquivalent: "")
        toggle.target = self
        toggle.state = showTimerStyle ? .on : .off
        menu.addItem(toggle)

        let refreshItem = NSMenuItem(title: "再スキャン", action: #selector(refreshTapped), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let statusLine = NSMenuItem(
            title: "更新: \(lastRefreshed.formatted(date: .omitted, time: .standard))",
            action: nil,
            keyEquivalent: ""
        )
        statusLine.isEnabled = false
        menu.addItem(statusLine)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "終了", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    /// ジョブ情報行はクリック不可だが、action なしだと AppKit が自動的に淡色表示にしてしまうため
    /// no-op アクションを与えて有効状態(=通常の色)のまま表示する。
    @objc private func noop() {}

    @objc private func toggleTimerStyle() {
        showTimerStyle.toggle()
        updateStatusItemTitle()
    }

    @objc private func refreshTapped() {
        refresh()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
