import Foundation
import UserNotifications
import WidgetKit

// Напоминания, которые ты просишь у Булька в чате:
// уведомление iPhone в нужное время + табличка 🔔 на виджете.
enum Reminders {
    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f
    }()

    static func add(text: String, at: String) {
        guard let date = parser.date(from: at), date > Date() else { return }

        var s = BulkStore.load()
        s.reminders.removeAll { $0.at < Date().addingTimeInterval(-24 * 3600) }
        s.reminders.append(Reminder(text: text, at: date))
        BulkStore.save(s, writer: "app")
        WidgetCenter.shared.reloadAllTimelines()

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Бульк"
            content.body = text
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger))
        }
    }
}

// Чтобы уведомление показывалось, даже когда приложение открыто.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
