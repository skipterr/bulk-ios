import Foundation

enum Eyes: String, Codable { case open, closed, happy, wide, angry, dizzy, drunk }
enum Mouth: String, Codable { case smile, grin, o, wide, flat, frown, wavy }
enum Arms: String, Codable { case rest, up, wave, waveLow, hold, drink }
enum Prop: String, Codable { case none, bottle, bulb, mug }

// Всё, чем Бульк может быть занят. Одно действие = одна сценка в виджете.
enum BulkAction: String, Codable, CaseIterable {
    case chill, wave, sleep, burp, swear, drink, unscrew, inDark, screwBack, fixLight, kick, dance, stare, poked, mad, scared
    case yawn, lookAround, sitDown, coffee, fly

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
        case .yawn: return "зевает"
        case .lookAround: return "осматривается"
        case .sitDown: return "присел отдохнуть"
        case .coffee: return "пьёт кофе"
        case .fly: return "гоняет муху"
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
        case .yawn: return ["аааах...", "спать охота", ""]
        case .lookAround: return ["", "чё там?", "хм", "кто тут?"]
        case .sitDown: return ["", "ноги гудят", "кайф", "посижу"]
        case .coffee: return ["кофеёк...", "без кофе не человек", "бодрит"]
        case .fly: return ["бзззз...", "ах ты ж сука!", "муха, бля!"]
        }
    }

    var eyes: Eyes {
        switch self {
        case .chill, .unscrew, .screwBack, .poked: return .open
        case .wave, .inDark, .kick, .dance: return .happy
        case .sleep, .burp, .drink: return .closed
        case .swear, .mad: return .angry
        case .fixLight, .stare, .scared, .fly: return .wide
        case .lookAround: return .open
        case .yawn, .coffee: return .closed
        case .sitDown: return .happy
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
        case .lookAround: return .flat
        case .yawn: return .wide
        case .coffee, .fly: return .o
        case .sitDown: return .smile
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

struct Reminder: Codable, Equatable {
    var text: String
    var at: Date
}

struct BulkState: Codable {
    var action: BulkAction = .wave
    var phrase: String = "я Бульк!"
    // .distantPast — чтобы после установки Бульк сразу жил сам, а не «здоровался» по твоей команде
    var since: Date = .distantPast
    var lightOn: Bool = true
    var tipsy: Double = 0
    var tipsyAt: Date = .now
    var pokes: Int = 0
    var lastPoke: Date = .distantPast
    var x: Double = 0.42
    var shoeX: Double = 0.12
    var reminders: [Reminder] = []

    /// Напоминание, которое Бульк показывает на виджете с момента «at» ещё полчаса.
    func reminder(at date: Date) -> Reminder? {
        reminders.first { date >= $0.at && date < $0.at.addingTimeInterval(30 * 60) }
    }

    /// Ближайший план в следующие сутки (для строчки внизу виджета и «скоро»).
    func nextReminder(after date: Date) -> Reminder? {
        reminders.filter { $0.at > date && $0.at < date.addingTimeInterval(24 * 3600) }.min { $0.at < $1.at }
    }

    // Хмель выветривается примерно за полчаса.
    func tipsyNow(_ date: Date = .now) -> Double {
        max(0, tipsy - date.timeIntervalSince(tipsyAt) / 1800)
    }

    /// true — действие пришло от тебя из приложения (виджет его ненадолго повторяет)
    var byUser = false
    /// кто записал состояние: "app" или "widget" (для диагностики связи)
    var writer = ""

    mutating func set(_ a: BulkAction, at date: Date, byUser: Bool = false) {
        self.byUser = byUser
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

    /// Диагностика: по каким каналам видно состояние, записанное приложением.
    static var appSeenVia: [String] = []

    // Берём самое свежее состояние из своей памяти и из общих каналов (буфер, связка ключей);
    // напоминания собираем из всех.
    static func load() -> BulkState {
        let decoder = JSONDecoder()
        let sources: [(String, Data?)] = [
            ("своё", SharedGroup.defaults.data(forKey: key)),
            ("буфер", SharedBridge.read()),
            ("связка", SharedKeychain.read())
        ]
        var states: [BulkState] = []
        appSeenVia = []
        for (name, data) in sources {
            guard let data, let s = try? decoder.decode(BulkState.self, from: data) else { continue }
            states.append(s)
            if s.writer == "app" { appSeenVia.append(name) }
        }
        guard var newest = states.max(by: { $0.since < $1.since }) else { return BulkState() }
        for s in states {
            for r in s.reminders where !newest.reminders.contains(r) { newest.reminders.append(r) }
        }
        return newest
    }

    static func save(_ state: BulkState, writer: String) {
        var s = state
        s.writer = writer
        if let data = try? JSONEncoder().encode(s) {
            SharedGroup.defaults.set(data, forKey: key)
            SharedBridge.write(data)
            SharedKeychain.write(data)
        }
    }
}

enum BulkBrain {
    // Сам решает, чем заняться дальше. Живёт по времени суток:
    // ночью в основном спит, утром кофе и зевота, в пятницу вечером пьёт и танцует, в понедельник утром бурчит.
    static func next(after a: BulkAction, lightOn: Bool, at date: Date = .now) -> BulkAction {
        switch a {
        case .unscrew: return .inDark
        case .inDark: return .screwBack
        default: break
        }
        if !lightOn { return .fixLight }
        var w: [BulkAction: Double] = [
            .chill: 2, .lookAround: 1.6, .sitDown: 1, .yawn: 0.6, .wave: 0.8, .sleep: 0.8, .burp: 0.8,
            .swear: 0.8, .drink: 0.8, .unscrew: 0.8, .kick: 1, .dance: 0.8, .stare: 0.8, .fly: 0.6
        ]
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let weekday = cal.component(.weekday, from: date) // 1 — воскресенье, 2 — понедельник, 6 — пятница
        switch hour {
        case 0..<7:
            w[.sleep] = 8; w[.yawn] = 1.5; w[.dance] = 0.2; w[.kick] = 0.3
        case 7..<11:
            w[.coffee] = 2.5; w[.yawn] = 2; w[.sleep] = 0.3
            if weekday == 2 { w[.swear] = 2.5 }
        case 22..<24:
            w[.sleep] = 3; w[.yawn] = 2
        default:
            break
        }
        if weekday == 6 && hour >= 18 || weekday == 7 && hour < 3 {
            w[.drink] = 3; w[.dance] = 2.5; w[.burp] = 1.5
        }
        let options = w.filter { $0.key != a }.map { ($0.key, $0.value) }
        let total = options.reduce(0) { $0 + $1.1 }
        var r = Double.random(in: 0..<total)
        for (action, weight) in options {
            r -= weight
            if r <= 0 { return action }
        }
        return .chill
    }
}
