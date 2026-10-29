import SwiftUI
import WebKit

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
            .background(Color(red: 0.03, green: 0.03, blue: 0.045))
            .preferredColorScheme(.dark)
            .statusBarHidden(false)
    }
}

struct BulkWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.045, alpha: 1)
        web.scrollView.isScrollEnabled = false
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        if let url = Bundle.main.url(forResource: "bulk", withExtension: "html") {
            web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
