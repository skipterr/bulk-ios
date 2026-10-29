import SwiftUI

// MARK: - Лицо

struct FaceView: View {
    var eyes: Eyes
    var mouth: Mouth
    var glow: Bool
    var blush: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let line = Color(white: 0.08)
            let ew = w * 0.17, eh = h * 0.24
            let lw = max(1.4, w * 0.045)
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)

            // румянец
            for cx in [w * 0.1, w * 0.9] {
                let r = CGRect(x: cx - ew * 0.75, y: h * 0.52, width: ew * 1.5, height: eh * 0.38)
                ctx.fill(Path(ellipseIn: r), with: .color(Color(red: 1, green: 0.45, blue: 0.55).opacity(blush)))
            }

            var ectx = ctx
            if glow { ectx.addFilter(.shadow(color: Color.white.opacity(0.9), radius: 3)) }

            // глаза небольшие, близко посажены, в верхней части тела
            for (i, cx) in [w * 0.35, w * 0.65].enumerated() {
                let side: CGFloat = i == 0 ? -1 : 1
                let cy = h * 0.3
                switch eyes {
                case .closed:
                    var p = Path()
                    p.move(to: CGPoint(x: cx - ew * 0.8, y: cy))
                    p.addQuadCurve(to: CGPoint(x: cx + ew * 0.8, y: cy), control: CGPoint(x: cx, y: cy + eh * 0.6))
                    ectx.stroke(p, with: .color(line), style: stroke)
                case .happy:
                    var p = Path()
                    p.move(to: CGPoint(x: cx - ew * 0.8, y: cy + eh * 0.2))
                    p.addQuadCurve(to: CGPoint(x: cx + ew * 0.8, y: cy + eh * 0.2), control: CGPoint(x: cx, y: cy - eh * 0.7))
                    ectx.stroke(p, with: .color(line), style: stroke)
                case .dizzy:
                    var p = Path()
                    p.move(to: CGPoint(x: cx - ew * 0.6, y: cy - eh * 0.5))
                    p.addLine(to: CGPoint(x: cx + ew * 0.6, y: cy + eh * 0.5))
                    p.move(to: CGPoint(x: cx + ew * 0.6, y: cy - eh * 0.5))
                    p.addLine(to: CGPoint(x: cx - ew * 0.6, y: cy + eh * 0.5))
                    ectx.stroke(p, with: .color(line), style: stroke)
                case .drunk:
                    var p = Path()
                    p.move(to: CGPoint(x: cx - ew, y: cy))
                    p.addQuadCurve(to: CGPoint(x: cx + ew, y: cy), control: CGPoint(x: cx, y: cy + eh * 2))
                    p.closeSubpath()
                    ectx.fill(p, with: .color(.white))
                    let pr = ew * 0.45
                    ctx.fill(Path(ellipseIn: CGRect(x: cx + side * ew * 0.25 - pr, y: cy + eh * 0.45 - pr, width: pr * 2, height: pr * 2)), with: .color(.black))
                    var lid = Path()
                    lid.move(to: CGPoint(x: cx - ew * 1.05, y: cy))
                    lid.addLine(to: CGPoint(x: cx + ew * 1.05, y: cy))
                    ctx.stroke(lid, with: .color(line), style: stroke)
                case .open, .wide, .angry:
                    let k: CGFloat = eyes == .wide ? 1.22 : 1
                    let ew2 = ew * k, eh2 = eh * k
                    let eyeRect = CGRect(x: cx - ew2, y: cy - eh2, width: ew2 * 2, height: eh2 * 2)
                    ectx.fill(Path(ellipseIn: eyeRect), with: .color(.white))
                    ctx.stroke(Path(ellipseIn: eyeRect), with: .color(Color(white: 0.08)), lineWidth: 1.5)
                    let pr = eyes == .wide ? ew2 * 0.34 : ew2 * 0.5
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - pr, y: cy - pr + eh2 * 0.1, width: pr * 2, height: pr * 2)), with: .color(.black))
                    let hr = pr * 0.32
                    ctx.fill(Path(ellipseIn: CGRect(x: cx - pr * 0.35 - hr, y: cy - pr * 0.35 + eh2 * 0.1 - hr, width: hr * 2, height: hr * 2)), with: .color(.white))
                    if eyes == .angry {
                        var b = Path()
                        b.move(to: CGPoint(x: cx + side * ew * 0.9, y: cy - eh * 1.55))
                        b.addLine(to: CGPoint(x: cx - side * ew * 0.9, y: cy - eh * 1.05))
                        ctx.stroke(b, with: .color(line), style: stroke)
                    }
                }
            }

            // рот
            let mx = w * 0.5, my = h * 0.82, mw = w * 0.12
            let mouthFill = Color(white: 0.08)
            let tongue = Color(red: 0.94, green: 0.43, blue: 0.51)
            switch mouth {
            case .smile:
                var p = Path()
                p.move(to: CGPoint(x: mx - mw, y: my - mw * 0.25))
                p.addQuadCurve(to: CGPoint(x: mx + mw, y: my - mw * 0.25), control: CGPoint(x: mx, y: my + mw * 0.9))
                ctx.stroke(p, with: .color(line), style: stroke)
            case .grin:
                var p = Path()
                p.move(to: CGPoint(x: mx - mw, y: my - mw * 0.3))
                p.addQuadCurve(to: CGPoint(x: mx + mw, y: my - mw * 0.3), control: CGPoint(x: mx, y: my + mw * 1.5))
                p.closeSubpath()
                ctx.fill(p, with: .color(mouthFill))
                ctx.fill(Path(ellipseIn: CGRect(x: mx - mw * 0.4, y: my + mw * 0.15, width: mw * 0.8, height: mw * 0.35)), with: .color(tongue))
            case .o:
                ctx.fill(Path(ellipseIn: CGRect(x: mx - mw * 0.32, y: my - mw * 0.4, width: mw * 0.64, height: mw * 0.8)), with: .color(mouthFill))
            case .wide:
                ctx.fill(Path(ellipseIn: CGRect(x: mx - mw * 0.85, y: my - mw * 0.55, width: mw * 1.7, height: mw * 1.4)), with: .color(mouthFill))
                ctx.fill(Path(ellipseIn: CGRect(x: mx - mw * 0.5, y: my + mw * 0.3, width: mw, height: mw * 0.45)), with: .color(tongue))
            case .flat:
                var p = Path()
                p.move(to: CGPoint(x: mx - mw * 0.6, y: my - mw * 0.1))
                p.addLine(to: CGPoint(x: mx + mw * 0.6, y: my + mw * 0.15))
                ctx.stroke(p, with: .color(line), style: stroke)
            case .frown:
                var p = Path()
                p.move(to: CGPoint(x: mx - mw * 0.8, y: my + mw * 0.3))
                p.addQuadCurve(to: CGPoint(x: mx + mw * 0.8, y: my + mw * 0.3), control: CGPoint(x: mx, y: my - mw * 0.7))
                ctx.stroke(p, with: .color(line), style: stroke)
            case .wavy:
                var p = Path()
                p.move(to: CGPoint(x: mx - mw, y: my))
                p.addQuadCurve(to: CGPoint(x: mx - mw * 0.33, y: my), control: CGPoint(x: mx - mw * 0.66, y: my - mw * 0.35))
                p.addQuadCurve(to: CGPoint(x: mx + mw * 0.33, y: my), control: CGPoint(x: mx, y: my + mw * 0.35))
                p.addQuadCurve(to: CGPoint(x: mx + mw, y: my), control: CGPoint(x: mx + mw * 0.66, y: my - mw * 0.35))
                ctx.stroke(p, with: .color(line), style: stroke)
            }
        }
    }
}

// MARK: - Предметы

struct BulbView: View {
    var on: Bool
    var size: CGFloat
    var body: some View {
        ZStack {
            if on {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.98, blue: 0.9).opacity(0.6), .clear],
                                         center: .center, startRadius: 0, endRadius: size * 2))
                    .frame(width: size * 4, height: size * 4)
            }
            Circle()
                .fill(on ? Color(red: 1, green: 0.98, blue: 0.9) : Color(white: 0.32))
                .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
    }
}

struct ShoeView: View {
    var dark: Bool
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Capsule().fill(Color(red: dark ? 0.3 : 0.72, green: dark ? 0.1 : 0.24, blue: dark ? 0.1 : 0.23))
                    .frame(width: w * 0.9, height: h * 0.75).position(x: w * 0.5, y: h * 0.42)
                Capsule().fill(Color(white: dark ? 0.4 : 0.9))
                    .frame(width: w, height: h * 0.3).position(x: w * 0.5, y: h * 0.85)
            }
        }
    }
}

struct BottleView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let glass = Color(red: 0.25, green: 0.52, blue: 0.34)
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.25).fill(glass)
                    .frame(width: w, height: h * 0.68).position(x: w / 2, y: h * 0.66)
                Rectangle().fill(glass)
                    .frame(width: w * 0.4, height: h * 0.36).position(x: w / 2, y: h * 0.18)
                Rectangle().fill(Color(red: 0.86, green: 0.8, blue: 0.64))
                    .frame(width: w, height: h * 0.2).position(x: w / 2, y: h * 0.62)
            }
        }
    }
}

// MARK: - Тело

// Клякса: неровный край, низ чуть шире верха.
struct BlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cx = Double(rect.midX), cy = Double(rect.midY)
        let rx = Double(rect.width) / 2 / 1.12, ry = Double(rect.height) / 2 / 1.06
        var p = Path()
        for i in 0...60 {
            let a = Double(i) / 60 * 2 * Double.pi
            let c = cos(a), s = sin(a)
            let bump = 1 + 0.03 * sin(a * 2 + 1.3) + 0.02 * sin(a * 3 + 0.4)
            let x = cx + c * rx * bump * (1 + 0.04 * s)
            let y = min(cy + s * ry * bump, Double(rect.maxY))
            if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
        }
        p.closeSubpath()
        return p
    }
}

struct BulkBody: View {
    var eyes: Eyes
    var mouth: Mouth
    var dark: Bool
    var angry: Bool
    var arms: Arms
    var holding: Prop
    var blush: Double

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let lh = leftHand(w: w, h: h), rh = rightHand(w: w, h: h)
            ZStack {
                BlobShape().fill(bodyFill(w: w))
                BlobShape().stroke(rim, lineWidth: 2)
                FaceView(eyes: eyes, mouth: mouth, glow: dark, blush: blush)
                    .frame(width: w * 0.6, height: h * 0.62).position(x: w * 0.5, y: h * 0.4)
                if holding == .bottle {
                    BottleView().frame(width: w * 0.12, height: h * 0.42)
                        .rotationEffect(.degrees(-40))
                        .position(x: rh.x - w * 0.06, y: rh.y - h * 0.16)
                }
                hand(at: lh, size: w * 0.17)
                hand(at: rh, size: w * 0.17)
                if holding == .bulb {
                    BulbView(on: false, size: w * 0.17).position(x: w * 0.5, y: h * 0.74)
                }
            }
        }
    }

    private var rim: Color { Color(white: 0.07) }

    // матовый серый, как у кляксы
    private var baseColor: Color {
        if angry { return Color(red: 0.55, green: 0.4, blue: 0.42) }
        return dark ? Color(white: 0.2) : Color(white: 0.47)
    }

    private func bodyFill(w: CGFloat) -> RadialGradient {
        let top = angry ? Color(red: 0.62, green: 0.47, blue: 0.49) : Color(white: dark ? 0.23 : 0.52)
        let low = Color(white: dark ? 0.15 : 0.42)
        return RadialGradient(colors: [top, baseColor, low], center: UnitPoint(x: 0.4, y: 0.2),
                              startRadius: 1, endRadius: w * 0.75)
    }

    private func leftHand(w: CGFloat, h: CGFloat) -> CGPoint {
        switch arms {
        case .rest, .wave, .waveLow, .drink: return CGPoint(x: w * 0.02, y: h * 0.65)
        case .up: return CGPoint(x: w * 0.3, y: -h * 0.08)
        case .hold: return CGPoint(x: w * 0.36, y: h * 0.82)
        }
    }

    private func rightHand(w: CGFloat, h: CGFloat) -> CGPoint {
        switch arms {
        case .rest: return CGPoint(x: w * 0.98, y: h * 0.65)
        case .up: return CGPoint(x: w * 0.7, y: -h * 0.08)
        case .wave: return CGPoint(x: w * 1.02, y: h * 0.05)
        case .waveLow: return CGPoint(x: w * 1.08, y: h * 0.35)
        case .hold: return CGPoint(x: w * 0.64, y: h * 0.82)
        case .drink: return CGPoint(x: w * 0.8, y: h * 0.55)
        }
    }

    private func hand(at p: CGPoint, size: CGFloat) -> some View {
        Circle().fill(baseColor)
            .overlay(Circle().stroke(rim, lineWidth: 1))
            .frame(width: size, height: size)
            .position(p)
    }
}

// MARK: - Живой Бульк в виджете

/// Секундомер, нарисованный шрифтом, где цифры 0-9 — кадры Булька (шрифты собираются при сборке).
/// Видна только последняя цифра, она меняется раз в секунду — так Бульк двигается прямо на экране «Домой».
struct LiveSprite: View {
    let action: BulkAction
    let height: CGFloat

    static let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    private var fontName: String {
        "Bulk" + action.rawValue.prefix(1).uppercased() + action.rawValue.dropFirst()
    }

    var body: some View {
        Text(Self.epoch, style: .timer)
            .font(.custom(fontName, size: height))
            .lineLimit(1)
            .fixedSize()
            .frame(width: height * 1.4, height: height, alignment: .trailing)
            .clipped()
    }
}

/// Запасной способ: три одноцветных шрифта-слоя (тело, белое, чёрное) накладываются друг на друга.
struct LayeredSprite: View {
    let action: BulkAction
    let height: CGFloat
    var live = true

    private var base: String {
        "Bulk" + action.rawValue.prefix(1).uppercased() + action.rawValue.dropFirst()
    }

    var body: some View {
        ZStack {
            layer("F", Color(white: 0.47))
            layer("W", .white)
            layer("K", Color(white: 0.07))
        }
        .frame(width: height * 1.4, height: height, alignment: .trailing)
        .clipped()
    }

    @ViewBuilder
    private func layer(_ suffix: String, _ color: Color) -> some View {
        Group {
            if live { Text(LiveSprite.epoch, style: .timer) } else { Text("5") }
        }
        .font(.custom(base + suffix, size: height))
        .foregroundStyle(color)
        .lineLimit(1)
        .fixedSize()
        .frame(width: height * 1.4, height: height, alignment: .trailing)
    }
}

/// Временный тестовый блок. Верхний ряд — цветные кадры: A обычный секундомер, B кадр, C секундомер кадрами, D итог.
/// Нижний ряд — слои: E кадр из слоёв, F секундомер из слоёв (итог запасного способа).
struct SpriteProbe: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 3) {
                Text("A").font(.system(size: 7))
                Text(LiveSprite.epoch, style: .timer).font(.system(size: 8, design: .monospaced))
                Text("B").font(.system(size: 7))
                Text("05").font(.custom("BulkDance", size: 18))
                Text("C").font(.system(size: 7))
                Text(LiveSprite.epoch, style: .timer).font(.custom("BulkDance", size: 18)).lineLimit(1).fixedSize()
                Text("D").font(.system(size: 7))
                LiveSprite(action: .dance, height: 18)
            }
            HStack(spacing: 3) {
                Text("E").font(.system(size: 7))
                LayeredSprite(action: .dance, height: 26, live: false)
                Text("F").font(.system(size: 7))
                LayeredSprite(action: .dance, height: 26)
            }
        }
        .foregroundStyle(Color.white.opacity(0.8))
        .padding(3)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - Сцена

struct BulkPose {
    var x: CGFloat
    var lift: Bool
    var tilt: Double
    var sx: CGFloat
    var sy: CGFloat
    var arms: Arms
}

extension BulkAction {
    var pose: BulkPose {
        switch self {
        case .chill: return BulkPose(x: 0.42, lift: false, tilt: 0, sx: 1, sy: 1, arms: .rest)
        case .wave: return BulkPose(x: 0.42, lift: false, tilt: 0, sx: 1, sy: 1, arms: .wave)
        case .sleep: return BulkPose(x: 0.36, lift: false, tilt: 0, sx: 1.12, sy: 0.8, arms: .rest)
        case .burp: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1.12, sy: 0.95, arms: .rest)
        case .swear: return BulkPose(x: 0.45, lift: false, tilt: -7, sx: 1, sy: 1.05, arms: .up)
        case .drink: return BulkPose(x: 0.4, lift: false, tilt: -8, sx: 1, sy: 1, arms: .drink)
        case .unscrew, .screwBack, .fixLight: return BulkPose(x: 0.68, lift: true, tilt: 0, sx: 0.92, sy: 1.1, arms: .up)
        case .inDark: return BulkPose(x: 0.3, lift: false, tilt: 0, sx: 1, sy: 1, arms: .hold)
        case .kick: return BulkPose(x: 0.3, lift: false, tilt: 14, sx: 1, sy: 1, arms: .rest)
        case .dance: return BulkPose(x: 0.5, lift: false, tilt: -12, sx: 1, sy: 1, arms: .wave)
        case .stare: return BulkPose(x: 0.5, lift: false, tilt: 0, sx: 1.06, sy: 1.06, arms: .rest)
        case .poked: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1.15, sy: 0.82, arms: .rest)
        case .mad: return BulkPose(x: 0.45, lift: false, tilt: 6, sx: 1, sy: 1.05, arms: .up)
        case .scared: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 0.95, sy: 1.05, arms: .hold)
        }
    }

    var holding: Prop {
        switch self {
        case .drink: return .bottle
        case .inDark: return .bulb
        default: return .none
        }
    }

    // Сколько кадров в цикле движения и как быстро он крутится.
    var frameCount: Int {
        switch self {
        case .scared, .poked, .swear, .mad: return 6
        case .dance, .wave, .kick, .unscrew, .screwBack, .fixLight: return 8
        default: return 12
        }
    }

    var period: TimeInterval {
        switch self {
        case .chill, .stare: return 3.6
        case .sleep: return 4
        case .wave: return 1.2
        case .burp: return 2.4
        case .swear, .mad, .poked: return 0.6
        case .drink, .inDark: return 2
        case .unscrew, .screwBack, .fixLight: return 1
        case .kick: return 1.4
        case .dance: return 1
        case .scared: return 0.36
        }
    }

    func framePose(_ i: Int, of n: Int, drunk: Bool) -> FramePose {
        let t = Double(i) / Double(n)
        let s = sin(t * 2 * Double.pi)
        let odd = i % 2 == 1
        var f = FramePose()
        switch self {
        case .chill, .stare:
            f.sy = 1 + 0.03 * s
            f.sx = 1 - 0.02 * s
            if i == n - 1 { f.eyes = .closed }
        case .sleep:
            f.sy = 1 + 0.05 * s
            f.sx = 1 - 0.03 * s
        case .wave:
            f.arms = odd ? .wave : .waveLow
            f.tilt = 3 * s
        case .burp:
            if t < 0.55 {
                f.sx = 1 + 0.25 * t
                f.mouth = .o
                f.eyes = .open
            } else {
                f.mouth = .wide
                f.eyes = .closed
                f.dy = -3
            }
        case .swear, .mad:
            f.dx = odd ? 2.5 : -2.5
            f.dy = odd ? -2 : 0
            f.arms = odd ? .up : .rest
        case .drink:
            f.tilt = 3 * s
            f.sy = 1 + 0.02 * s
        case .unscrew, .screwBack, .fixLight:
            f.tilt = 10 * s
        case .inDark:
            f.dy = -3 * max(0, s)
            f.tilt = 4 * s
        case .kick:
            f.tilt = 12 * s
            f.dx = 2 * s
        case .dance:
            f.dy = -6 * abs(s)
            f.tilt = 12 * s
            f.arms = odd ? .wave : .up
        case .poked:
            f.sy = 1 + 0.06 * s
            f.sx = 1 - 0.05 * s
        case .scared:
            f.dx = odd ? 1.5 : -1.5
        }
        if drunk { f.tilt += 6 * s }
        return f
    }
}

struct FramePose {
    var dx: Double = 0
    var dy: Double = 0
    var tilt: Double = 0
    var sx: Double = 1
    var sy: Double = 1
    var eyes: Eyes? = nil
    var mouth: Mouth? = nil
    var arms: Arms? = nil
}

struct BulkScene: View {
    let action: BulkAction
    let phrase: String
    let lightOn: Bool
    let tipsy: Double

    var body: some View {
        GeometryReader { geo in
            content(w: geo.size.width, h: geo.size.height)
        }
    }

    private var drunkLook: Bool { tipsy > 0.4 && [.chill, .stare, .wave].contains(action) }

    @ViewBuilder
    private func content(w: CGFloat, h: CGFloat) -> some View {
        let floorY = h * 0.86
        let lampX = w * 0.68
        let bulbY = h * 0.2
        let bodyH = h * 0.38
        let bodyW = bodyH * 0.95
        let pose = action.pose
        let bx: CGFloat = pose.lift ? lampX : w * pose.x
        let bottomY: CGFloat = pose.lift ? bulbY + 10 + bodyH * pose.sy : floorY
        let dark = !lightOn

        ZStack {
            Color(white: 0.16)
            room(w: w, h: h, floorY: floorY, lampX: lampX, bulbY: bulbY)

            ShoeView(dark: dark)
                .frame(width: 24, height: 11)
                .rotationEffect(.degrees(action == .kick ? -35 : 0))
                .position(x: action == .kick ? w * 0.6 : w * 0.12, y: action == .kick ? h * 0.3 : floorY - 5.5)

            Ellipse().fill(Color.black.opacity(pose.lift ? 0.15 : 0.45))
                .frame(width: bodyW * (pose.lift ? 0.6 : 1), height: 5)
                .position(x: bx, y: floorY + 1)

            BulkBody(eyes: drunkLook ? .drunk : action.eyes,
                     mouth: drunkLook ? .wavy : action.mouth,
                     dark: dark,
                     angry: action == .mad || action == .swear,
                     arms: pose.arms,
                     holding: action.holding,
                     blush: min(1, tipsy) * 0.5)
                .frame(width: bodyW * pose.sx, height: bodyH * pose.sy)
                .rotationEffect(.degrees(pose.tilt + (drunkLook ? 8 : 0)), anchor: .bottom)
                .position(x: bx, y: bottomY - bodyH * pose.sy / 2)

            // ТЕСТ: проверяем, рисует ли iOS кадры из шрифта в виджете
            SpriteProbe()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(6)

            effects(bx: bx, topY: bottomY - bodyH * pose.sy, bodyW: bodyW)

            if !phrase.isEmpty {
                bubble(phrase)
                    .position(x: pose.lift ? lampX - 78 : min(max(bx, 62), w - 62),
                              y: pose.lift ? h * 0.42 : max(14, bottomY - bodyH * pose.sy - 16))
            }

            Text("Бульк · \(action.status)")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.leading, 12)
                .padding(.top, 10)
        }
    }

    @ViewBuilder
    private func room(w: CGFloat, h: CGFloat, floorY: CGFloat, lampX: CGFloat, bulbY: CGFloat) -> some View {
        if lightOn {
            RadialGradient(colors: [Color.white.opacity(0.22), Color.white.opacity(0.05), .clear],
                           center: UnitPoint(x: lampX / w, y: bulbY / h), startRadius: 2, endRadius: h * 1.1)
            Ellipse()
                .fill(RadialGradient(colors: [Color.white.opacity(0.14), .clear], center: .center, startRadius: 1, endRadius: w * 0.25))
                .frame(width: w * 0.5, height: h * 0.12)
                .position(x: lampX, y: floorY + 2)
        }
        Rectangle().fill(Color.white.opacity(0.07)).frame(width: w, height: 1).position(x: w / 2, y: floorY)
        // лампа слегка качается на проводе
        Flipbook(count: 8, period: 3) { i in
            lamp(bulbY: bulbY)
                .rotationEffect(.degrees(sin(Double(i) / 8 * 2 * Double.pi) * 3), anchor: .top)
        }
        .frame(width: 60, height: bulbY + 30)
        .position(x: lampX, y: (bulbY + 30) / 2)
    }

    private func lamp(bulbY: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(Color(white: 0.22)).frame(width: 1.5, height: bulbY).position(x: 30, y: bulbY / 2)
            RoundedRectangle(cornerRadius: 2).fill(Color(white: lightOn ? 0.35 : 0.2))
                .frame(width: 9, height: 6).position(x: 30, y: bulbY - 5)
            if action != .inDark {
                BulbView(on: lightOn, size: 12).position(x: 30, y: bulbY + 3)
            }
        }
        .frame(width: 60, height: bulbY + 30)
    }

    @ViewBuilder
    private func effects(bx: CGFloat, topY: CGFloat, bodyW: CGFloat) -> some View {
        switch action {
        case .sleep:
            Flipbook(count: 6, period: 3) { i in
                Text("z").font(.system(size: 9 + CGFloat(i) * 1.5, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7 - Double(i) * 0.1))
                    .offset(x: CGFloat(i) * 2.5, y: -CGFloat(i) * 4)
                    .frame(width: 40, height: 40, alignment: .bottomLeading)
            }
            .position(x: bx + bodyW * 0.6, y: topY - 10)
        case .dance:
            Flipbook(count: 4, period: 1.6) { i in
                Text(i % 2 == 0 ? "♪" : "♫").font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .offset(x: i < 2 ? -4 : 4, y: -CGFloat(i % 2) * 5)
                    .frame(width: 30, height: 30)
            }
            .position(x: bx - bodyW * 0.6, y: topY + 4)
        case .burp:
            Circle().fill(Color(red: 0.65, green: 0.82, blue: 0.55).opacity(0.35))
                .frame(width: 16, height: 16).position(x: bx + bodyW * 0.55, y: topY + 10)
        default:
            if drunkLook {
                Text("ик").font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .position(x: bx + bodyW * 0.6, y: topY + 2)
            }
        }
    }

    private func bubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(Color.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.92)))
            .fixedSize()
    }
}
