import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Лицо

/// Один штрих лица: контур или заливка.
struct FaceOp {
    let path: Path
    let color: Color
    var stroke = false
    var lineWidth: CGFloat = 1.5
    var glow = false
}

struct FixedPath: Shape {
    let p: Path
    func path(in rect: CGRect) -> Path { p }
}

// Лицо собрано из отдельных фигур, а не одной картинкой (Canvas):
// при движении в виджете фигуры едут вместе с телом, а картинка «растворялась»
// на старом месте — получалась вторая пара глаз.
struct FaceView: View {
    var eyes: Eyes
    var mouth: Mouth
    var glow: Bool
    var blush: Double
    var look: Double = 0          // -1 — смотрит влево, 1 — вправо

    var body: some View {
        GeometryReader { g in
            ZStack {
                ForEach(Array(ops(g.size).enumerated()), id: \.offset) { _, op in
                    Group {
                        if op.stroke {
                            FixedPath(p: op.path)
                                .stroke(op.color, style: StrokeStyle(lineWidth: op.lineWidth, lineCap: .round, lineJoin: .round))
                        } else {
                            FixedPath(p: op.path).fill(op.color)
                        }
                    }
                    .shadow(color: op.glow ? Color.white.opacity(0.9) : .clear, radius: op.glow ? 3 : 0)
                }
            }
        }
    }

    private func ops(_ size: CGSize) -> [FaceOp] {
        var out: [FaceOp] = []
        let w = size.width, h = size.height
        let line = Color(white: 0.08)
        let ew = w * 0.17, eh = h * 0.24
        let lw = max(1.4, w * 0.045)

        // румянец
        for cx in [w * 0.1, w * 0.9] {
            let r = CGRect(x: cx - ew * 0.75, y: h * 0.52, width: ew * 1.5, height: eh * 0.38)
            out.append(FaceOp(path: Path(ellipseIn: r), color: Color(red: 1, green: 0.45, blue: 0.55).opacity(blush)))
        }

        // глаза небольшие, близко посажены, в верхней части тела
        for (i, cx) in [w * 0.35, w * 0.65].enumerated() {
            let side: CGFloat = i == 0 ? -1 : 1
            let cy = h * 0.3
            switch eyes {
            case .closed:
                var p = Path()
                p.move(to: CGPoint(x: cx - ew * 0.8, y: cy))
                p.addQuadCurve(to: CGPoint(x: cx + ew * 0.8, y: cy), control: CGPoint(x: cx, y: cy + eh * 0.6))
                out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw, glow: glow))
            case .happy:
                var p = Path()
                p.move(to: CGPoint(x: cx - ew * 0.8, y: cy + eh * 0.2))
                p.addQuadCurve(to: CGPoint(x: cx + ew * 0.8, y: cy + eh * 0.2), control: CGPoint(x: cx, y: cy - eh * 0.7))
                out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw, glow: glow))
            case .dizzy:
                var p = Path()
                p.move(to: CGPoint(x: cx - ew * 0.6, y: cy - eh * 0.5))
                p.addLine(to: CGPoint(x: cx + ew * 0.6, y: cy + eh * 0.5))
                p.move(to: CGPoint(x: cx + ew * 0.6, y: cy - eh * 0.5))
                p.addLine(to: CGPoint(x: cx - ew * 0.6, y: cy + eh * 0.5))
                out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw, glow: glow))
            case .drunk:
                var p = Path()
                p.move(to: CGPoint(x: cx - ew, y: cy))
                p.addQuadCurve(to: CGPoint(x: cx + ew, y: cy), control: CGPoint(x: cx, y: cy + eh * 2))
                p.closeSubpath()
                out.append(FaceOp(path: p, color: .white, glow: glow))
                let pr = ew * 0.45
                out.append(FaceOp(path: Path(ellipseIn: CGRect(x: cx + side * ew * 0.25 - pr, y: cy + eh * 0.45 - pr,
                                                                width: pr * 2, height: pr * 2)), color: .black))
                var lid = Path()
                lid.move(to: CGPoint(x: cx - ew * 1.05, y: cy))
                lid.addLine(to: CGPoint(x: cx + ew * 1.05, y: cy))
                out.append(FaceOp(path: lid, color: line, stroke: true, lineWidth: lw))
            case .open, .wide, .angry:
                let k: CGFloat = eyes == .wide ? 1.22 : 1
                let ew2 = ew * k, eh2 = eh * k
                let eyeRect = CGRect(x: cx - ew2, y: cy - eh2, width: ew2 * 2, height: eh2 * 2)
                out.append(FaceOp(path: Path(ellipseIn: eyeRect), color: .white, glow: glow))
                out.append(FaceOp(path: Path(ellipseIn: eyeRect), color: line, stroke: true, lineWidth: 1.5))
                let pr = eyes == .wide ? ew2 * 0.34 : ew2 * 0.5
                let px = cx + CGFloat(look) * (ew2 - pr) * 0.9
                out.append(FaceOp(path: Path(ellipseIn: CGRect(x: px - pr, y: cy - pr + eh2 * 0.1, width: pr * 2, height: pr * 2)),
                                  color: .black))
                let hr = pr * 0.32
                out.append(FaceOp(path: Path(ellipseIn: CGRect(x: px - pr * 0.35 - hr, y: cy - pr * 0.35 + eh2 * 0.1 - hr,
                                                                width: hr * 2, height: hr * 2)), color: .white))
                if eyes == .angry {
                    var b = Path()
                    b.move(to: CGPoint(x: cx + side * ew * 0.9, y: cy - eh * 1.55))
                    b.addLine(to: CGPoint(x: cx - side * ew * 0.9, y: cy - eh * 1.05))
                    out.append(FaceOp(path: b, color: line, stroke: true, lineWidth: lw))
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
            out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw))
        case .grin:
            var p = Path()
            p.move(to: CGPoint(x: mx - mw, y: my - mw * 0.3))
            p.addQuadCurve(to: CGPoint(x: mx + mw, y: my - mw * 0.3), control: CGPoint(x: mx, y: my + mw * 1.5))
            p.closeSubpath()
            out.append(FaceOp(path: p, color: mouthFill))
            out.append(FaceOp(path: Path(ellipseIn: CGRect(x: mx - mw * 0.4, y: my + mw * 0.15, width: mw * 0.8, height: mw * 0.35)),
                              color: tongue))
        case .o:
            out.append(FaceOp(path: Path(ellipseIn: CGRect(x: mx - mw * 0.32, y: my - mw * 0.4, width: mw * 0.64, height: mw * 0.8)),
                              color: mouthFill))
        case .wide:
            out.append(FaceOp(path: Path(ellipseIn: CGRect(x: mx - mw * 0.85, y: my - mw * 0.55, width: mw * 1.7, height: mw * 1.4)),
                              color: mouthFill))
            out.append(FaceOp(path: Path(ellipseIn: CGRect(x: mx - mw * 0.5, y: my + mw * 0.3, width: mw, height: mw * 0.45)),
                              color: tongue))
        case .flat:
            var p = Path()
            p.move(to: CGPoint(x: mx - mw * 0.6, y: my - mw * 0.1))
            p.addLine(to: CGPoint(x: mx + mw * 0.6, y: my + mw * 0.15))
            out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw))
        case .frown:
            var p = Path()
            p.move(to: CGPoint(x: mx - mw * 0.8, y: my + mw * 0.3))
            p.addQuadCurve(to: CGPoint(x: mx + mw * 0.8, y: my + mw * 0.3), control: CGPoint(x: mx, y: my - mw * 0.7))
            out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw))
        case .wavy:
            var p = Path()
            p.move(to: CGPoint(x: mx - mw, y: my))
            p.addQuadCurve(to: CGPoint(x: mx - mw * 0.33, y: my), control: CGPoint(x: mx - mw * 0.66, y: my - mw * 0.35))
            p.addQuadCurve(to: CGPoint(x: mx + mw * 0.33, y: my), control: CGPoint(x: mx, y: my + mw * 0.35))
            p.addQuadCurve(to: CGPoint(x: mx + mw, y: my), control: CGPoint(x: mx + mw * 0.66, y: my - mw * 0.35))
            out.append(FaceOp(path: p, color: line, stroke: true, lineWidth: lw))
        }
        return out
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

// Высокий красно-бело-чёрный кроссовок, носок смотрит вправо.
struct HighTopShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height, soleTop = h * 0.8
        var p = Path()
        p.move(to: CGPoint(x: 0, y: soleTop))
        p.addLine(to: CGPoint(x: w * 0.04, y: 0))
        p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.04))
        p.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.48), control: CGPoint(x: w * 0.52, y: h * 0.45))
        p.addQuadCurve(to: CGPoint(x: w, y: soleTop), control: CGPoint(x: w * 1.02, y: h * 0.52))
        p.closeSubpath()
        return p
    }
}

// Свуш на боку: острый кончик к пятке, загиб у носка.
struct SwooshShape: Shape {
    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.14, y: h * 0.36))
        p.addQuadCurve(to: CGPoint(x: w * 0.82, y: h * 0.6), control: CGPoint(x: w * 0.5, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.86, y: h * 0.47))
        p.addQuadCurve(to: CGPoint(x: w * 0.14, y: h * 0.36), control: CGPoint(x: w * 0.5, y: h * 0.68))
        p.closeSubpath()
        return p
    }
}

struct ShoeView: View {
    var dark: Bool
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let k = dark ? 0.4 : 1.0
            let red = Color(red: 0.78 * k, green: 0.12 * k, blue: 0.16 * k)
            let white = Color(white: 0.93 * k)
            let black = Color(white: 0.08)
            ZStack {
                ZStack {
                    white
                    red.frame(width: w * 0.36).position(x: w * 0.18, y: h / 2)          // пятка
                    red.frame(width: w * 0.32).position(x: w * 0.88, y: h / 2)          // носок
                    red.frame(height: h * 0.2).position(x: w / 2, y: h * 0.1)           // верх голенища
                    SwooshShape().fill(black)                                           // свуш
                }
                .frame(width: w, height: h)
                .clipShape(HighTopShape())
                HighTopShape().stroke(black, lineWidth: 1)
                Capsule().fill(white).overlay(Capsule().stroke(black, lineWidth: 1))
                    .frame(width: w, height: h * 0.22).position(x: w / 2, y: h * 0.89)
            }
        }
    }
}

// Баллончик краски для граффити.
struct SprayCanView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.25).fill(Color(red: 0.9, green: 0.3, blue: 0.45))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.25).stroke(Color(white: 0.08), lineWidth: 1))
                    .frame(width: w, height: h * 0.78).position(x: w / 2, y: h * 0.61)
                RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.75))
                    .frame(width: w * 0.5, height: h * 0.2).position(x: w / 2, y: h * 0.12)
            }
        }
    }
}

// Выкрученная лампочка в руках: стеклянная колба и резьбовой цоколь снизу.
struct HeldBulbView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                Circle().fill(Color(red: 0.92, green: 0.9, blue: 0.82).opacity(0.85))
                    .overlay(Circle().stroke(Color(white: 0.08), lineWidth: 1))
                    .frame(width: w, height: w).position(x: w / 2, y: w / 2)
                Path { p in                                     // нить накаливания
                    p.move(to: CGPoint(x: w * 0.3, y: w * 0.55))
                    p.addLine(to: CGPoint(x: w * 0.42, y: w * 0.38))
                    p.addLine(to: CGPoint(x: w * 0.58, y: w * 0.55))
                    p.addLine(to: CGPoint(x: w * 0.7, y: w * 0.38))
                }
                .stroke(Color(red: 0.6, green: 0.45, blue: 0.2), lineWidth: 1)
                RoundedRectangle(cornerRadius: 1.5).fill(Color(white: 0.55))
                    .overlay(RoundedRectangle(cornerRadius: 1.5).stroke(Color(white: 0.08), lineWidth: 1))
                    .frame(width: w * 0.5, height: h - w * 0.92).position(x: w / 2, y: (h + w * 0.92) / 2)
            }
        }
    }
}

// Кружка кофе с паром.
struct MugView: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            ZStack {
                RoundedRectangle(cornerRadius: w * 0.12).fill(Color(white: 0.95))
                    .overlay(RoundedRectangle(cornerRadius: w * 0.12).stroke(Color(white: 0.08), lineWidth: 1))
                    .frame(width: w * 0.72, height: h * 0.78).position(x: w * 0.42, y: h * 0.58)
                Circle().stroke(Color(white: 0.95), lineWidth: w * 0.1)
                    .frame(width: w * 0.32, height: w * 0.32).position(x: w * 0.82, y: h * 0.56)
                Rectangle().fill(Color(red: 0.45, green: 0.28, blue: 0.16))
                    .frame(width: w * 0.6, height: h * 0.1).position(x: w * 0.42, y: h * 0.27)
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
    var look: Double = 0
    /// true — Бульк отвернулся (обиделся): лица не видно
    var back: Bool = false

    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let lh = leftHand(w: w, h: h), rh = rightHand(w: w, h: h)
            ZStack {
                BlobShape().fill(bodyFill(w: w))
                BlobShape().stroke(rim, lineWidth: 2)
                if !back {
                    FaceView(eyes: eyes, mouth: mouth, glow: dark, blush: blush, look: look)
                        .frame(width: w * 0.6, height: h * 0.62).position(x: w * 0.5, y: h * 0.4)
                }
                if holding == .bottle {
                    BottleView().frame(width: w * 0.12, height: h * 0.42)
                        .rotationEffect(.degrees(-40))
                        .position(x: rh.x - w * 0.06, y: rh.y - h * 0.16)
                }
                hand(at: lh, size: w * 0.17)
                hand(at: rh, size: w * 0.17)
                if holding == .bulb {
                    // лампочку держит перед собой в руках, внизу — чтобы не путалась с лицом
                    HeldBulbView().frame(width: w * 0.2, height: w * 0.28).position(x: w * 0.5, y: h * 0.8)
                }
                if holding == .gamepad {
                    Text("🎮").font(.system(size: w * 0.24)).position(x: w * 0.5, y: h * 0.8)
                }
                if holding == .book {
                    // книжка вверх ногами — в этом весь прикол
                    Text("📖").font(.system(size: w * 0.26)).rotationEffect(.degrees(180)).position(x: w * 0.5, y: h * 0.74)
                }
                if holding == .spray {
                    SprayCanView().frame(width: w * 0.1, height: w * 0.2).rotationEffect(.degrees(25))
                        .position(x: rh.x + w * 0.02, y: rh.y - h * 0.08)
                }
                if holding == .mug {
                    MugView().frame(width: w * 0.2, height: w * 0.18).position(x: rh.x - w * 0.08, y: rh.y - h * 0.08)
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

/// Временный тестовый виджет: в каждой ячейке подпись и проба, всё обрезано по своей рамке.
/// B — кадр цветным шрифтом, D — секундомер цветным шрифтом,
/// E — кадр из шрифтов-слоёв, F — секундомер из шрифтов-слоёв, G — общая память с приложением.
struct SpriteProbe: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                cell("A") {
                    Text(LiveSprite.epoch, style: .timer)
                        .font(.system(size: 10, design: .monospaced))
                        .frame(width: 90, height: 40, alignment: .trailing)
                        .clipped()
                }
                cell("B") {
                    Text("5").font(.custom("BulkDance", size: 40))
                        .frame(width: 56, height: 40).clipped()
                }
                cell("D") { LiveSprite(action: .dance, height: 40) }
            }
            HStack(spacing: 10) {
                cell("E") { LayeredSprite(action: .dance, height: 40, live: false) }
                cell("F") { LayeredSprite(action: .dance, height: 40) }
                Text(SharedGroup.isShared ? "G: связь есть" : "G: связи нет")
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .foregroundStyle(Color.white)
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func cell<V: View>(_ label: String, @ViewBuilder _ content: () -> V) -> some View {
        HStack(spacing: 3) {
            Text(label).font(.system(size: 10, weight: .bold))
            content()
                .background(Color.white.opacity(0.08))
        }
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
        case .yawn, .lookAround, .fly: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1, sy: 1, arms: .rest)
        case .sitDown: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1.2, sy: 0.75, arms: .rest)
        case .coffee: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1, sy: 1, arms: .drink)
        case .sulk, .missYou: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1.05, sy: 0.92, arms: .rest)
        case .cheer: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1, sy: 1, arms: .up)
        case .hug: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1, sy: 1, arms: .hold)
        case .gaming: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1.15, sy: 0.82, arms: .hold)
        case .reading: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1, sy: 1, arms: .hold)
        case .graffiti: return BulkPose(x: 0.45, lift: false, tilt: 0, sx: 1, sy: 1, arms: .up)
        }
    }

    var holding: Prop {
        switch self {
        case .drink: return .bottle
        case .inDark: return .bulb
        case .coffee: return .mug
        case .gaming: return .gamepad
        case .reading: return .book
        case .graffiti: return .spray
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
        case .yawn, .lookAround, .sitDown, .coffee, .fly: return 3
        case .sulk, .missYou, .hug: return 3
        case .cheer: return 1
        case .gaming, .reading, .graffiti: return 3
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
        case .yawn, .sitDown, .coffee:
            f.sy = 1 + 0.03 * s
        case .lookAround, .fly:
            f.look = s
        case .sulk, .missYou, .hug:
            f.sy = 1 + 0.02 * s
        case .gaming:
            f.look = 0.3 * s
        case .reading, .graffiti:
            f.sy = 1 + 0.02 * s
        case .cheer:
            f.dy = -6 * abs(s)
            f.arms = odd ? .up : .wave
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
    var look: Double? = nil
    var back: Bool? = nil
}

/// Картинки граффити, которые нарисовало приложение (bubble letters, как в комнате приложения).
enum TagImages {
    #if canImport(UIKit)
    // ключ + дата файла: приложение перерисовало картинку — виджет берёт новую, а не старую из памяти
    static var cache: [String: (date: Date, img: UIImage)] = [:]
    static func image(for tag: WallTag) -> UIImage? {
        guard let url = SharedGroup.tagsFolder?.appendingPathComponent(tag.imageKey + ".png"),
              let date = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        else { return nil }
        if let hit = cache[tag.imageKey], hit.date == date { return hit.img }
        guard let img = UIImage(contentsOfFile: url.path) else { return nil }
        cache[tag.imageKey] = (date, img)
        return img
    }
    #endif
}

/// Граффити на стене виджета. Обычно — готовая картинка из приложения (рисуется один раз, не грузит виджет).
/// Пока картинки нет (приложение ещё не открывали) — упрощённое граффити из текста.
struct GraffitiTag: View {
    let tag: WallTag
    var dim = false     // свет выключен — краска еле видна

    var body: some View {
        Group {
            #if canImport(UIKit)
            if let img = TagImages.image(for: tag) {
                // картинка нарисована вдвое крупнее букв в 17 pt
                Image(uiImage: img).resizable().interpolation(.high)
                    .frame(width: img.size.width / 2, height: img.size.height / 2)
            } else {
                drawn
            }
            #else
            drawn
            #endif
        }
        .rotationEffect(.degrees(tag.tilt))
        .opacity(dim ? 0.25 : 0.95)
    }

    // пары цветов (как TAG_PAL в bulk.html): верх букв посветлее, низ — насыщеннее
    static let colors: [(Color, Color)] = [
        (Color(red: 0.83, green: 0.97, blue: 0.54), Color(red: 0.42, green: 0.76, blue: 0.23)),
        (Color(red: 1, green: 0.72, blue: 0.82), Color(red: 0.94, green: 0.29, blue: 0.53)),
        (Color(red: 0.68, green: 0.94, blue: 1), Color(red: 0.18, green: 0.71, blue: 0.93)),
        (Color(red: 1, green: 0.95, blue: 0.63), Color(red: 1, green: 0.76, blue: 0.12)),
        (Color(red: 0.89, green: 0.78, blue: 1), Color(red: 0.61, green: 0.36, blue: 0.94))
    ]

    static let size: CGFloat = 17
    private let ink = Color(white: 0.06)

    /// Подтёки: где (доля ширины) и какой длины — зависят только от текста, чтобы не прыгали между кадрами.
    static func drips(_ text: String) -> [(x: CGFloat, len: CGFloat)] {
        var h: UInt32 = 0
        for u in text.unicodeScalars { h = h &* 31 &+ u.value }
        var out: [(x: CGFloat, len: CGFloat)] = []
        for i in 0..<3 {
            let a = CGFloat((h >> UInt32(i * 5)) % 32) / 31
            let b = CGFloat((h >> UInt32(i * 7 + 3)) % 16) / 15
            out.append((x: 0.12 + 0.76 * a, len: size * (0.25 + 0.5 * b)))
        }
        return out
    }

    private var drawn: some View {
        let pair = Self.colors[abs(tag.color) % Self.colors.count]
        let word = Text(tag.text.uppercased())
            .font(.system(size: Self.size, weight: .black, design: .rounded))
            .tracking(-0.5)
        let s = Self.size
        return ZStack {
            // объёмная тень
            word.foregroundStyle(ink).offset(x: s * 0.12, y: s * 0.12)
            // контур
            ForEach(0..<4, id: \.self) { i in
                let a: CGFloat = CGFloat(i) * .pi / 2 + .pi / 4
                let r: CGFloat = s * 0.09
                word.foregroundStyle(ink).offset(x: cos(a) * r, y: sin(a) * r)
            }
            word.foregroundStyle(LinearGradient(colors: [pair.0, pair.1], startPoint: .top, endPoint: .bottom))
        }
        .fixedSize()
        .background {
            GeometryReader { g in
                ForEach(Array(Self.drips(tag.text).enumerated()), id: \.offset) { _, d in
                    Capsule().fill(pair.1)
                        .overlay(Capsule().stroke(ink, lineWidth: 1))
                        .frame(width: s * 0.13, height: d.len)
                        .position(x: g.size.width * d.x, y: g.size.height * 0.72 + d.len / 2)
                }
            }
        }
        .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))
    }
}

struct BulkScene: View {
    let frame: BulkFrame
    let phrase: String
    let tipsy: Double
    /// Подарки в комнате и граффити на стене.
    var gifts: [String] = []
    var tags: [WallTag] = []
    /// Время кадра в секундах — от него качается лампа и подрагивает кроссовок.
    var clock: Double = 0
    /// Ближайший план («🔔 18:00 — тренировка»), пусто — планов нет.
    var upcoming: String = ""

    // лампа качается всегда, сильнее — когда Бульк на ней висит
    private var lampSway: Double {
        (sin(clock * 1.3) * 4 + sin(clock * 0.47) * 2) * (frame.lift > 0.8 ? 2.5 : 1)
    }

    // кроссовок сам не дёргается (Марк попросил убрать) — двигается, только когда Бульк его пинает
    private var shoeHop: Bool { false }

    private var action: BulkAction { frame.action }
    private var lightOn: Bool { frame.light }

    var body: some View {
        GeometryReader { geo in
            content(w: geo.size.width, h: geo.size.height)
        }
    }

    private var drunkLook: Bool { tipsy > 0.4 && [.chill, .stare, .wave].contains(action) }

    @ViewBuilder
    private func content(w: CGFloat, h: CGFloat) -> some View {
        let floorY = h * 0.86
        let lampX = w * CGFloat(BulkScript.lampX)
        let bulbY = h * 0.2
        let bodyH = h * 0.38
        let bodyW = bodyH * 0.95
        let f = frame.pose
        let sx = CGFloat(f.sx), sy = CGFloat(f.sy)
        let lift = CGFloat(frame.lift)
        let hangBottom = bulbY + 10 + bodyH * sy
        let bottomY = floorY - (floorY - hangBottom) * lift + CGFloat(f.dy) * 2
        let bx = w * CGFloat(frame.x) + CGFloat(f.dx) * 2
        let dark = !lightOn

        ZStack {
            Color(white: 0.16)
            room(w: w, h: h, floorY: floorY, lampX: lampX, bulbY: bulbY)

            ShoeView(dark: dark)
                .frame(width: 26, height: 17)
                .rotationEffect(.degrees(frame.shoeAir > 0 ? -25 : (shoeHop ? -12 : 0)), anchor: .bottomTrailing)
                .position(x: w * CGFloat(frame.shoeX),
                          y: floorY - 8.5 - h * 0.5 * CGFloat(frame.shoeAir) - (shoeHop ? 7 : 0))

            // граффити на стене
            ForEach(Array(tags.enumerated()), id: \.offset) { _, tag in
                // на росте Булька, а не под потолком
                let half = min(w / 2, CGFloat(tag.text.count) * 6.5 + 10)   // целиком в виджете, не за краем
                GraffitiTag(tag: tag, dim: !lightOn)
                    .position(x: min(max(w * CGFloat(tag.x), half), w - half), y: floorY - bodyH * CGFloat(tag.widgetLift))
            }
            // подарки: на стене висят, на полу стоят
            ForEach(gifts, id: \.self) { gift in
                if let e = Gifts.emoji[gift], let spot = Gifts.spot[gift] {
                    Text(e).font(.system(size: spot.wall == nil ? 15 : 16))
                        .opacity(lightOn ? 1 : 0.35)
                        .position(x: w * CGFloat(spot.x), y: spot.wall.map { floorY * CGFloat($0) } ?? floorY - 9)
                }
            }

            Ellipse().fill(Color.black.opacity(0.45 - 0.3 * Double(lift)))
                .frame(width: bodyW * (1 - 0.4 * lift), height: 5)
                .position(x: bx, y: floorY + 1)

            BulkBody(eyes: f.eyes ?? (drunkLook ? .drunk : action.eyes),
                     mouth: f.mouth ?? (drunkLook ? .wavy : action.mouth),
                     dark: dark,
                     angry: action == .mad || action == .swear,
                     arms: f.arms ?? .rest,
                     holding: frame.holding,
                     blush: min(1, tipsy) * 0.5,
                     look: f.look ?? 0,
                     back: f.back ?? false)
                .frame(width: bodyW * sx, height: bodyH * sy)
                .rotationEffect(.degrees(f.tilt + (drunkLook ? 8 : 0)), anchor: .bottom)
                .position(x: bx, y: bottomY - bodyH * sy / 2)

            effects(bx: bx, topY: bottomY - bodyH * sy, bodyW: bodyW)

            // муха-пасхалка
            if let fx = frame.flyX {
                ZStack {
                    Ellipse().fill(Color.white.opacity(0.55)).frame(width: 5, height: 3).offset(x: -2, y: -2.5)
                    Ellipse().fill(Color.white.opacity(0.55)).frame(width: 5, height: 3).offset(x: 2, y: -2.5)
                    Circle().fill(Color.black).frame(width: 4, height: 4)
                }
                .position(x: w * CGFloat(fx), y: h * CGFloat(frame.flyY))
            }

            if !phrase.isEmpty {
                bubble(phrase)
                    .position(x: lift > 0.5 ? lampX - 78 : min(max(bx, 62), w - 62),
                              y: lift > 0.5 ? h * 0.42 : max(14, bottomY - bodyH * sy - 16))
            }

            // ВРЕМЕННО: в конце строки — диагностика общей памяти с приложением
            if !upcoming.isEmpty {
                Text(upcoming)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 12)
                    .padding(.bottom, 5)
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
        // лампа качается на проводе (угол меняется от кадра к кадру, iOS плавно перетекает)
        lamp(bulbY: bulbY)
            .rotationEffect(.degrees(lampSway), anchor: .top)
            .frame(width: 60, height: bulbY + 30)
            .position(x: lampX, y: (bulbY + 30) / 2)
    }

    private func lamp(bulbY: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(Color(white: 0.22)).frame(width: 1.5, height: bulbY).position(x: 30, y: bulbY / 2)
            RoundedRectangle(cornerRadius: 2).fill(Color(white: lightOn ? 0.35 : 0.2))
                .frame(width: 9, height: 6).position(x: 30, y: bulbY - 5)
            if frame.bulbInLamp {
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
            Text("буэ").font(.system(size: 10, weight: .semibold, design: .rounded)).italic()
                .foregroundStyle(Color.white.opacity(0.65))
                .rotationEffect(.degrees(-12))
                .position(x: bx + bodyW * 0.62, y: topY + bodyW * 0.55)
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
