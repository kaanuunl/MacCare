import SwiftUI

// MARK: - Minimalist Silicon Chip Logo (Apple Silicon Hardware Core, No Letters, No Numbers)

struct MacCareLogoView: View {
    let size: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. Chip Substrate Package (Dark Titanium Square)
            RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.24, green: 0.24, blue: 0.28),
                            Color(red: 0.10, green: 0.10, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.88, height: size * 0.88)
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.65 : 0.25),
                    radius: size * 0.14,
                    x: 0,
                    y: size * 0.05
                )

            // Chip Substrate Silver Rim
            RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.40)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.0, size * 0.035)
                )
                .frame(width: size * 0.88, height: size * 0.88)

            // 2. Chip Pins (3 micro metallic traces on each side)
            ForEach([-1, 0, 1], id: \.self) { offset in
                let spacing = size * 0.22
                let pinThickness = max(1.5, size * 0.04)
                let pinLength = size * 0.10

                // Top & Bottom pins
                Capsule()
                    .fill(Color(white: 0.65))
                    .frame(width: pinThickness, height: pinLength)
                    .offset(x: CGFloat(offset) * spacing, y: -size * 0.44)

                Capsule()
                    .fill(Color(white: 0.65))
                    .frame(width: pinThickness, height: pinLength)
                    .offset(x: CGFloat(offset) * spacing, y: size * 0.44)

                // Left & Right pins
                Capsule()
                    .fill(Color(white: 0.65))
                    .frame(width: pinLength, height: pinThickness)
                    .offset(x: -size * 0.44, y: CGFloat(offset) * spacing)

                Capsule()
                    .fill(Color(white: 0.65))
                    .frame(width: pinLength, height: pinThickness)
                    .offset(x: size * 0.44, y: CGFloat(offset) * spacing)
            }

            // 3. Central Silicon Die (Radiant Platinum Silver Square)
            RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.80, green: 0.82, blue: 0.88),
                            Color(red: 0.45, green: 0.46, blue: 0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.48, height: size * 0.48)
                .shadow(color: Color.white.opacity(0.35), radius: size * 0.06)

            RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
                .strokeBorder(Color.white, lineWidth: max(1.0, size * 0.025))
                .frame(width: size * 0.48, height: size * 0.48)

            // 4. Central Aperture Core Ring
            Circle()
                .fill(Color(red: 0.10, green: 0.10, blue: 0.12))
                .frame(width: size * 0.26, height: size * 0.26)

            Circle()
                .strokeBorder(Color.white, lineWidth: max(1.0, size * 0.03))
                .frame(width: size * 0.26, height: size * 0.26)

            // 5. Central Radiant Diamond Point
            DiamondShape()
                .fill(Color.white)
                .frame(width: size * 0.11, height: size * 0.14)
                .shadow(color: Color.white, radius: size * 0.05)
        }
    }
}

// MARK: - Geometric Diamond Shard

private struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width / 2
        let ry = rect.height / 2

        path.move(to: CGPoint(x: cx, y: cy - ry))
        path.addLine(to: CGPoint(x: cx + rx, y: cy))
        path.addLine(to: CGPoint(x: cx, y: cy + ry))
        path.addLine(to: CGPoint(x: cx - rx, y: cy))
        path.closeSubpath()
        return path
    }
}

// MARK: - Temperature Gauges

struct TemperatureGaugeView: View {
    let temperature: Double
    let label: String
    let icon: String
    @ObservedObject private var settings = AppSettings.shared
    @State private var animatedValue: Double = 0

    private var gaugeColor: Color {
        if temperature < 45 {
            return Color(red: 0.15, green: 0.68, blue: 0.45)
        } else if temperature < 70 {
            return Color(red: 0.92, green: 0.68, blue: 0.16)
        } else if temperature < 85 {
            return Color(red: 0.94, green: 0.45, blue: 0.16)
        } else {
            return Color(red: 0.88, green: 0.25, blue: 0.24)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .trim(from: 0.2, to: 0.8)
                    .stroke(Color.primary.opacity(0.10), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0.2, to: 0.2 + min(max(animatedValue, 0) / 110.0, 1.0) * 0.6)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: 64, height: 64)
                    .shadow(color: gaugeColor.opacity(0.35), radius: 3)

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(gaugeColor)
                    Text(temperature > 0 ? settings.tempUnit.format(temperature) : "—")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }

            VStack(spacing: 1) {
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(temperature > 0 ? statusText : "—")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedValue = temperature
            }
        }
        .onChange(of: temperature) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedValue = newValue
            }
        }
    }

    private var statusText: String {
        if temperature < 45 { return LocalizationManager.shared.tr(.statusNormal) }
        if temperature < 70 { return LocalizationManager.shared.tr(.statusFair) }
        if temperature < 85 { return LocalizationManager.shared.tr(.statusSerious) }
        return LocalizationManager.shared.tr(.statusCritical)
    }
}

struct LargeTemperatureGaugeView: View {
    let temperature: Double
    let label: String
    let icon: String
    let available: Bool
    @ObservedObject private var settings = AppSettings.shared
    @State private var animatedValue: Double = 0
    @State private var glowPulse: Bool = false

    private var gaugeColor: Color {
        if temperature < 45 { return Color(red: 0.15, green: 0.68, blue: 0.45) }
        if temperature < 70 { return Color(red: 0.92, green: 0.68, blue: 0.16) }
        if temperature < 85 { return Color(red: 0.94, green: 0.45, blue: 0.16) }
        return Color(red: 0.88, green: 0.25, blue: 0.24)
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if available && temperature > 65 {
                    Circle()
                        .fill(gaugeColor.opacity(glowPulse ? 0.2 : 0.05))
                        .frame(width: 95, height: 95)
                        .blur(radius: 12)
                }

                Circle()
                    .trim(from: 0.15, to: 0.85)
                    .stroke(Color.primary.opacity(0.10), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(90))
                    .frame(width: 82, height: 82)

                ForEach(0..<9, id: \.self) { i in
                    Rectangle()
                        .fill(Color.primary.opacity(0.20))
                        .frame(width: 1.5, height: 5)
                        .offset(y: -46)
                        .rotationEffect(.degrees(Double(i) * 31.5 - 126))
                }

                Circle()
                    .trim(from: 0.15, to: 0.15 + min(max(animatedValue, 0) / 110.0, 1.0) * 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [gaugeColor.opacity(0.6), gaugeColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(90))
                    .frame(width: 82, height: 82)
                    .shadow(color: gaugeColor.opacity(0.4), radius: 5)

                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(available ? gaugeColor : .secondary)
                    if available {
                        Text(settings.tempUnit.format(temperature))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    } else {
                        Text("—")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                if available {
                    Text(settings.tempUnit.formatDetailed(temperature))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(gaugeColor)
                } else {
                    Text(LocalizationManager.shared.tr(.noSensor))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedValue = available ? temperature : 0
            }
            if available && temperature > 65 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
        .onChange(of: temperature) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedValue = available ? newValue : 0
            }
        }
    }
}

// MARK: - Animated Ring & Pulsing Dot

struct AnimatedRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(animatedProgress, 1.0)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.3), radius: 3)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newValue
            }
        }
    }
}

struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.35))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

struct Notice: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
