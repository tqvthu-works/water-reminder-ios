import SwiftUI

@main
struct WaterReminderIosApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onReceive(NotificationCenter.default.publisher(for: .reminderNotificationTapped)) { _ in
                    appState.fireReminder()
                }
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Trang chủ", systemImage: "drop.fill")
                }

            ScheduleEditorView()
                .tabItem {
                    Label("Lịch", systemImage: "calendar")
                }

            WaterHistoryView()
                .tabItem {
                    Label("Lịch sử", systemImage: "list.bullet")
                }
        }
    }
}
