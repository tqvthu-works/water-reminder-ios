import SwiftUI

struct ReminderPopupView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var mlText: String = ""
    @State private var drinkTime: Date = Date()

    private let quickPicks = [100, 200, 250, 330, 500]

    private var isMissedMode: Bool { appState.currentSlot == nil && appState.missedMl > 0 }

    private var prefillMl: Int {
        if let slot = appState.currentSlot { return slot.ml }
        if appState.missedMl > 0 { return appState.missedMl }
        return 250
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                if let slot = appState.currentSlot {
                    Text(slot.timeString)
                        .font(.title)
                        .bold()
                        .foregroundColor(.blue)

                    Text(slot.label)
                        .font(.headline)
                        .multilineTextAlignment(.center)

                    Text("Uống \(slot.ml) ml nước")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else if appState.missedMl > 0 {
                    Text("Bạn đang thiếu nước!")
                        .font(.title2)
                        .bold()

                    Text("Các khung giờ đã qua nhưng chưa uống đủ.\nNên uống bù \(appState.missedMl) ml.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Đến giờ uống nước rồi!")
                        .font(.title2)
                        .bold()
                }

                VStack(spacing: 12) {
                    Text("Chọn nhanh")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(quickPicks, id: \.self) { ml in
                            Button("\(ml)") {
                                mlText = "\(ml)"
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField("ml", text: $mlText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    Text("ml")
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text("Thời gian:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $drinkTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }

                VStack(spacing: 12) {
                    Button {
                        if let ml = Int(mlText), ml > 0 {
                            appState.logWater(ml: ml, at: drinkTime)
                        } else {
                            appState.logWater(ml: prefillMl, at: drinkTime)
                        }
                        dismiss()
                    } label: {
                        Text("Uống rồi!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button {
                        appState.snooze(minutes: 5)
                        dismiss()
                    } label: {
                        Text("Nhắc lại sau 5 phút")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Bỏ qua")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Nhắc uống nước")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                mlText = "\(prefillMl)"
                drinkTime = Date()
            }
        }
    }
}
