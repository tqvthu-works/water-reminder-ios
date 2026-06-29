import SwiftUI

struct ScheduleEditorView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Mục tiêu: \(appState.dailyGoalMl) ml")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                List {
                    ForEach($appState.schedule) { $slot in
                        ScheduleRow(slot: $slot)
                    }
                    .onDelete { indexSet in
                        appState.schedule.remove(atOffsets: indexSet)
                        appState.rescheduleNotifications()
                    }
                }
                .listStyle(.insetGrouped)

                HStack {
                    Button {
                        appState.schedule.append(
                            ScheduleSlot(id: UUID(), hour: 12, minute: 0, ml: 250, isEnabled: true, label: "Khung mới")
                        )
                        appState.rescheduleNotifications()
                    } label: {
                        Label("Thêm khung giờ", systemImage: "plus.circle")
                    }

                    Spacer()

                    Button {
                        appState.schedule = AppState.defaultSchedule()
                        appState.rescheduleNotifications()
                    } label: {
                        Text("Reset mặc định")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle("Lịch uống nước")
        }
    }
}

struct ScheduleRow: View {
    @Binding var slot: ScheduleSlot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("", isOn: $slot.isEnabled)
                    .toggleStyle(.switch)
                    .labelsHidden()

                DatePicker(
                    "",
                    selection: timeBinding,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()

                Spacer()

                HStack(spacing: 2) {
                    TextField("ml", value: $slot.ml, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("ml")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            TextField("Ghi chú", text: $slot.label)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
        }
        .padding(.vertical, 4)
        .opacity(slot.isEnabled ? 1.0 : 0.5)
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: slot.hour,
                    minute: slot.minute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                slot.hour = comps.hour ?? 0
                slot.minute = comps.minute ?? 0
            }
        )
    }
}
