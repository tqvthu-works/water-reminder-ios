import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    @State private var customMlText: String = ""
    @State private var customTime: Date = Date()

    private var progressText: String {
        let current = appState.mlToday
        let goal = appState.dailyGoalMl
        if current >= 1000 {
            return String(format: "%.1f / %.1f L", Double(current) / 1000, Double(goal) / 1000)
        } else {
            return "\(current) / \(goal) ml"
        }
    }

    private var progressPercent: Double {
        let goal = max(appState.dailyGoalMl, 1)
        return min(Double(appState.mlToday) / Double(goal), 1.0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Hôm nay")
                            .font(.title2)
                            .bold()

                        Text(progressText)
                            .font(.title3)
                            .foregroundColor(.blue)

                        ProgressView(value: progressPercent)
                            .progressViewStyle(.linear)
                            .tint(.blue)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    VStack(spacing: 12) {
                        Button {
                            appState.logWater(ml: 250, at: Date())
                        } label: {
                            Label("Đã uống 250 ml", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ghi nhận tùy chỉnh")
                                .font(.subheadline)
                                .bold()

                            HStack(spacing: 8) {
                                TextField("ml", text: $customMlText)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)

                                Text("ml")
                                    .foregroundColor(.secondary)

                                DatePicker("", selection: $customTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()

                                Spacer()

                                Button("Ghi nhận") {
                                    if let ml = Int(customMlText), ml > 0 {
                                        appState.logWater(ml: ml, at: customTime)
                                        customMlText = ""
                                        customTime = Date()
                                    }
                                }
                                .buttonStyle(.bordered)
                                .disabled(Int(customMlText) == nil || (Int(customMlText) ?? 0) <= 0)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    if !appState.isPaused, let slot = appState.currentSlot, appState.nextReminderDate != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lần nhắc tiếp theo")
                                .font(.subheadline)
                                .bold()

                            HStack {
                                Text(slot.timeString)
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.blue)

                                Text("\(slot.ml) ml")
                                    .font(.body)

                                Text(slot.label)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else if appState.isPaused {
                        Text("Đang tạm dừng nhắc nhở")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding()
                    }

                    Button {
                        appState.togglePause()
                    } label: {
                        Label(appState.isPaused ? "Tiếp tục nhắc" : "Tạm dừng nhắc",
                              systemImage: appState.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appState.isPaused ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Nhắc uống nước")
            .fullScreenCover(isPresented: $appState.showReminderPopup) {
                ReminderPopupView()
                    .environmentObject(appState)
            }
            .onAppear {
                appState.checkMissedAndNotify()
            }
        }
    }
}
