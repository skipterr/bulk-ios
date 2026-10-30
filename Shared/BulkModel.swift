import Foundation

enum Eyes: String, Codable { case open, closed, happy, wide, angry, dizzy, drunk }
enum Mouth: String, Codable { case smile, grin, o, wide, flat, frown, wavy }
enum Arms: String, Codable { case rest, up, wave, waveLow, hold, drink }
enum Prop: String, Codable { case none, bottle, bulb }

// Всё, чем Бульк может быть занят. Одно действие = одна сценка в виджете.
enum BulkAction: String, Codable, CaseIterable {
    case chill, wave, sleep, burp, swear, drink, unscrew, inDark, screwBack, fixLight, kick, dance, stare, poked, mad, scared

    var status: String {
        switch self {
        case .chill: return "залипает"
        case .wave: return "здоровается"
        case .sleep: return "спит"
        case .burp: return "рыгает"
        case .swear: return "ругается"
        case .drink: return "выпивает"
        case .unscrew: return "ворует лампочку"
        case .inDark: return "сидит в темноте"
        case .screwBack: return "вкручивает обратно"
        case .fixLight: return "включает свет"
        case .kick: return "пинает ботинок"
        case .dance: return "танцует"
        case .stare: return "пялится на тебя"
        case .poked: return "возмущается"
        case .mad: return "злой"
        case .scared: return "боится темноты"
        }
    }

    var phrases: [String] {
        switch self {
        case .chill: return ["", "хм", "скучно", "...", "ну и денёк"]
        case .wave: return ["привет!", "о, ты тут", "йоу", "я Бульк!"]
        case .sleep: return ["zzz", "хррр...", "zzZZ"]
        case .burp: return ["БУЭЭЭЭ", "пардон", "ыыыгх"]
        case .swear: return ["да бля!", "ёб твою мать...", "пиздец!", "сука!", "ну нахер!"]
        case .drink: return ["за здоровье!", "буль-буль", "по чуть-чуть"]
        case .unscrew: return ["хе-хе", "скрип-скрип"]
        case .inDark: return ["свет для слабаков", "сюрприз!", "моя лампочка"]
        case .screwBack: return ["ладно, ладно", "да будет свет!"]
        case .fixLight: return ["кто выключил?!", "так-то лучше"]
        case .kick: return ["ГОЛ!", "лети!", "на!"]
        case .dance: return ["♪ ♫", "туц-туц", "♫"]
        case .stare: return ["чё смотришь?", "а ты кто?", "мне б зарплату"]
        case .poked: return ["эй!", "щекотно!", "хи-хи", "ну чё?"]
        case .mad: return ["ДА ОТСТАНЬ!", "ну всё, бля!", "щас укушу!"]
        case .scared: return ["эй! кто выключил?", "мне страшно...", "мама..."]
        }
    }

    var eyes: Eyes {
        switch self {
        case .chill, .unscrew, .screwBack, .poked: return .open
        case .wave, .inDark, .kick, .dance: return .happy
        case .sleep, .burp, .drink: return .closed
        case .swear, .mad: return .angry
        case .fixLight, .stare, .scared: return .wide
        }
    }

    var mouth: Mouth {
        switch self {
        case .chill: return .flat
        case .wave, .unscrew, .inDark, .kick, .dance: return .grin
        case .sleep, .drink, .poked: return .o
        case .burp, .swear: return .wide
        case .screwBack, .fixLight, .stare: return .flat
        case .mad, .scared: return .frown
        }
    }

    // Что станет со светом после этого действия.
    func lightAfter(_ light: Bool) -> Bool {
        switch self {
        case .unscrew, .screwBack, .fixLight: return true
        case .inDark, .scared: return false
        default: return light
        }
    }
}

struct BulkState: Codable {
    var action: BulkAction = .wave
    var phrase: String = "я Бульк!"
    var since: Date = .now
    var lightOn: Bool = true
    var tipsy: Double = 0
    var tipsyAt: Date = .now
    var pokes: Int = 0
    var lastPoke: Date = .distantPast
    var x: Double = 0.42
    var shoeX: Double = 0.12

    // Хмель выветривается примерно за полчаса.
    func tipsyNow(_ date: Date = .now) -> Double {
        max(0, tipsy - date.timeIntervalSince(tipsyAt) / 1800)
    }

    mutating func set(_ a: BulkAction, at date: Date) {
        action = a
        phrase = a.phrases.randomElement() ?? ""
        since = date
        lightOn = a.lightAfter(lightOn)
        if a == .drink {
            tipsy = min(1.6, tipsyNow(date) + 0.6)
            tipsyAt = date
        }
    }
}

enum BulkStore {
    private static let key = "bulk.state.v1"

    // Берём самое свежее состояние: из своей памяти или из общего буфера (там его оставляет приложение).
    static func load() -> BulkState {
        let decoder = JSONDecoder()
        let own = SharedGroup.defaults.data(forKey: key).flatMap { try? decoder.decode(BulkState.self, from: $0) }
        let shared = SharedBridge.read().flatMap { try? decoder.decode(BulkState.self, from: $0) }
        switch (own, shared) {
        case let (a?, b?): return b.since > a.since ? b : a
        case let (a?, nil): return a
        case let (nil, b?): return b
        default: return BulkState()
        }
    }

    static func save(_ state: BulkState) {
        if let data = try? JSONEncoder().encode(state) {
            SharedGroup.defaults.set(data, forKey: key)
            SharedBridge.write(data)
        }
    }
}

enum BulkBrain {
    // Сам решает, чем заняться дальше.
    static func next(after a: BulkAction, lightOn: Bool) -> BulkAction {
        switch a {
        case .unscrew: return .inDark
        case .inDark: return .screwBack
        default: break
        }
        if !lightOn { return .fixLight }
        let pool: [(BulkAction, Double)] = [
            (.chill, 3), (.wave, 1), (.sleep, 1.2), (.burp, 1), (.swear, 1),
            (.drink, 1), (.unscrew, 1), (.kick, 1.2), (.dance, 1), (.stare, 1)
        ]
        let options = pool.filter { $0.0 != a }
        let total = options.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        for (action, weight) in options {
            r -= weight
            if r <= 0 { return action }
        }
        return .chill
    }
}
