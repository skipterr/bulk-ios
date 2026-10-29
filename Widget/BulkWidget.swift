import WidgetKit
import SwiftUI
import AppIntents

struct BulkEntry: TimelineEntry {
    let date: Date
    let frame: BulkFrame
    let phrase: String
    let tipsy: Double
}

struct BulkProvider: TimelineProvider {
    func placeholder(in context: Context) -> BulkEntry {
        BulkEntry(date: .now, frame: BulkFrame(action: .wave, x: 0.42, pose: FramePose(arms: .wave), light: true, shoeX: 0.12),
                  phrase: "я Бульк!", tipsy: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (BulkEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BulkEntry>) -> Void) {
        completion(Timeline(entries: Self.makeEntries(now: .now), policy: .atEnd))
    }

    // План на ближайшие полчаса: каждые 2 секунды следующий кадр сценария,
    // iOS плавно перетекает между ними. Занятия идут одно за другим без телепортов.
    static let frameStep: TimeInterval = 2

    static func makeEntries(now: Date) -> [BulkEntry] {
        var s = BulkStore.load()
        let fresh = now.timeIntervalSince(s.since) < 60
        if !fresh {
            s.set(BulkBrain.next(after: s.action, lightOn: s.lightOn), at: now)
        }
        var action = s.action
        var phrase = s.phrase
        var light = s.lightOn
        var x = s.x
        var shoe = s.shoeX
        var tipsy = s.tipsyNow(now)
        var t = now
        let end = now.addingTimeInterval(30 * 60)
        var entries: [BulkEntry] = []
        while t < end {
            let frames = BulkScript.frames(for: action, x: x, shoeX: shoe, light: light)
            for (i, f) in frames.enumerated() {
                entries.append(BulkEntry(date: t, frame: f, phrase: i < 2 ? phrase : "", tipsy: tipsy))
                t = t.addingTimeInterval(frameStep)
            }
            if let last = frames.last {
                x = last.x
                shoe = last.shoeX
                light = last.light
            }
            action = BulkBrain.next(after: action, lightOn: light)
            phrase = action.phrases.randomElement() ?? ""
            tipsy = action == .drink ? min(1.6, tipsy + 0.6) : max(0, tipsy - 0.05)
        }
        // Запоминаем, где Бульк окажется, чтобы следующий план продолжился оттуда же.
        s.x = x
        s.shoeX = shoe
        BulkStore.save(s)
        return entries
    }
}

struct BulkWidgetView: View {
    let entry: BulkEntry

    // Без кнопок: на виджете Бульк просто живёт. Тап открывает приложение.
    var body: some View {
        BulkScene(frame: entry.frame, phrase: entry.phrase, tipsy: entry.tipsy)
            .animation(.spring(duration: 1.0, bounce: 0.25), value: entry.date)
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

@main
struct BulkWidgetBundle: WidgetBundle {
    var body: some Widget {
        BulkWidget()
    }
}
