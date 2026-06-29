import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationService()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func scheduleAllNotifications(from schedule: [ScheduleSlot]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: schedule.map { $0.id.uuidString })

        let enabledSlots = schedule.filter { $0.isEnabled }

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

            center.add(request)
        }
    }

    func scheduleSnooze(afterMinutes minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Nhắc uống nước (nhắc lại)"
        content.body = "Đến giờ uống nước rồi!"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "snooze", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: .reminderNotificationTapped, object: nil)
        completionHandler()
    }
}

extension Notification.Name {
    static let reminderNotificationTapped = Notification.Name("reminderNotificationTapped")
}
