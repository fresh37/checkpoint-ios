//
//  ParticleEmitterView.swift
//  Checkpoint
//
//  Floating particles that drift upward and fade, used for goal completion celebrations.
//

import SwiftUI

private struct Particle: Identifiable {
    let id = UUID()
    let startX: CGFloat
    let startY: CGFloat
    let endX: CGFloat
    let endY: CGFloat
    let diameter: CGFloat
    let color: Color
    let opacity: Double
    let delay: Double
    let duration: Double
}

struct ParticleEmitterView: View {
    @State private var particles: [Particle] = []
    @State private var animate = false
    @Environment(\.appTheme) private var theme

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height / 2

            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color.opacity(animate ? 0 : particle.opacity))
                    .frame(width: particle.diameter, height: particle.diameter)
                    .position(
                        x: centerX + particle.startX + (animate ? particle.endX : 0),
                        y: centerY + particle.startY + (animate ? particle.endY : 0)
                    )
                    .animation(
                        .easeOut(duration: particle.duration).delay(particle.delay),
                        value: animate
                    )
            }
        }
        .onAppear {
            let palette: [Color] = [theme.accent, theme.accentLight, .white]
            particles = Self.makeParticles(palette: palette)
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                animate = true
            }
        }
    }

    private static func makeParticles(palette: [Color]) -> [Particle] {
        // The emitter frame is offset -80pt relative to the circle center,
        // so the circle center sits 80pt below the emitter center in local coords.
        let circleRadius: CGFloat = 60
        let circleOffsetY: CGFloat = 80

        return (0..<30).map { _ in
            // Top arc: 200°–340° (270° = straight up in SwiftUI screen coords)
            let angleDeg = Double.random(in: 200...340)
            let angleRad = angleDeg * .pi / 180
            let startX = CGFloat(cos(angleRad)) * circleRadius
            let startY = CGFloat(sin(angleRad)) * circleRadius + circleOffsetY

            // Drift radially outward with slight angular jitter
            let travelDist = CGFloat.random(in: 70...120)
            let jitter = Double.random(in: -0.25...0.25)
            let endX = CGFloat(cos(angleRad + jitter)) * travelDist
            let endY = CGFloat(sin(angleRad + jitter)) * travelDist

            return Particle(
                startX: startX,
                startY: startY,
                endX: endX,
                endY: endY,
                diameter: .random(in: 3...6),
                color: palette.randomElement() ?? palette[0],
                opacity: .random(in: 0.50...0.85),
                delay: .random(in: 0...1.5),
                duration: .random(in: 3.0...4.5)
            )
        }
    }
}
