import SwiftUI

@main
struct LaunchdMonitorApp: App {
    @StateObject private var viewModel = LaunchdMonitorViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(viewModel: viewModel)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var viewModel: LaunchdMonitorViewModel

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar.badge.clock")
            if viewModel.showTimerStyle, let upcoming = viewModel.nearestUpcoming(after: viewModel.now) {
                Text(TimeFormatting.compactCountdown(to: upcoming.date, from: viewModel.now))
                    .monospacedDigit()
            }
        }
    }
}
