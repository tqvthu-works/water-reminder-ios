import Foundation
import UserNotifications

final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationService] Permission error: \(error.localizedDescription)")
            }
            if !granted {
                print("[NotificationService] Permission denied by user")
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleAllNotifications(from schedule: [ScheduleSlot]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let enabledSlots = schedule.filter { $0.isEnabled }
        print("[NotificationService] Scheduling \(enabledSlots.count) notifications")

        for slot in enabledSlots {
            let content = UNMutableNotificationContent()
            content.title = "Nhắc uống nước"
            content.body = "\(slot.label) - Uống \(slot.ml) ml nước"
            content.sound = .default
            content.userInfo = ["slotId": slot.id.uuidString]

            var dateComponents = DateComponents()
            dateComponents.hour = slot.hour
            dateComponents.minute = slot.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: slot.id.uuidString, content: content, trigger: trigger)

            center.add(request) { error in
                if let error = error {
                    print("[NotificationService] Failed to schedule \(slot.timeString): \(error.localizedDescription)")
                } else {
                    print("[NotificationService] Scheduled \(slot.timeString): \(slot.label)")
                }
            }
        }
    }

    func scheduleSnooze(afterMinutes minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Nhắc uống nước (nhắc lại)"
        content.body = "Đến giờ uống nước rồi!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "snooze", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationService] Failed to schedule snooze: \(error.localizedDescription)")
            }
        }
    }
}

extension Notification.Name {
    static let reminderNotificationTapped = Notification.Name("reminderNotificationTapped")
}
