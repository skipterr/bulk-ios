import Foundation

/// Один «кадр» виджета: где Бульк, в какой позе, что в руках, что с лампой и ботинком.
/// Между кадрами iOS плавно перетекает, поэтому Бульк не телепортируется, а идёт, прыгает и падает.
struct BulkFrame {
    var action: BulkAction
    var x: Double                 // доля ширины комнаты
    var lift: Double = 0          // 0 — на полу, 1 — висит на лампе
    var pose = FramePose()
    var holding: Prop = .none
    var light: Bool
    var bulbInLamp = true
    var shoeX: Double
    var shoeAir: Double = 0       // 0 — ботинок на полу, больше — в полёте
    var flyX: Double? = nil       // муха (доли ширины и высоты комнаты), nil — мухи нет
    var flyY: Double = 0.4
}

enum BulkScript {
    static let lampX = 0.68

    /// Сценарий одного занятия, начиная с того места, где Бульк закончил прошлое.
    static func frames(for action: BulkAction, x startX: Double, shoeX startShoe: Double, light startLight: Bool) -> [BulkFrame] {
        var out: [BulkFrame] = []
        var x = startX, shoe = startShoe, light = startLight

        func add(_ p: FramePose = FramePose(), lift: Double = 0, holding: Prop = .none, bulb: Bool = true, shoeAir: Double = 0,
                 fly: (Double, Double)? = nil) {
            var f = BulkFrame(action: action, x: x, lift: lift, pose: p, holding: holding, light: light,
                              bulbInLamp: bulb, shoeX: shoe, shoeAir: shoeAir)
            if let fly { f.flyX = fly.0; f.flyY = fly.1 }
            out.append(f)
        }
        func rnd(_ r: ClosedRange<Double>) -> Double { Double.random(in: r) }
        // Идёт вприпрыжку, шаг за кадр.
        func walk(to target: Double, holding: Prop = .none, bulb: Bool = true) {
            var hop = false
            while abs(target - x) > 0.02 {
                let dir = target > x ? 1.0 : -1.0
                x += dir * min(0.1, abs(target - x))
                hop.toggle()
                add(FramePose(dy: hop ? -5 : 0, tilt: dir * 6), holding: holding, bulb: bulb)
            }
        }
        // Прыжок к лампе и обратно; work — что делает, пока висит.
        func lampTrip(holdingUp: Prop, work: () -> Void, fallHolding: Prop) {
            add(FramePose(sx: 1.15, sy: 0.75), holding: holdingUp, bulb: holdingUp != .bulb)
            add(FramePose(sx: 0.9, sy: 1.12, eyes: .wide, mouth: .o, arms: .up), lift: 0.55, bulb: holdingUp != .bulb)
            work()
            let bulb = fallHolding != .bulb
            add(FramePose(sx: 0.92, sy: 1.1, eyes: .wide, mouth: .o, arms: fallHolding == .bulb ? Arms.hold : Arms.up),
                lift: 0.45, holding: fallHolding, bulb: bulb)
            add(FramePose(sx: 1.2, sy: 0.75, eyes: .closed, mouth: .o, arms: fallHolding == .bulb ? Arms.hold : Arms.rest),
                holding: fallHolding, bulb: bulb)
        }

        switch action {
        case .chill:
            // каждый раз по-разному: дышит, косится по сторонам, моргает невпопад, иногда подпрыгивает
            let n = Int.random(in: 4...7)
            var look = 0.0
            for i in 0..<n {
                if Double.random(in: 0...1) < 0.45 { look = [-1.0, -0.5, 0, 0.5, 1].randomElement()! }
                let blink = Double.random(in: 0...1) < 0.18
                let hop = Double.random(in: 0...1) < 0.12
                add(FramePose(dy: hop ? -6 : 0, tilt: rnd(-3...3), sx: i % 2 == 0 ? 1.02 : 0.98, sy: i % 2 == 0 ? 0.98 : 1.03,
                              eyes: blink ? Eyes.closed : nil, look: look))
            }
        case .yawn:
            add(FramePose(sy: 1.05, eyes: .closed, mouth: .o))
            add(FramePose(sx: 0.95, sy: 1.12, eyes: .closed, mouth: .wide, arms: .up))
            add(FramePose(sx: 0.95, sy: 1.14, eyes: .closed, mouth: .wide, arms: .up))
            add(FramePose(sx: 1.06, sy: 0.94, eyes: .closed, mouth: .o))
            add(FramePose(mouth: .flat))
        case .lookAround:
            for l in [-1.0, -1.0, 0, 1.0, 1.0, 0].shuffled() {
                add(FramePose(tilt: l * 4, look: l))
            }
            add(FramePose(eyes: .closed))
        case .sitDown:
            add(FramePose(sx: 1.12, sy: 0.82))
            for i in 0..<Int.random(in: 3...5) {
                add(FramePose(sx: 1.24, sy: 0.66, eyes: i % 3 == 2 ? Eyes.closed : Eyes.happy, mouth: .smile, look: rnd(-1...1)))
            }
            add(FramePose(dy: -5, sx: 0.95, sy: 1.08))
        case .coffee:
            add(FramePose(arms: .drink), holding: .mug)
            add(FramePose(tilt: -6, eyes: .closed, mouth: .o, arms: .drink), holding: .mug)
            add(FramePose(tilt: -8, eyes: .closed, mouth: .o, arms: .drink), holding: .mug)
            add(FramePose(eyes: .happy, mouth: .smile, arms: .drink), holding: .mug)
            add(FramePose(tilt: -6, eyes: .closed, mouth: .o, arms: .drink), holding: .mug)
            add(FramePose(eyes: .open, mouth: .smile, arms: .drink), holding: .mug)
        case .fly:
            // муха прилетает из ниоткуда, Бульк следит глазами и пытается прихлопнуть
            var fx = x + 0.15, fy = 0.35
            for _ in 0..<4 {
                fx = min(0.95, max(0.05, x + rnd(-0.14...0.14)))
                fy = rnd(0.25...0.55)
                add(FramePose(eyes: .wide, mouth: .o, look: fx > x ? 1 : -1), fly: (fx, fy))
            }
            add(FramePose(dy: -8, eyes: .angry, mouth: .wide, arms: .up), fly: (fx, fy))
            add(FramePose(sx: 1.1, sy: 0.9, eyes: .angry, mouth: .frown), fly: (min(0.95, fx + 0.2), 0.15))
            add(FramePose(eyes: .happy, mouth: .grin))
        case .wave:
            for i in 0..<4 { add(FramePose(tilt: i % 2 == 0 ? 4 : -4, arms: i % 2 == 0 ? Arms.wave : Arms.waveLow)) }
        case .sleep:
            for i in 0..<7 {
                add(FramePose(sx: i % 2 == 0 ? 1.14 : 1.1, sy: i % 2 == 0 ? 0.78 : 0.83, eyes: .closed, mouth: .o))
            }
        case .burp:
            add(FramePose(sx: 1.08, mouth: .o))
            add(FramePose(sx: 1.2, sy: 0.95, eyes: .open, mouth: .o))
            add(FramePose(dy: -6, sx: 0.95, sy: 1.1, eyes: .closed, mouth: .wide))
            add(FramePose(eyes: .happy, mouth: .smile))
        case .swear, .mad:
            for i in 0..<5 {
                add(FramePose(dx: i % 2 == 0 ? 3 : -3, dy: i % 2 == 0 ? -4 : 0, arms: i % 2 == 0 ? Arms.up : Arms.rest))
            }
        case .drink:
            add(FramePose(arms: .drink), holding: .bottle)
            add(FramePose(tilt: -10, eyes: .closed, mouth: .o, arms: .drink), holding: .bottle)
            add(FramePose(tilt: -14, eyes: .closed, mouth: .o, arms: .drink), holding: .bottle)
            add(FramePose(eyes: .happy, mouth: .grin))
            add(FramePose(dy: -4, eyes: .happy, mouth: .grin))
        case .unscrew:
            walk(to: lampX)
            lampTrip(holdingUp: .none, work: {
                add(FramePose(sy: 1.1, arms: .up), lift: 1)
                add(FramePose(tilt: 12, sy: 1.1, mouth: .grin, arms: .up), lift: 1)
                add(FramePose(tilt: -12, sy: 1.1, mouth: .grin, arms: .up), lift: 1)
                light = false
            }, fallHolding: .bulb)
            walk(to: max(0.2, lampX - 0.3), holding: .bulb, bulb: false)
            add(FramePose(eyes: .happy, mouth: .grin, arms: .hold), holding: .bulb, bulb: false)
        case .inDark:
            for i in 0..<4 {
                add(FramePose(dy: i % 2 == 0 ? -3 : 0, tilt: i % 2 == 0 ? 4 : -4, eyes: .happy, mouth: .grin, arms: .hold),
                    holding: .bulb, bulb: false)
            }
        case .screwBack:
            walk(to: lampX, holding: .bulb, bulb: false)
            lampTrip(holdingUp: .bulb, work: {
                add(FramePose(tilt: 10, sy: 1.1, arms: .up), lift: 1, bulb: true)
                light = true
                add(FramePose(tilt: -10, sy: 1.1, arms: .up), lift: 1)
            }, fallHolding: .none)
            add(FramePose(eyes: .happy, mouth: .grin))
        case .fixLight:
            walk(to: lampX)
            lampTrip(holdingUp: .none, work: {
                add(FramePose(sy: 1.1, eyes: .wide, arms: .up), lift: 1)
                light = true
            }, fallHolding: .none)
            add(FramePose(eyes: .happy, mouth: .grin))
        case .kick:
            let dir = shoe < 0.5 ? 1.0 : -1.0
            walk(to: min(0.92, max(0.08, shoe - dir * 0.09)))
            add(FramePose(tilt: -dir * 14, mouth: .flat))
            let target = min(0.9, max(0.1, shoe + dir * Double.random(in: 0.3...0.5)))
            shoe = (shoe + target) / 2
            add(FramePose(tilt: dir * 14, eyes: .happy, mouth: .grin), shoeAir: 0.6)
            shoe = target
            add(FramePose(eyes: .happy, mouth: .grin))
            add(FramePose(dy: -5, eyes: .happy, mouth: .grin, arms: .up))
        case .dance:
            for i in 0..<6 {
                add(FramePose(dy: i % 2 == 0 ? -8 : 0, tilt: i % 2 == 0 ? 12 : -12, eyes: .happy, mouth: .grin,
                              arms: i % 2 == 0 ? Arms.up : Arms.wave))
            }
        case .stare:
            for i in 0..<4 { add(FramePose(sx: 1.06, sy: 1.06, eyes: i == 2 ? Eyes.closed : Eyes.wide, mouth: .flat)) }
        case .poked:
            add(FramePose(sx: 1.15, sy: 0.82, eyes: .closed, mouth: .o))
            add(FramePose(mouth: .frown))
            add()
        case .scared:
            for i in 0..<4 { add(FramePose(dx: i % 2 == 0 ? 2 : -2, eyes: .wide, mouth: .frown, arms: .hold)) }
        }

        // Иногда просто гуляет после занятия.
        if [.chill, .lookAround, .sitDown, .coffee].contains(action) && Double.random(in: 0...1) < 0.55 {
            walk(to: Double.random(in: 0.15...0.85))
            add()
        }
        return out
    }
}
