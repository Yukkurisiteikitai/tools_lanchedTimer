import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LaunchdMonitorViewModel

    var body: some View {
        let now = viewModel.now
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if viewModel.jobs.isEmpty {
                Text("launchd ジョブが見つかりませんでした\n(~/Library/LaunchAgents, /Library/LaunchAgents, /Library/LaunchDaemons)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                // ScrollView は自身の内容から自然な高さを算出できないため、
                // MenuBarExtra(.window) の自動サイジングに任せると高さ0に潰れてしまう。
                // ジョブ数から明示的に高さを計算して指定する。
                let rowHeight: CGFloat = 58
                let visibleRows = min(viewModel.jobs.count, 6)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.jobs) { job in
                            JobRow(
                                job: job,
                                now: now,
                                showTimerStyle: viewModel.showTimerStyle,
                                nextFire: viewModel.nextFire(for: job, after: now)
                            )
                            Divider()
                        }
                    }
                }
                .frame(height: rowHeight * CGFloat(visibleRows))
            }

            footer
        }
        .frame(width: 340)
    }

    private var header: some View {
        HStack {
            Text("Launchd 次回発火監視")
                .font(.headline)
            Spacer()
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("再スキャン")
        }
        .padding([.horizontal, .top], 12)
        .padding(.bottom, 8)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            Toggle(isOn: $viewModel.showTimerStyle) {
                Label("タイマー表示（カウントダウン）", systemImage: "timer")
                    .font(.callout)
            }
            .toggleStyle(.switch)

            HStack {
                Text("更新: \(viewModel.lastRefreshed.formatted(date: .omitted, time: .standard))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("終了") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                .font(.caption)
            }
        }
        .padding(12)
    }
}
