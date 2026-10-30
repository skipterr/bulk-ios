import SwiftUI
import WebKit
import WidgetKit

@main
struct BulkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// В приложении Бульк полностью живой: внутри та же комната, что в веб-версии,
// с плавной анимацией, тычками, броском, кнопками и чатом.
struct ContentView: View {
    var body: some View {
        BulkWebView()
            .ignoresSafeArea()
            .background(Color(white: 0.11))
            .preferredColorScheme(.dark)
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
        let key = UserDefaults.standard.string(forKey: Self.keyDefaultsKey) ?? ""
        config.userContentController.addUserScript(WKUserScript(
            source: "window.__geminiKey = \(jsString(key));", injectionTime: .atDocumentStart, forMainFrameOnly: true))

        // ВРЕМЕННО: строчка-диагностика общей памяти с виджетом
        let group = SharedGroup.id ?? "нет"
        let debug = "группа: \(group) · связь: \(SharedGroup.isShared ? "да" : "нет")"
        let script = """
        document.addEventListener('DOMContentLoaded', () => {
          const d = document.createElement('div');
          d.textContent = \(jsString(debug));
          d.style.cssText = 'position:absolute;top:calc(40px + env(safe-area-inset-top,0px));left:16px;right:16px;font:11px -apple-system;color:#9a9aa3;pointer-events:none';
          document.body.appendChild(d);
        });
        """
        config.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true))

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
                    }
                case "fetch":
                    fetch(dict)
                default:
                    break
                }
                return
            }
            // Что ты сделал с Бульком в приложении — сразу уходит в виджет.
            guard let name = message.body as? String, let action = BulkAction(rawValue: name) else { return }
            var s = BulkStore.load()
            s.set(action, at: Date())
            if action == .chill {
                s.lightOn = true
                s.phrase = "о, свет!"
            }
            BulkStore.save(s)
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
            req.httpBody = Data(body.utf8)
            req.timeoutInterval = 30
            URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                let text = data.flatMap { String(data: $0, encoding: .utf8) } ?? (error?.localizedDescription ?? "нет ответа")
                let js = "window.__fetchDone(\(id), \(status), \(jsString(text)))"
                DispatchQueue.main.async { self?.webView?.evaluateJavaScript(js) }
            }.resume()
        }
    }
}
