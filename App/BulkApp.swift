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
// с плавной анимацией, тычками, броском и кнопками.
struct ContentView: View {
    var body: some View {
        BulkWebView()
            .ignoresSafeArea()
            .background(Color(white: 0.11))
            .preferredColorScheme(.dark)
    }
}

struct BulkWebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "bulk")
        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = UIColor(white: 0.11, alpha: 1)
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        if let url = Bundle.main.url(forResource: "bulk", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // Что ты сделал с Бульком в приложении — сразу уходит в виджет.
    final class Coordinator: NSObject, WKScriptMessageHandler {
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
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
    }
}
