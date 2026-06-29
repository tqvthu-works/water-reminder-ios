import SwiftUI

struct WaterHistoryView: View {
    @EnvironmentObject var appState: AppState

    private var sortedLogs: [WaterLog] {
        appState.logsToday.sorted { $0.timestamp > $1.timestamp }
    }

    private var progressText: String {
        let current = appState.mlToday
        let goal = appState.dailyGoalMl
        if current >= 1000 {
            return String(format: "%.1f / %.1f L", Double(current) / 1000, Double(goal) / 1000)
        } else {
            return "\(current) / \(goal) ml"
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    HStack {
                        Text(progressText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    ProgressView(value: Double(appState.mlToday), total: Double(max(appState.dailyGoalMl, 1)))
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if sortedLogs.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "drop")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Chưa có dữ liệu")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Hãy uống nước và ghi nhận để xem lịch sử ở đây.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(sortedLogs) { log in
                            WaterLogRow(log: log)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let log = sortedLogs[index]
                                appState.deleteLog(id: log.id)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Lịch sử hôm nay")
        }
    }
}

struct WaterLogRow: View {
    let log: WaterLog

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: log.timestamp)
    }

    var body: some View {
        HStack {
            Text(timeString)
                .font(.system(.body, design: .monospaced))
                .frame(width: 60, alignment: .leading)

            Text("\(log.ml) ml")
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "drop.fill")
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}
