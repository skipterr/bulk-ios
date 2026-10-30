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

    // План на ближайшие 12 минут: каждые 1,5 секунды следующий кадр сценария,
    // iOS плавно перетекает между ними. Занятия идут одно за другим без телепортов.
    // Больше ~600 кадров iOS не успевает построить — виджет становится серой заглушкой.
    static let frameStep: TimeInterval = 1.5

    static func makeEntries(now: Date) -> [BulkEntry] {
        var s = BulkStore.load()
        // Что ты сделал в приложении, Бульк на виджете повторяет ещё раз-другой (до ~40 с).
        let userHold: TimeInterval = 40
        let fresh = s.byUser && now.timeIntervalSince(s.since) < userHold
        if !fresh {
            s.set(BulkBrain.next(after: s.action, lightOn: s.lightOn, at: now), at: now)
        }
        var action = s.action
        var phrase = s.phrase
        var light = s.lightOn
        var x = s.x
        var shoe = s.shoeX
        var tipsy = s.tipsyNow(now)
        var t = now
        let end = now.addingTimeInterval(12 * 60)
        var entries: [BulkEntry] = []
        var first = true
        while t < end {
            // твоё действие повторяется максимум дважды
            let repeatUntil = first && fresh ? s.since.addingTimeInterval(userHold) : t
            var plays = 0
            repeat {
                plays += 1
                let frames = BulkScript.frames(for: action, x: x, shoeX: shoe, light: light)
                for (i, f) in frames.enumerated() {
                    // пришло время напоминания — Бульк держит табличку 🔔
                    let shown = s.reminder(at: t).map { "🔔 " + $0.text } ?? (i < 2 ? phrase : "")
                    entries.append(BulkEntry(date: t, frame: f, phrase: shown, tipsy: tipsy))
                    t = t.addingTimeInterval(frameStep)
                }
                if let last = frames.last {
                    x = last.x
                    shoe = last.shoeX
                    light = last.light
                }
            } while plays < 2 && t < repeatUntil && t < end
            first = false
            action = BulkBrain.next(after: action, lightOn: light, at: t)
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
        BulkScene(frame: entry.frame, phrase: entry.phrase, tipsy: entry.tipsy, clock: entry.date.timeIntervalSince1970)
            .animation(.spring(duration: 0.7, bounce: 0.25), value: entry.date)
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
