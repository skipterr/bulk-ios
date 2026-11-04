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
        let reminder = Reminder(text: text, at: date)
        s.reminders.append(reminder)
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
            center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
        }
    }

    /// Бульк сам спросит, как всё прошло (без таблички на виджете — только уведомление).
    static func followUp(text: String, at: String) {
        guard let date = parser.date(from: at), date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Бульк"
        content.body = text
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "followup-" + UUID().uuidString, content: content, trigger: trigger))
    }

    /// «Я сделал» — убираем табличку с виджета (и уведомление, если оно ещё не пришло).
    /// hint — слова из дела; если ничего не совпало, закрываем то, что уже висит или вот-вот наступит.
    static func markDone(hint: String) {
        var s = BulkStore.load()
        let now = Date()
        let words = hint.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }).filter { $0.count > 2 }
        var done = s.reminders.filter { r in
            let text = r.text.lowercased()
            return words.contains { text.contains($0) }
        }
        if done.isEmpty {
            done = s.reminders.filter { $0.at <= now.addingTimeInterval(30 * 60) }
        }
        guard !done.isEmpty else { return }
        let ids = done.map(\.id)
        s.reminders.removeAll { ids.contains($0.id) }
        BulkStore.save(s, writer: "app")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// Бульк пишет первым: уходя из приложения, заранее ставим сообщения на случай, если ты пропадёшь.
// Открыл приложение — все снимаются.
enum Nudges {
    private static let ids = (0..<4).map { "nudge-\($0)" }
    private static let plan: [(days: Int, texts: [String])] = [
        (1, ["эй, ты где пропал?", "мне скучно, зайди", "я тут один бухаю, между прочим", "лампочка без тебя не горит так же"]),
        (2, ["два дня, бро. ты живой вообще?", "я уже с ботинком разговариваю", "ты меня бросил?"]),
        (4, ["я начинаю обижаться", "ботинок спрашивает, где ты", "я уже и граффити твои обратно не отмою"]),
        (7, ["неделя, сука. я всё запомнил", "ладно, я не обижаюсь. почти. заходи"])
    ]

    static func askPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func schedule() {
        cancel()
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            for (i, step) in plan.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = "Бульк"
                content.body = step.texts.randomElement() ?? ""
                content.sound = .default
                let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: awakeTime(step.days))
                let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
                center.add(UNNotificationRequest(identifier: ids[i], content: content, trigger: trigger))
            }
        }
    }

    // через столько-то дней в то же время, но не ночью и не рано утром
    private static func awakeTime(_ days: Int) -> Date {
        let cal = Calendar.current
        let date = Date().addingTimeInterval(Double(days) * 86400)
        let hour = cal.component(.hour, from: date)
        if hour < 11 { return cal.date(bySettingHour: 13, minute: 0, second: 0, of: date) ?? date }
        if hour >= 22 { return cal.date(bySettingHour: 20, minute: 0, second: 0, of: date) ?? date }
        return date
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
