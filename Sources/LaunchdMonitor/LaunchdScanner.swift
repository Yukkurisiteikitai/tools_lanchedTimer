import Foundation

/// ~/Library/LaunchAgents, /Library/LaunchAgents, /Library/LaunchDaemons を走査し、
/// launchctl list の結果と突き合わせて LaunchdJob の一覧を作る。
/// （/System/Library 配下の OS 内蔵デーモンは大半がスケジュール実行を持たず件数も膨大なため対象外）
enum LaunchdScanner {
    private static func targetDirectories() -> [(path: String, domain: LaunchdDomain)] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            (home + "/Library/LaunchAgents", .userAgent),
            ("/Library/LaunchAgents", .globalAgent),
            ("/Library/LaunchDaemons", .globalDaemon),
        ]
    }

    /// `launchctl list` に現れているラベル＝現在ロードされているジョブ
    private static func loadedLabels() -> Set<String> {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["list"]
        let outPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return []
        }
        let data = outPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard let output = String(data: data, encoding: .utf8) else { return [] }

        var labels = Set<String>()
        for line in output.split(separator: "\n").dropFirst() {
            let fields = line.split(separator: "\t", omittingEmptySubsequences: false)
            if let last = fields.last {
                let label = String(last).trimmingCharacters(in: .whitespaces)
                if !label.isEmpty { labels.insert(label) }
            }
        }
        return labels
    }

    static func scanAll() -> [LaunchdJob] {
        let loaded = loadedLabels()
        var jobs: [LaunchdJob] = []

        for (dirPath, domain) in targetDirectories() {
            guard let entries = try? FileManager.default.contentsOfDirectory(atPath: dirPath) else { continue }
            for entry in entries where entry.hasSuffix(".plist") {
                let fullPath = dirPath + "/" + entry
                if let job = parsePlist(at: fullPath, domain: domain, loaded: loaded) {
                    jobs.append(job)
                }
            }
        }

        return jobs.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    private static func parsePlist(at path: String, domain: LaunchdDomain, loaded: Set<String>) -> LaunchdJob? {
        guard let data = FileManager.default.contents(atPath: path) else { return nil }
        guard let plist = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] else {
            return nil
        }
        guard let label = plist["Label"] as? String else { return nil }

        let disabled = (plist["Disabled"] as? Bool) ?? false

        var rules: [CalendarIntervalRule] = []
        if let dict = plist["StartCalendarInterval"] as? [String: Any] {
            rules = [parseRule(dict)]
        } else if let array = plist["StartCalendarInterval"] as? [[String: Any]] {
            rules = array.map(parseRule)
        }

        let startInterval = plist["StartInterval"] as? Int

        var lastKnownRun: Date?
        for key in ["StandardOutPath", "StandardErrorPath"] {
            if let logPath = plist[key] as? String,
               let attrs = try? FileManager.default.attributesOfItem(atPath: logPath),
               let modified = attrs[.modificationDate] as? Date {
                if lastKnownRun == nil || modified > lastKnownRun! {
                    lastKnownRun = modified
                }
            }
        }

        return LaunchdJob(
            label: label,
            plistPath: path,
            domain: domain,
            calendarRules: rules,
            startIntervalSeconds: startInterval,
            disabled: disabled,
            isLoaded: loaded.contains(label),
            lastKnownRun: lastKnownRun
        )
    }

    private static func parseRule(_ dict: [String: Any]) -> CalendarIntervalRule {
        CalendarIntervalRule(
            minute: dict["Minute"] as? Int,
            hour: dict["Hour"] as? Int,
            day: dict["Day"] as? Int,
            weekday: dict["Weekday"] as? Int,
            month: dict["Month"] as? Int
        )
    }
}
