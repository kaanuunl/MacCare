import SwiftUI

struct SplashView: View {
    let onComplete: () -> Void
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var ringScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlePhase: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Obsidian / Deep Charcoal Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.06),
                    Color(red: 0.09, green: 0.09, blue: 0.11),
                    Color(red: 0.05, green: 0.05, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle monochrome floating particles
            ForEach(0..<24, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.08 + Double(i % 3) * 0.05))
                    .frame(width: CGFloat(2 + i % 4), height: CGFloat(2 + i % 4))
                    .offset(
                        x: CGFloat(cos(particlePhase + Double(i) * 0.5)) * CGFloat(60 + i * 8),
                        y: CGFloat(sin(particlePhase + Double(i) * 0.7)) * CGFloat(50 + i * 6)
                    )
                    .blur(radius: CGFloat(i % 2))
            }

            VStack(spacing: 24) {
                ZStack {
                    // Soft Silver Radial Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .opacity(glowOpacity)

                    // Outer Precision Silver Ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(white: 0.85),
                                    Color(white: 0.35),
                                    Color(white: 0.95),
                                    Color(white: 0.40),
                                    Color(white: 0.85)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(ringRotation))
                        .scaleEffect(ringScale)

                    // Inner Fine Segmented Ring
                    Circle()
                        .stroke(
                            Color.white.opacity(0.25),
                            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 6])
                        )
                        .frame(width: 96, height: 96)
                        .rotationEffect(.degrees(-ringRotation * 0.7))
                        .scaleEffect(ringScale)

                    // Center Modern Monochrome Logo
                    MacCareLogoView(size: 64)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                VStack(spacing: 8) {
                    Text("MacCare")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(white: 0.82)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(textOpacity)
                        .overlay {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.6), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60)
                                .offset(x: shimmerOffset)
                                .mask {
                                    Text("MacCare")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                }
                        }

                    Text(loc.tr(.appSubtitle))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .opacity(textOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
                ringScale = 1.0
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                glowOpacity = 1.0
            }
            withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                textOpacity = 1.0
            }
            withAnimation(.linear(duration: 1.5).delay(0.3)) {
                shimmerOffset = 220
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
                onComplete()
            }
        }
    }
}
