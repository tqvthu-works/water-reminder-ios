import Foundation
import Combine
import UserNotifications

struct ScheduleSlot: Codable, Identifiable {
    let id: UUID
    var hour: Int
    var minute: Int
    var ml: Int
    var isEnabled: Bool
    var label: String

    var timeString: String {
        String(format: "%d:%02d", hour, minute)
    }
}

struct WaterLog: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    var ml: Int
}

final class AppState: ObservableObject {

    @Published var schedule: [ScheduleSlot] {
        didSet {
            if let data = try? JSONEncoder().encode(schedule) {
                UserDefaults.standard.set(data, forKey: Keys.schedule)
            }
        }
    }

    var dailyGoalMl: Int {
        schedule.filter { $0.isEnabled }.reduce(0) { $0 + $1.ml }
    }

    @Published var logsToday: [WaterLog] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(logsToday) {
                UserDefaults.standard.set(data, forKey: Keys.logsToday)
            }
        }
    }

    var mlToday: Int {
        logsToday.reduce(0) { $0 + $1.ml }
    }

    @Published var isPaused: Bool = false
    @Published var nextReminderDate: Date? = nil
    @Published var currentSlot: ScheduleSlot? = nil
    @Published var missedMl: Int = 0
    @Published var showReminderPopup: Bool = false

    private var snoozeTimer: Timer?
    private var lastResetDay: Int

    private enum Keys {
        static let schedule = "schedule_v1"
        static let logsToday = "logsToday"
        static let lastResetDay = "lastResetDay"
    }

    init() {
        let defaults = UserDefaults.standard

        if let data = defaults.data(forKey: Keys.schedule),
           let decoded = try? JSONDecoder().decode([ScheduleSlot].self, from: data) {
            self.schedule = decoded
        } else {
            self.schedule = Self.defaultSchedule()
        }

        self.lastResetDay = defaults.object(forKey: Keys.lastResetDay) as? Int
            ?? Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0

        if let data = defaults.data(forKey: Keys.logsToday),
           let decoded = try? JSONDecoder().decode([WaterLog].self, from: data) {
            self.logsToday = decoded
        } else {
            self.logsToday = []
        }

        resetCupsIfNewDay()
        NotificationService.shared.requestPermission()
        NotificationService.shared.scheduleAllNotifications(from: schedule)
        calculateNextReminder()
    }

    func checkMissedAndNotify() {
        let deficit = calculateDeficit()
        if deficit > 0 {
            missedMl = deficit
            showReminderPopup = true
        }
    }

    private func calculateDeficit() -> Int {
        let cal = Calendar.current
        let now = Date()
        let passedEnabled = schedule.filter { slot in
            guard slot.isEnabled else { return false }
            if let slotDate = cal.date(bySettingHour: slot.hour, minute: slot.minute, second: 0, of: now) {
                return slotDate <= now
            }
            return false
        }
        let expectedMl = passedEnabled.reduce(0) { $0 + $1.ml }
        return max(0, expectedMl - mlToday)
    }

    func calculateNextReminder() {
        guard !isPaused else {
            nextReminderDate = nil
            currentSlot = nil
            return
        }

        let enabledSlots = schedule.filter { $0.isEnabled }
        guard !enabledSlots.isEmpty else {
            nextReminderDate = nil
            currentSlot = nil
            return
        }

        let sorted = enabledSlots.sorted { a, b in
            a.hour * 60 + a.minute < b.hour * 60 + b.minute
        }

        let cal = Calendar.current
        let now = Date()

        for slot in sorted {
            if let slotDate = cal.date(bySettingHour: slot.hour, minute: slot.minute, second: 0, of: now),
               slotDate > now {
                currentSlot = slot
                nextReminderDate = slotDate
                return
            }
        }

        let firstSlot = sorted[0]
        if let tomorrowSlot = cal.date(byAdding: .day, value: 1, to: now).flatMap({
            cal.date(bySettingHour: firstSlot.hour, minute: firstSlot.minute, second: 0, of: $0)
        }) {
            currentSlot = firstSlot
            nextReminderDate = tomorrowSlot
        }
    }

    func pauseTimer() {
        isPaused = true
        snoozeTimer?.invalidate()
        snoozeTimer = nil
        nextReminderDate = nil
        NotificationService.shared.cancelAll()
    }

    func resumeTimer() {
        isPaused = false
        NotificationService.shared.scheduleAllNotifications(from: schedule)
        calculateNextReminder()
    }

    func togglePause() {
        if isPaused { resumeTimer() } else { pauseTimer() }
    }

    func snooze(minutes: Int) {
        snoozeTimer?.invalidate()
        let seconds = TimeInterval(minutes * 60)
        nextReminderDate = Date().addingTimeInterval(seconds)
        NotificationService.shared.scheduleSnooze(afterMinutes: minutes)
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.fireReminder()
        }
    }

    func fireReminder() {
        resetCupsIfNewDay()
        missedMl = 0
        showReminderPopup = true
        calculateNextReminder()
    }

    func logWater(ml: Int, at timestamp: Date = Date()) {
        resetCupsIfNewDay()
        let log = WaterLog(id: UUID(), timestamp: timestamp, ml: ml)
        logsToday.append(log)
        logsToday.sort { $0.timestamp < $1.timestamp }
    }

    func deleteLog(id: UUID) {
        logsToday.removeAll { $0.id == id }
    }

    func rescheduleNotifications() {
        guard !isPaused else { return }
        NotificationService.shared.scheduleAllNotifications(from: schedule)
        calculateNextReminder()
    }

    private func resetCupsIfNewDay() {
        let today = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        if today != lastResetDay {
            logsToday = []
            lastResetDay = today
            UserDefaults.standard.set(lastResetDay, forKey: Keys.lastResetDay)
        }
    }

    static func defaultSchedule() -> [ScheduleSlot] {
        [
            ScheduleSlot(id: UUID(), hour: 6,  minute: 30, ml: 300, isEnabled: true, label: "Buổi sáng"),
            ScheduleSlot(id: UUID(), hour: 8,  minute: 0,  ml: 300, isEnabled: true, label: "Trước bữa sáng"),
            ScheduleSlot(id: UUID(), hour: 9,  minute: 30, ml: 250, isEnabled: true, label: "Giờ làm việc"),
            ScheduleSlot(id: UUID(), hour: 11, minute: 0,  ml: 250, isEnabled: true, label: "Trước bữa trưa"),
            ScheduleSlot(id: UUID(), hour: 13, minute: 30, ml: 250, isEnabled: true, label: "Sau ăn trưa"),
            ScheduleSlot(id: UUID(), hour: 15, minute: 0,  ml: 250, isEnabled: true, label: "Giữa giờ chiều"),
            ScheduleSlot(id: UUID(), hour: 16, minute: 30, ml: 200, isEnabled: true, label: "Cuối giờ làm"),
            ScheduleSlot(id: UUID(), hour: 18, minute: 0,  ml: 200, isEnabled: true, label: "Trước bữa tối"),
            ScheduleSlot(id: UUID(), hour: 20, minute: 30, ml: 150, isEnabled: true, label: "Cuối ngày"),
        ]
    }
}
