import Foundation

enum Eyes: String, Codable { case open, closed, happy, wide, angry, dizzy, drunk }
enum Mouth: String, Codable { case smile, grin, o, wide, flat, frown, wavy }
enum Arms: String, Codable { case rest, up, wave, waveLow, hold, drink }
enum Prop: String, Codable { case none, bottle, bulb, mug, gamepad, book, spray }

// Всё, чем Бульк может быть занят. Одно действие = одна сценка в виджете.
enum BulkAction: String, Codable, CaseIterable {
    case chill, wave, sleep, burp, swear, drink, unscrew, inDark, screwBack, fixLight, kick, dance, stare, poked, mad, scared
    case yawn, lookAround, sitDown, coffee, fly
    case sulk, missYou, cheer, hug
    case gaming, reading, graffiti

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
        case .sulk: return "обиделся"
        case .missYou: return "скучает"
        case .cheer: return "празднует за тебя"
        case .hug: return "поддерживает тебя"
        case .gaming: return "рубится в приставку"
        case .reading: return "читает (вверх ногами)"
        case .graffiti: return "рисует на стене"
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
        case .sulk: return ["хмф", "не разговариваю", "обиделся", ""]
        case .missYou: return ["ты где?", "скучно без тебя...", "зайди хоть", "ау?"]
        case .cheer: return ["ты лучший!", "празднуем!", "красавчик!", "гордость моя"]
        case .hug: return ["я с тобой", "держись, бро", "всё наладится", "обнимашки"]
        case .gaming: return ["ещё катку", "да кто так играет?!", "изи", "лагает, бля"]
        case .reading: return ["интересно...", "умнею", "хм, глубоко", "ничё не понял"]
        case .graffiti: return ["пш-ш-ш", "искусство!", "я художник", "Бэнкси нервно курит"]
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
        case .sulk: return .angry
        case .missYou: return .drunk
        case .cheer, .hug: return .happy
        case .gaming, .reading: return .open
        case .graffiti: return .happy
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
        case .sulk, .missYou: return .frown
        case .cheer: return .grin
        case .hug: return .smile
        case .gaming: return .flat
        case .reading: return .o
        case .graffiti: return .grin
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

/// Граффити-тег на стене: где (доли ширины/высоты стены), что написано, каким цветом и с каким наклоном.
struct WallTag: Codable, Equatable {
    var text: String
    var x: Double
    var y: Double
    var color: Int
    var tilt: Double
    var createdAt: Date
    /// Высота над полом в ростах Булька (граффити — на его росте). У старых тегов нет — считаем из y.
    var lift: Double? = nil

    var liftNow: Double { lift ?? min(2.4, max(0.7, 2.4 - (y - 0.2) * 3.4)) }
    /// То же для виджета: комната там низкая, поэтому 0,7…2,4 роста сжимаем в 0,45…1,7.
    var widgetLift: Double { 0.45 + (min(2.4, max(0.7, liftNow)) - 0.7) / 1.7 * 1.25 }

    /// Ключ картинки, которую рисует приложение (как tagSeed в bulk.html).
    var imageKey: String {
        var h: UInt32 = 0
        for u in text.uppercased().unicodeScalars { h = h &* 31 &+ u.value }
        return "\(h)_\(abs(color) % 5)"
    }

    static let texts = ["БУЛЬК", "ЙОУ", "ЛАМПА МОЯ", "Б★", "BULK", "НЕ ТЫКАЙ", "ТУТ БЫЛ БУЛЬК", "ЗОЖ — ЛОЖЬ"]

    /// Новый тег в случайном месте стены.
    static func random(at date: Date) -> WallTag {
        WallTag(text: texts.randomElement()!, x: Double.random(in: 0.12...0.88), y: Double.random(in: 0.25...0.6),
                color: Int.random(in: 0..<5), tilt: Double.random(in: -12...12), createdAt: date)
    }
}

/// Подарки для комнаты: что можно подарить Бульку в чате.
enum Gifts {
    static let all = ["poster", "clock", "flag", "tv", "guitar", "cactus", "plant", "radio", "teddy", "ball", "console", "pizza"]
    static let emoji: [String: String] = [
        "poster": "🖼️", "clock": "🕰️", "flag": "🏴‍☠️", "tv": "📺", "guitar": "🎸", "cactus": "🌵",
        "plant": "🪴", "radio": "📻", "teddy": "🧸", "ball": "⚽", "console": "🕹️", "pizza": "🍕"
    ]
    /// Где стоит вещь: доли ширины комнаты; wall — висит на стене (высота — доля стены), иначе стоит на полу.
    static let spot: [String: (x: Double, wall: Double?)] = [
        "poster": (0.16, 0.42), "clock": (0.86, 0.28), "flag": (0.42, 0.3), "tv": (0.9, nil), "guitar": (0.05, nil),
        "cactus": (0.8, nil), "plant": (0.25, nil), "radio": (0.7, nil), "teddy": (0.32, nil), "ball": (0.55, nil),
        "console": (0.95, nil), "pizza": (0.62, nil)
    ]
}

struct Reminder: Codable, Equatable {
    var text: String
    var at: Date
    var id: String = UUID().uuidString   // он же id уведомления — чтобы отменить, если дело уже сделано

    init(text: String, at: Date) {
        self.text = text
        self.at = at
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        at = try c.decode(Date.self, forKey: .at)
        id = (try? c.decodeIfPresent(String.self, forKey: .id)) ?? UUID().uuidString
    }
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
    /// До какого момента Бульк обижен (задолбал тычками).
    var offendedUntil: Date = .distantPast
    /// Когда ты последний раз заходил в приложение (для «ты где?»).
    var lastVisit: Date = .now
    /// Настроение после твоего рассказа о дне: "support" — поддерживает, "cheer" — празднует.
    var mood = ""
    var moodUntil: Date = .distantPast
    /// Граффити на стене (максимум 5) и подарки в комнате.
    var tags: [WallTag] = []
    var gifts: [String] = []

    init() {}

    // Читаем поля по одному: если в сохранённых данных какого-то поля ещё нет (обновление),
    // берём значение по умолчанию, а не сбрасываем всё состояние вместе с напоминаниями.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func get<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        let d = BulkState()
        action = get(.action, d.action)
        phrase = get(.phrase, d.phrase)
        since = get(.since, d.since)
        lightOn = get(.lightOn, d.lightOn)
        tipsy = get(.tipsy, d.tipsy)
        tipsyAt = get(.tipsyAt, d.tipsyAt)
        pokes = get(.pokes, d.pokes)
        lastPoke = get(.lastPoke, d.lastPoke)
        x = get(.x, d.x)
        shoeX = get(.shoeX, d.shoeX)
        reminders = get(.reminders, d.reminders)
        byUser = get(.byUser, d.byUser)
        writer = get(.writer, d.writer)
        offendedUntil = get(.offendedUntil, d.offendedUntil)
        lastVisit = get(.lastVisit, d.lastVisit)
        mood = get(.mood, d.mood)
        moodUntil = get(.moodUntil, d.moodUntil)
        tags = get(.tags, d.tags)
        gifts = get(.gifts, d.gifts)
    }

    func offended(at date: Date) -> Bool { date < offendedUntil }
    func moodNow(at date: Date) -> String { date < moodUntil ? mood : "" }
    /// Не заходил больше двух суток.
    func missing(at date: Date) -> Bool { date.timeIntervalSince(lastVisit) > 48 * 3600 }

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

    /// Диагностика (старое): по каким каналам видно состояние, записанное приложением.
    static var appSeenVia: [String] = []

    // Состояние хранится в одном месте — общей памяти приложения и виджета (App Group, её выдаёт AltStore).
    // Запасные каналы (буфер обмена, связка ключей) убраны: у приложения и виджета они были свои,
    // и виджет мог взять оттуда устаревшую копию — терялись граффити, «воскресали» напоминания.
    static func load() -> BulkState {
        guard let data = SharedGroup.defaults.data(forKey: key),
              let s = try? JSONDecoder().decode(BulkState.self, from: data) else { return BulkState() }
        return s
    }

    static func save(_ state: BulkState, writer: String) {
        var s = state
        s.writer = writer
        if let data = try? JSONEncoder().encode(s) {
            SharedGroup.defaults.set(data, forKey: key)
        }
    }
}
enum BulkBrain {
    // Сам решает, чем заняться дальше. Живёт по времени суток:
    // ночью в основном спит, утром кофе и зевота, в пятницу вечером пьёт и танцует, в понедельник утром бурчит.
    static func next(after a: BulkAction, lightOn: Bool, at date: Date = .now,
                     offended: Bool = false, missing: Bool = false, mood: String = "") -> BulkAction {
        switch a {
        case .unscrew: return .inDark
        case .inDark: return .screwBack
        default: break
        }
        if !lightOn { return .fixLight }
        // обижен — сидит спиной, пока не отойдёт
        if offended { return .sulk }
        // твой день: празднует или поддерживает (вперемешку с обычными делами)
        if mood == "cheer" && Double.random(in: 0...1) < 0.55 { return [.cheer, .dance, .drink].randomElement()! }
        if mood == "support" && Double.random(in: 0...1) < 0.55 { return [.hug, .hug, .sitDown].randomElement()! }
        // давно не заходил — скучает
        if missing && Double.random(in: 0...1) < 0.5 { return .missYou }
        var w: [BulkAction: Double] = [
            .chill: 2, .lookAround: 1.6, .sitDown: 1, .yawn: 0.6, .wave: 0.8, .sleep: 0.8, .burp: 0.8,
            .swear: 0.8, .drink: 0.8, .unscrew: 0.08, .kick: 1, .dance: 0.8, .stare: 0.8, .fly: 0.6,
            .gaming: 0.7, .reading: 0.6, .graffiti: 0.35
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
        case 18..<22:
            w[.gaming] = 1.6
        case 22..<24:
            w[.sleep] = 3; w[.yawn] = 2; w[.gaming] = 1
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
