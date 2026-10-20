import SwiftUI

struct OverviewView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var settings = AppSettings.shared
    let cpuUsage: Double
    let memoryUsage: (used: UInt64, total: UInt64)
    let diskUsage: (used: Int64, total: Int64)
    let sensorReadings: HardwareSensorReader.SensorReadings
    let thermalState: ProcessInfo.ThermalState
    let onNavigate: (String) -> Void
    let onRefresh: () -> Void
    let isScanning: Bool

    @State private var hoveredCard: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 10) {
                        MacCareLogoView(size: 26)
                        Text(loc.tr(.navOverview))
                            .font(.system(size: 27, weight: .bold, design: .rounded))
                            .tracking(-0.6)
                    }
                    Text(loc.tr(.headerSubtitle))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onRefresh) {
                    Label(isScanning ? loc.tr(.scanning) : loc.tr(.refresh), systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .disabled(isScanning)
            }

            // Top Row: CPU & RAM Cards
            HStack(spacing: 14) {
                cpuCard
                memoryCard
            }

            // Middle Row: Live Temperatures & System Storage
            HStack(spacing: 14) {
                temperatureCard
                storageCard
            }

            // Quick Actions
            quickActionsSection
        }
    }

    // MARK: - CPU Card

    private var cpuCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardLabel(loc.tr(.cpuUsage), icon: "cpu")

            HStack(spacing: 16) {
                ZStack {
                    AnimatedRing(
                        progress: cpuUsage / 100.0,
                        color: cpuUsage > 80 ? .red : Color(red: 0.15, green: 0.68, blue: 0.45),
                        lineWidth: 7
                    )
                    .frame(width: 58, height: 58)

                    Text(String(format: "%.0f%%", cpuUsage))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(String(format: "%.1f%%", cpuUsage))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(loc.tr(.coresActive, ProcessInfo.processInfo.activeProcessorCount))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if sensorReadings.cpuAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 9))
                            Text(settings.tempUnit.formatDetailed(sensorReadings.cpuTemperature))
                        }
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(tempColor(sensorReadings.cpuTemperature))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
        .modernCard(isHovered: hoveredCard == "cpu")
        .onHover { hoveredCard = $0 ? "cpu" : nil }
    }

    // MARK: - Memory Card

    private var memoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardLabel(loc.tr(.memoryUsage), icon: "memorychip")

            HStack(spacing: 16) {
                ZStack {
                    AnimatedRing(
                        progress: memoryUsage.total > 0 ? Double(memoryUsage.used) / Double(memoryUsage.total) : 0,
                        color: Color.primary.opacity(0.85),
                        lineWidth: 7
                    )
                    .frame(width: 58, height: 58)

                    Image(systemName: "memorychip")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(SystemInfoHelper.formatBytes(Int64(memoryUsage.used)))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("/ \(SystemInfoHelper.formatBytes(Int64(memoryUsage.total)))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    if sensorReadings.memoryAvailable {
                        HStack(spacing: 4) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 9))
                            Text(settings.tempUnit.formatDetailed(sensorReadings.memoryTemperature))
                        }
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(tempColor(sensorReadings.memoryTemperature))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 155, alignment: .leading)
        .modernCard(isHovered: hoveredCard == "mem")
        .onHover { hoveredCard = $0 ? "mem" : nil }
    }

    // MARK: - Live Temperatures Card

    private var temperatureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                cardLabel(loc.tr(.liveTemperatures), icon: "thermometer.medium")
                Spacer()
                PulsingDot(color: Color(red: 0.15, green: 0.68, blue: 0.45))
                Text(loc.tr(.live))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.15, green: 0.68, blue: 0.45))
            }

            HStack(spacing: 10) {
                TemperatureGaugeView(
                    temperature: sensorReadings.cpuAvailable ? sensorReadings.cpuTemperature : 0,
                    label: "CPU",
                    icon: "cpu"
                )
                TemperatureGaugeView(
                    temperature: sensorReadings.gpuAvailable ? sensorReadings.gpuTemperature : 0,
                    label: "GPU",
                    icon: "gpu"
                )
                TemperatureGaugeView(
                    temperature: sensorReadings.memoryAvailable ? sensorReadings.memoryTemperature : 0,
                    label: "RAM",
                    icon: "memorychip"
                )
                TemperatureGaugeView(
                    temperature: sensorReadings.ssdAvailable ? sensorReadings.ssdTemperature : 0,
                    label: "SSD",
                    icon: "internaldrive"
                )
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 6) {
                Image(systemName: thermalSymbol)
                    .foregroundStyle(thermalColor)
                Text("\(loc.tr(.thermalState)): \(thermalTitle)")
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 165, alignment: .leading)
        .modernCard(isHovered: hoveredCard == "temp")
        .onHover { hoveredCard = $0 ? "temp" : nil }
    }

    // MARK: - Storage Card

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardLabel(loc.tr(.systemStorage), icon: "internaldrive")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(SystemInfoHelper.formatBytes(diskUsage.used))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("/ \(SystemInfoHelper.formatBytes(diskUsage.total))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.primary.opacity(0.9),
                                    Color.primary.opacity(0.6)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: diskUsage.total > 0 ? max(0, geo.size.width * CGFloat(diskUsage.used) / CGFloat(diskUsage.total)) : 0)
                }
            }
            .frame(height: 7)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                if sensorReadings.ssdAvailable {
                    Image(systemName: "thermometer.medium")
                        .foregroundStyle(tempColor(sensorReadings.ssdTemperature))
                    Text("SSD: \(settings.tempUnit.formatDetailed(sensorReadings.ssdTemperature)) (\(loc.tr(.live)))")
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.15, green: 0.68, blue: 0.45))
                    Text(loc.tr(.availableSpace, SystemInfoHelper.formatBytes(max(0, diskUsage.total - diskUsage.used))))
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 165, alignment: .leading)
        .modernCard(isHovered: hoveredCard == "storage")
        .onHover { hoveredCard = $0 ? "storage" : nil }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(loc.tr(.quickActions))
                .font(.system(size: 15, weight: .bold))

            HStack(spacing: 12) {
                quickActionButton(loc.tr(.viewTemperatures), icon: "thermometer.medium") {
                    onNavigate("Temperatures")
                }
                quickActionButton(loc.tr(.cleanSystem), icon: "sparkles") {
                    onNavigate("Cleaner")
                }
                quickActionButton(loc.tr(.manageStorage), icon: "internaldrive") {
                    onNavigate("Storage")
                }
                quickActionButton(loc.tr(.systemSpecs), icon: "info.circle.fill") {
                    onNavigate("System Info")
                }
            }
        }
    }

    private func quickActionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .modernCard()
        }
        .buttonStyle(.plain)
    }

    private func cardLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(0.8)
        }
        .foregroundStyle(.secondary)
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp < 45 { return Color(red: 0.15, green: 0.68, blue: 0.45) }
        if temp < 70 { return Color(red: 0.92, green: 0.68, blue: 0.16) }
        if temp < 85 { return Color(red: 0.94, green: 0.45, blue: 0.16) }
        return Color(red: 0.88, green: 0.25, blue: 0.24)
    }

    private var thermalTitle: String {
        switch thermalState {
        case .nominal: return loc.tr(.statusNormal)
        case .fair: return loc.tr(.statusFair)
        case .serious: return loc.tr(.statusSerious)
        case .critical: return loc.tr(.statusCritical)
        @unknown default: return "Unknown"
        }
    }

    private var thermalSymbol: String {
        switch thermalState {
        case .nominal: return "checkmark.circle.fill"
        case .fair: return "thermometer.low"
        case .serious: return "thermometer.high"
        case .critical: return "exclamationmark.triangle.fill"
        @unknown default: return "questionmark"
        }
    }

    private var thermalColor: Color {
        switch thermalState {
        case .nominal: return Color(red: 0.15, green: 0.68, blue: 0.45)
        case .fair: return Color(red: 0.20, green: 0.54, blue: 0.83)
        case .serious: return Color(red: 0.92, green: 0.57, blue: 0.16)
        case .critical: return Color(red: 0.88, green: 0.25, blue: 0.24)
        @unknown default: return .secondary
        }
    }
}
