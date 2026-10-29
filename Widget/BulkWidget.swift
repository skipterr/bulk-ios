import WidgetKit
import SwiftUI

struct BulkEntry: TimelineEntry {
    let date: Date
    let action: BulkAction
    let phrase: String
    let lightOn: Bool
    let tipsy: Double
}

struct BulkProvider: TimelineProvider {
    func placeholder(in context: Context) -> BulkEntry {
        BulkEntry(date: .now, action: .wave, phrase: "я Бульк!", lightOn: true, tipsy: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (BulkEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BulkEntry>) -> Void) {
        completion(Timeline(entries: Self.makeEntries(now: .now), policy: .atEnd))
    }

    // План на ближайший час: каждые 4–7 минут Бульк сам меняет занятие.
    static func makeEntries(now: Date) -> [BulkEntry] {
        var s = BulkStore.load()
        let fresh = now.timeIntervalSince(s.since) < 150
        if !fresh {
            s.set(BulkBrain.next(after: s.action, lightOn: s.lightOn), at: now)
            BulkStore.save(s)
        }
        var action = s.action
        var phrase = s.phrase
        var light = s.lightOn
        var tipsy = s.tipsyNow(now)
        var t = now
        var entries: [BulkEntry] = []
        for i in 0..<12 {
            entries.append(BulkEntry(date: t, action: action, phrase: phrase, lightOn: light, tipsy: tipsy))
            t = t.addingTimeInterval(i == 0 && fresh ? 90 : Double.random(in: 240...420))
            action = BulkBrain.next(after: action, lightOn: light)
            phrase = action.phrases.randomElement() ?? ""
            light = action.lightAfter(light)
            tipsy = action == .drink ? min(1.6, tipsy + 0.6) : max(0, tipsy - 0.15)
        }
        return entries
    }
}

struct BulkWidgetView: View {
    let entry: BulkEntry

    var body: some View {
        HStack(spacing: 0) {
            BulkScene(action: entry.action, phrase: entry.phrase, lightOn: entry.lightOn, tipsy: entry.tipsy)
                .animation(.spring(duration: 0.6), value: entry.action)
            VStack(spacing: 6) {
                control(PokeIntent(), icon: "hand.point.up.left.fill")
                control(DrinkIntent(), icon: "mug.fill")
                control(LightIntent(), icon: entry.lightOn ? "lightbulb.fill" : "lightbulb")
                control(KickIntent(), icon: "figure.soccer")
            }
            .padding(.horizontal, 8)
        }
    }

    private func control<I: AppIntent>(_ intent: I, icon: String) -> some View {
        Button(intent: intent) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.white.opacity(0.09)))
        }
        .buttonStyle(.plain)
    }
}

struct BulkWidget: Widget {
    let kind = "BulkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BulkProvider()) { entry in
            BulkWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(red: 0.055, green: 0.055, blue: 0.07) }
        }
        .configurationDisplayName("Бульк")
        .description("Живёт своей жизнью. Тыкай, наливай, выключай свет.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

@main
struct BulkWidgetBundle: WidgetBundle {
    var body: some Widget {
        BulkWidget()
    }
}
