import SwiftUI
import WebKit
import WidgetKit
import UserNotifications

@main
struct BulkApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// В приложении Бульк полностью живой: внутри та же комната, что в веб-версии,
// с плавной анимацией, тычками, броском, кнопками и чатом.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        BulkWebView()
            .ignoresSafeArea()
            .background(Color(white: 0.11))
            .preferredColorScheme(.dark)
            // каждый раз, когда открываешь Булька (и после фона тоже), он отмечает, что ты заходил
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                var s = BulkStore.load()
                s.lastVisit = Date()
                BulkStore.save(s, writer: "app")
                WidgetCenter.shared.reloadAllTimelines()
            }
    }
}

/// Строка Swift → строковый литерал JavaScript (с экранированием).
func jsString(_ s: String) -> String {
    guard let data = try? JSONEncoder().encode(s), let lit = String(data: data, encoding: .utf8) else { return "\"\"" }
    return lit
}

struct BulkWebView: UIViewRepresentable {
    static let keyDefaultsKey = "geminiKey"

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "bulk")

        // Сохранённый ключ Gemini отдаём странице до её запуска.
        let key = UserDefaults.standard.string(forKey: Self.keyDefaultsKey) ?? KeyVault.load() ?? ""
        if !key.isEmpty { KeyVault.save(key) }
        // и память Булька о тебе (переписка + факты), если она есть
        let memory = KeyVault.load(account: "memory") ?? ""
        // и настроение Булька: обижен ли, давно ли ты заходил, празднует/поддерживает ли
        var s = BulkStore.load()
        let now = Date()
        // подарки и граффити — чтобы в комнате приложения было то же, что на виджете
        let gifts = (try? JSONEncoder().encode(s.gifts)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let tags = (try? JSONEncoder().encode(s.tags.map { ["text": $0.text, "x": String($0.x), "y": String($0.y), "color": String($0.color), "tilt": String($0.tilt)] }))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        let mood = "{\"offendedUntil\":\(Int(s.offendedUntil.timeIntervalSince1970 * 1000)),\"awayHours\":\(Int(now.timeIntervalSince(s.lastVisit) / 3600)),\"mood\":\(jsString(s.moodNow(at: now))),\"gifts\":\(gifts),\"tags\":\(tags)}"
        s.lastVisit = now
        BulkStore.save(s, writer: "app")
        WidgetCenter.shared.reloadAllTimelines()
        config.userContentController.addUserScript(WKUserScript(
            source: "window.__geminiKey = \(jsString(key)); window.__bulkMemory = \(jsString(memory)); window.__bulkMood = \(mood);",
            injectionTime: .atDocumentStart, forMainFrameOnly: true))

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(white: 0.11, alpha: 1)
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        context.coordinator.webView = web
        if let url = Bundle.main.url(forResource: "bulk", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        // Как только страница создала поле ввода — убираем панель «‹ › Done» над клавиатурой.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { web.hideInputAccessoryBar() }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKScriptMessageHandler {
        weak var webView: WKWebView?

        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            if let dict = message.body as? [String: Any], let type = dict["type"] as? String {
                switch type {
                case "saveKey":
                    if let key = dict["key"] as? String {
                        UserDefaults.standard.set(key, forKey: BulkWebView.keyDefaultsKey)
                        KeyVault.save(key)
                    }
                case "fetch":
                    fetch(dict)
                case "saveMemory":
                    if let json = dict["json"] as? String { KeyVault.save(json, account: "memory") }
                case "reminderDone":
                    Reminders.markDone(hint: dict["hint"] as? String ?? "")
                case "forgive":
                    var s = BulkStore.load()
                    s.offendedUntil = .distantPast
                    s.set(.wave, at: Date(), byUser: true)
                    s.phrase = "ладно, мир"
                    BulkStore.save(s, writer: "app")
                    WidgetCenter.shared.reloadAllTimelines()
                case "mood":
                    // твой день: support — поддерживает, cheer — празднует (несколько часов)
                    guard let mood = dict["mood"] as? String, ["support", "cheer"].contains(mood) else { return }
                    let hours = (dict["hours"] as? Double) ?? 6
                    var s = BulkStore.load()
                    s.mood = mood
                    s.moodUntil = Date().addingTimeInterval(hours * 3600)
                    s.set(mood == "cheer" ? .cheer : .hug, at: Date(), byUser: true)
                    BulkStore.save(s, writer: "app")
                    WidgetCenter.shared.reloadAllTimelines()
                case "gift":
                    // подарок из чата навсегда появляется в комнате
                    guard let gift = dict["gift"] as? String, Gifts.all.contains(gift) else { return }
                    var s = BulkStore.load()
                    if !s.gifts.contains(gift) { s.gifts.append(gift) }
                    s.set(.cheer, at: Date(), byUser: true)
                    s.phrase = "спасибо за подарок!"
                    BulkStore.save(s, writer: "app")
                    WidgetCenter.shared.reloadAllTimelines()
                case "tag":
                    // граффити, нарисованное в приложении, появляется и на виджете
                    guard let text = dict["text"] as? String else { return }
                    var s = BulkStore.load()
                    s.tags.append(WallTag(text: text, x: (dict["x"] as? Double) ?? 0.5, y: (dict["y"] as? Double) ?? 0.4,
                                          color: (dict["color"] as? Int) ?? 0, tilt: (dict["tilt"] as? Double) ?? 0, createdAt: Date()))
                    if s.tags.count > 5 { s.tags.removeFirst(s.tags.count - 5) }
                    BulkStore.save(s, writer: "app")
                    WidgetCenter.shared.reloadAllTimelines()
                case "untag":
                    // Бульк оттёр граффити губкой — и с виджета оно пропадает
                    guard let text = dict["text"] as? String else { return }
                    var s = BulkStore.load()
                    if let i = s.tags.firstIndex(where: { $0.text == text }) { s.tags.remove(at: i) }
                    BulkStore.save(s, writer: "app")
                    WidgetCenter.shared.reloadAllTimelines()
                case "remind":
                    if let text = dict["text"] as? String, let at = dict["at"] as? String {
                        Reminders.add(text: text, at: at)
                    }
                default:
                    break
                }
                return
            }
            // Что ты сделал с Бульком в приложении — сразу уходит в виджет.
            guard let name = message.body as? String, let action = BulkAction(rawValue: name) else { return }
            var s = BulkStore.load()
            s.set(action, at: Date(), byUser: true)
            if action == .sulk { s.offendedUntil = Date().addingTimeInterval(20 * 60) }
            if action == .chill {
                s.lightOn = true
                s.phrase = "о, свет!"
            }
            BulkStore.save(s, writer: "app")
            WidgetCenter.shared.reloadAllTimelines()
        }

        // Запрос к Gemini делаем из приложения и возвращаем ответ странице.
        private func fetch(_ dict: [String: Any]) {
            guard let id = dict["id"] as? Int,
                  let urlString = dict["url"] as? String, let url = URL(string: urlString),
                  let body = dict["body"] as? String else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let key = dict["key"] as? String, !key.isEmpty {
                req.setValue(key, forHTTPHeaderField: "x-goog-api-key")
            }
            req.httpBody = Data(body.utf8)
            req.timeoutInterval = 8
            URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? (error?.localizedDescription ?? "нет ответа")
                let js = "window.__fetchDone(\(id), \(status), \(jsString(text)))"
                DispatchQueue.main.async { self?.webView?.evaluateJavaScript(js) }
            }.resume()
        }
    }
}
