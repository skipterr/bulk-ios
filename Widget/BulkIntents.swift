import AppIntents
import WidgetKit

// Кнопки на виджете. После каждой iOS сама перерисовывает виджет.

struct PokeIntent: AppIntent {
    static let title: LocalizedStringResource = "Тыкнуть Булька"

    func perform() async throws -> some IntentResult {
        var s = BulkStore.load()
        let now = Date()
        s.pokes = now.timeIntervalSince(s.lastPoke) < 90 ? s.pokes + 1 : 1
        s.lastPoke = now
        if s.pokes >= 4 {
            s.pokes = 0
            s.set(.mad, at: now)
        } else {
            s.set(.poked, at: now)
        }
        BulkStore.save(s)
        return .result()
    }
}

struct DrinkIntent: AppIntent {
    static let title: LocalizedStringResource = "Налить Бульку"

    func perform() async throws -> some IntentResult {
        var s = BulkStore.load()
        s.set(.drink, at: Date())
        BulkStore.save(s)
        return .result()
    }
}

struct LightIntent: AppIntent {
    static let title: LocalizedStringResource = "Свет"

    func perform() async throws -> some IntentResult {
        var s = BulkStore.load()
        let now = Date()
        if s.lightOn {
            s.set(.scared, at: now)
        } else {
            s.set(.chill, at: now)
            s.lightOn = true
            s.phrase = "о, свет!"
        }
        BulkStore.save(s)
        return .result()
    }
}

struct KickIntent: AppIntent {
    static let title: LocalizedStringResource = "Пнуть ботинок"

    func perform() async throws -> some IntentResult {
        var s = BulkStore.load()
        s.set(.kick, at: Date())
        BulkStore.save(s)
        return .result()
    }
}
