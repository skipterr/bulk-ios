import WidgetKit
import SwiftUI
import AppIntents

struct BulkEntry: TimelineEntry {
    let date: Date
    let action: BulkAction
    let phrase: String
    let lightOn: Bool
    let tipsy: Double
    var frame: Int = 0
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

    // План на ближайшие полчаса: каждые 3 секунды новая поза (iOS плавно перетекает между ними),
    // каждые 30–60 секунд Бульк сам меняет занятие.
    static let frameStep: TimeInterval = 3

    static func makeEntries(now: Date) -> [BulkEntry] {
        var s = BulkStore.load()
        let fresh = now.timeIntervalSince(s.since) < 60
        if !fresh {
            s.set(BulkBrain.next(after: s.action, lightOn: s.lightOn), at: now)
            BulkStore.save(s)
        }
        var action = s.action
        var phrase = s.phrase
        var light = s.lightOn
        var tipsy = s.tipsyNow(now)
        var t = now
        let end = now.addingTimeInterval(30 * 60)
        var entries: [BulkEntry] = []
        while t < end {
            let segment = Double.random(in: 30...60)
            let segmentEnd = t.addingTimeInterval(segment)
            var frame = 0
            while t < segmentEnd {
                entries.append(BulkEntry(date: t, action: action, phrase: frame < 3 ? phrase : "",
                                         lightOn: light, tipsy: tipsy, frame: frame))
                t = t.addingTimeInterval(frameStep)
                frame += 1
            }
            action = BulkBrain.next(after: action, lightOn: light)
            phrase = action.phrases.randomElement() ?? ""
            light = action.lightAfter(light)
            tipsy = action == .drink ? min(1.6, tipsy + 0.6) : max(0, tipsy - 0.05)
        }
        return entries
    }
}

struct BulkWidgetView: View {
    let entry: BulkEntry

    // Без кнопок: на виджете Бульк просто живёт. Тап открывает приложение.
    var body: some View {
        BulkScene(action: entry.action, phrase: entry.phrase, lightOn: entry.lightOn, tipsy: entry.tipsy, frame: entry.frame)
            .animation(.spring(duration: 1.2, bounce: 0.3), value: entry.date)
    }
}

struct BulkWidget: Widget {
    let kind = "BulkWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BulkProvider()) { entry in
            BulkWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(white: 0.16) }
        }
        .configurationDisplayName("Бульк")
        .description("Живёт своей жизнью. Тыкай, наливай, выключай свет.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// Временный виджет для проверки «1 кадр в секунду» и связи с приложением.
struct BulkProbeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BulkProbe", provider: ProbeProvider()) { _ in
            SpriteProbe()
                .containerBackground(for: .widget) { Color(white: 0.16) }
        }
        .configurationDisplayName("Бульк-тест")
        .description("Временная проверка для разработки.")
        .supportedFamilies([.systemMedium])
    }
}

struct ProbeProvider: TimelineProvider {
    struct Entry: TimelineEntry { let date: Date }
    func placeholder(in context: Context) -> Entry { Entry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: .now)], policy: .after(.now.addingTimeInterval(3600))))
    }
}

@main
struct BulkWidgetBundle: WidgetBundle {
    var body: some Widget {
        BulkWidget()
        BulkProbeWidget()
    }
}
