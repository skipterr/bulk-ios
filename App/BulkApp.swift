import SwiftUI
import Combine

@main
struct BulkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Приложение нужно в основном как «дом» для виджета, а тут — превью Булька.
struct ContentView: View {
    @State private var action: BulkAction = .wave
    @State private var phrase = "я Бульк!"
    @State private var light = true
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Бульк")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            BulkScene(action: action, phrase: phrase, lightOn: light, tipsy: 0)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            Text("Добавь виджет: зажми пустое место на экране «Домой» → «+» → Бульк.")
                .font(.system(size: 15, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.055, green: 0.055, blue: 0.07))
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            withAnimation(.spring(duration: 0.5)) {
                let next = BulkBrain.next(after: action, lightOn: light)
                light = next.lightAfter(light)
                action = next
                phrase = next.phrases.randomElement() ?? ""
            }
        }
    }
}
