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
            let line = Color(white: 0.93)
            let ew = w * 0.16, eh = h * 0.27
            let lw = max(1.4, w * 0.045)
            let stroke = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)

            // румянец
            for cx in [w * 0.1, w * 0.9] {
                let r = CGRect(x: cx - ew * 0.75, y: h * 0.52, width: ew * 1.5, height: eh * 0.38)
                ctx.fill(Path(ellipseIn: r), with: .color(Color(red: 1, green: 0.45, blue: 0.55).opacity(blush)))
            }

            var ectx = ctx
            if glow { ectx.addFilter(.shadow(color: Color.white.opacity(0.9), radius: 3)) }

            for (i, cx) in [w * 0.3, w * 0.7].enumerated() {
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
                    ectx.fill(Path(ellipseIn: CGRect(x: cx - ew2, y: cy - eh2, width: ew2 * 2, height: eh2 * 2)), with: .color(.white))
                    let pr = eyes == .wide ? ew2 * 0.38 : ew2 * 0.58
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
            let mx = w * 0.5, my = h * 0.78, mw = w * 0.13
            let mouthFill = Color(red: 0.44, green: 0.12, blue: 0.18)
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
                p.move(to: CGPoint(x: mx - mw * 0.6, y: my))
                p.addLine(to: CGPoint(x: mx + mw * 0.6, y: my))
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
    var body: some View {
        ZStack {
            if on {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.98, blue: 0.9).opacity(0.65), .clear],
                                         center: .center, startRadius: 0, endRadius: 24))
                    .frame(width: 48, height: 48)
            }
            Circle().fill(on ? Color(red: 1, green: 0.98, blue: 0.9) : Color(white: 0.32))
        }
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
                Ellipse().fill(bodyFill(w: w))
                Ellipse().stroke(rim, lineWidth: 1)
                Ellipse().fill(Color.white.opacity(dark ? 0.06 : 0.3))
                    .frame(width: w * 0.2, height: h * 0.13).position(x: w * 0.33, y: h * 0.2)
                FaceView(eyes: eyes, mouth: mouth, glow: dark, blush: blush)
                    .frame(width: w * 0.6, height: h * 0.62).position(x: w * 0.5, y: h * 0.47)
                if holding == .bottle {
                    BottleView().frame(width: w * 0.12, height: h * 0.42)
                        .rotationEffect(.degrees(-40))
                        .position(x: rh.x - w * 0.06, y: rh.y - h * 0.16)
                }
                hand(at: lh, size: w * 0.17)
                hand(at: rh, size: w * 0.17)
                if holding == .bulb {
                    BulbView(on: false).frame(width: w * 0.17, height: w * 0.17).position(x: w * 0.5, y: h * 0.74)
                }
            }
        }
    }

    private var rim: Color { Color.white.opacity(dark ? 0.1 : 0.22) }

    private var baseColor: Color {
        if angry { return Color(red: 0.45, green: 0.2, blue: 0.22) }
        return dark ? Color(red: 0.15, green: 0.155, blue: 0.18) : Color(red: 0.33, green: 0.34, blue: 0.38)
    }

    private func bodyFill(w: CGFloat) -> RadialGradient {
        let top = angry ? Color(red: 0.7, green: 0.35, blue: 0.35) : Color(white: dark ? 0.24 : 0.56)
        let low = Color(white: dark ? 0.05 : 0.15)
        return RadialGradient(colors: [top, baseColor, low], center: UnitPoint(x: 0.4, y: 0.2),
                              startRadius: 1, endRadius: w * 0.75)
    }

    private func leftHand(w: CGFloat, h: CGFloat) -> CGPoint {
        switch arms {
        case .rest, .wave, .drink: return CGPoint(x: w * 0.02, y: h * 0.65)
        case .up: return CGPoint(x: w * 0.3, y: -h * 0.08)
        case .hold: return CGPoint(x: w * 0.36, y: h * 0.82)
        }
    }

    private func rightHand(w: CGFloat, h: CGFloat) -> CGPoint {
        switch arms {
        case .rest: return CGPoint(x: w * 0.98, y: h * 0.65)
        case .up: return CGPoint(x: w * 0.7, y: -h * 0.08)
        case .wave: return CGPoint(x: w * 1.02, y: h * 0.05)
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
        let bodyH = h * 0.32
        let bodyW = bodyH * 1.6
        let pose = action.pose
        let bx: CGFloat = pose.lift ? lampX : w * pose.x
        let bottomY: CGFloat = pose.lift ? bulbY + 10 + bodyH * pose.sy : floorY
        let dark = !lightOn

        ZStack {
            Color(red: 0.055, green: 0.055, blue: 0.07)
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
                     blush: 0.15 + min(1, tipsy) * 0.5)
                .frame(width: bodyW * pose.sx, height: bodyH * pose.sy)
                .rotationEffect(.degrees(pose.tilt + (drunkLook ? 8 : 0)), anchor: .bottom)
                .position(x: bx, y: bottomY - bodyH * pose.sy / 2)

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
        Rectangle().fill(Color(white: 0.22)).frame(width: 1.5, height: bulbY).position(x: lampX, y: bulbY / 2)
        RoundedRectangle(cornerRadius: 2).fill(Color(white: lightOn ? 0.35 : 0.2))
            .frame(width: 9, height: 6).position(x: lampX, y: bulbY - 5)
        if action != .inDark {
            BulbView(on: lightOn).frame(width: 12, height: 12).position(x: lampX, y: bulbY + 3)
        }
    }

    @ViewBuilder
    private func effects(bx: CGFloat, topY: CGFloat, bodyW: CGFloat) -> some View {
        switch action {
        case .sleep:
            Text("z Z").font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.6))
                .position(x: bx + bodyW * 0.55, y: topY - 4)
        case .dance:
            Text("♪").font(.system(size: 14)).foregroundStyle(Color.white.opacity(0.7))
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
