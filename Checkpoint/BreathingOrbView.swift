//
//  BreathingOrbView.swift
//  Checkpoint
//
//  Pixel-faithful port of the Presence breathing orb.
//
//  CSS source (presence/public/index.html):
//    background: radial-gradient(circle at 38% 38%, #a8d8f0, #4a90d9 45%, #1a3a5c)
//    box-shadow (normal):   0 0 60px rgba(137,180,250,.25), 0 0 120px rgba(137,180,250,.08)
//    box-shadow (expanded): 0 0 90px rgba(137,180,250,.40), 0 0 160px rgba(137,180,250,.15)
//    transform: scale(1.2) on inhale, scale(1.0) on exhale — transition: 4s linear
//

import SwiftUI

private enum BreathPhase: CaseIterable {
    case inhale, holdIn, exhale, holdOut

    // Labels from presence/public/index.html breathCycle array
    var label: String {
        switch self {
        case .inhale:  return "inhale\u{2026}"   // inhale…
        case .holdIn:  return "hold\u{2026}"     // hold…
        case .exhale:  return "exhale\u{2026}"   // exhale…
        case .holdOut: return "hold\u{2026}"     // hold…
        }
    }
}

struct BreathingOrbView: View {
    var pattern: BreathingPattern = .box
    var isRunning: Bool = true

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appTheme)   private var theme

    // Drives both scale and glow intensity together (like Presence's .expanded CSS class)
    @State private var isExpanded = false
    @State private var phase: BreathPhase = .holdOut
    @State private var breathTask: Task<Void, Never>?

    // Orb gradient — matte, diffuse highlight with a narrow colour range.
    // The highlight is broad and soft; the rim only slightly darker than the body.
    private var orbGradient: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: theme.orbHighlight, location: 0.00), // soft diffuse highlight
                .init(color: theme.accentLight,  location: 0.30), // light body
                .init(color: theme.accent,        location: 0.60), // main accent
                .init(color: theme.accentDeep,   location: 0.85), // slightly deeper
                .init(color: theme.orbRim,        location: 1.00), // subtle rim
            ],
            center: UnitPoint(x: 0.42, y: 0.36),
            startRadius: 0,
            endRadius: 80          // half of orb diameter (160pt)
        )
    }

    @State private var yarnRotation: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(orbGradient)
                    .frame(width: 160, height: 160)

                if theme.yarnBall {
                    let accent = theme.accentLight
                    let rim    = theme.orbRim
                    Canvas { context, size in
                        context.clip(to: Path(ellipseIn: CGRect(origin: .zero, size: size)))
                        let cx = size.width / 2, cy = size.height / 2
                        let r  = size.width / 2, b  = r * 0.35
                        for i in 0..<7 {
                            let theta = Double(i) * .pi / 7.0 + yarnRotation * .pi / 180
                            var path = Path()
                            for step in 0...80 {
                                let t = Double(step) / 80.0 * 2 * .pi
                                let x = r * cos(t) * cos(theta) - b * sin(t) * sin(theta) + cx
                                let y = r * cos(t) * sin(theta) + b * sin(t) * cos(theta) + cy
                                if step == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else         { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                            path.closeSubpath()
                            let color = i % 2 == 0 ? accent.opacity(0.52) : rim.opacity(0.48)
                            context.stroke(path, with: .color(color), lineWidth: 2.5)
                        }
                    }
                    .frame(width: 160, height: 160)
                    .allowsHitTesting(false)
                }
            }
            // Inner glow: 60px → 30pt radius  |  expanded: 90px → 45pt
            .shadow(color: theme.glowColor.opacity(isExpanded ? 0.40 : 0.25),
                    radius: isExpanded ? 45 : 30)
            // Outer glow: 120px → 60pt radius  |  expanded: 160px → 80pt
            .shadow(color: theme.glowColor.opacity(isExpanded ? 0.15 : 0.08),
                    radius: isExpanded ? 80 : 60)
            .scaleEffect(isExpanded ? 1.2 : 1.0)

            Text(phase.label.uppercased())
                .font(.system(size: 13, weight: .regular))
                .tracking(13 * 0.18)         // letter-spacing: 0.18em
                .foregroundColor(theme.muted)
                .id(phase)
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
        }
        .onAppear { startCycle(); startYarnRotation() }
        .onDisappear { breathTask?.cancel() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { startCycle(); startYarnRotation() }
            else { breathTask?.cancel(); breathTask = nil }
        }
        .onChange(of: pattern) { startCycle() }
        .onChange(of: isRunning) { _, running in
            if running { startCycle(); startYarnRotation() }
            else { breathTask?.cancel(); breathTask = nil }
        }
    }

    // MARK: - Yarn

    private func startYarnRotation() {
        guard theme.yarnBall else { return }
        withAnimation(.none) { yarnRotation = 0 }
        withAnimation(.linear(duration: 25).repeatForever(autoreverses: false)) {
            yarnRotation = 360
        }
    }

    // MARK: - Cycle

    private func startCycle() {
        breathTask?.cancel()
        // Snap orb back to resting state so every cycle starts clean
        withAnimation(.none) { isExpanded = false }
        phase = .holdOut
        breathTask = Task { @MainActor in
            while !Task.isCancelled {
                // Inhale: expand
                withAnimation(.linear(duration: Double(pattern.inhale))) { isExpanded = true }
                withAnimation(.easeInOut(duration: 0.3)) { phase = .inhale }
                try? await Task.sleep(for: .seconds(pattern.inhale))
                guard !Task.isCancelled else { return }

                // Hold in: no scale change (skip if 0)
                if pattern.holdIn > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) { phase = .holdIn }
                    try? await Task.sleep(for: .seconds(pattern.holdIn))
                    guard !Task.isCancelled else { return }
                }

                // Exhale: contract
                withAnimation(.linear(duration: Double(pattern.exhale))) { isExpanded = false }
                withAnimation(.easeInOut(duration: 0.3)) { phase = .exhale }
                try? await Task.sleep(for: .seconds(pattern.exhale))
                guard !Task.isCancelled else { return }

                // Hold out: no scale change (skip if 0)
                if pattern.holdOut > 0 {
                    withAnimation(.easeInOut(duration: 0.3)) { phase = .holdOut }
                    try? await Task.sleep(for: .seconds(pattern.holdOut))
                    guard !Task.isCancelled else { return }
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        BreathingOrbView()
    }
    .environment(\.appTheme, .midnight)
}
