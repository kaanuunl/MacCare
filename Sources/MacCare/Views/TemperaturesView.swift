import SwiftUI

struct TemperaturesView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var settings = AppSettings.shared
    let sensorReadings: HardwareSensorReader.SensorReadings
    let thermalState: ProcessInfo.ThermalState
    let onRefresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: "thermometer.medium")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(loc.tr(.hardwareTemperatures))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .tracking(-0.6)
                    }
                    HStack(spacing: 6) {
                        PulsingDot(color: Color(red: 0.15, green: 0.68, blue: 0.45))
                        Text(loc.tr(.realHardwareSensorsSub))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(action: onRefresh) {
                    Label(loc.tr(.refresh), systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
            }

            // Big Gauges Card
            HStack(spacing: 16) {
                LargeTemperatureGaugeView(
                    temperature: sensorReadings.cpuTemperature,
                    label: loc.tr(.cpu),
                    icon: "cpu",
                    available: sensorReadings.cpuAvailable
                )
                LargeTemperatureGaugeView(
                    temperature: sensorReadings.gpuTemperature,
                    label: loc.tr(.gpu),
                    icon: "gpu",
                    available: sensorReadings.gpuAvailable
                )
                LargeTemperatureGaugeView(
                    temperature: sensorReadings.memoryTemperature,
                    label: loc.tr(.ram),
                    icon: "memorychip",
                    available: sensorReadings.memoryAvailable
                )
                LargeTemperatureGaugeView(
                    temperature: sensorReadings.ssdTemperature,
                    label: loc.tr(.ssd),
                    icon: "internaldrive",
                    available: sensorReadings.ssdAvailable
                )
                if sensorReadings.batteryAvailable {
                    LargeTemperatureGaugeView(
                        temperature: sensorReadings.batteryTemperature,
                        label: loc.tr(.battery),
                        icon: "battery.100",
                        available: sensorReadings.batteryAvailable
                    )
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .modernCard()

            // Thermal State & Detailed Table
            HStack(spacing: 14) {
                // Thermal State Card
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel(loc.tr(.thermalState), icon: "flame")
                    HStack(spacing: 12) {
                        Image(systemName: thermalSymbol)
                            .font(.system(size: 30))
                            .foregroundStyle(thermalColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(thermalTitle)
                                .font(.system(size: 20, weight: .bold))
                            Text(thermalDescription)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modernCard()

                // Live Temperature Table
                VStack(alignment: .leading, spacing: 10) {
                    cardLabel(loc.tr(.tempTable), icon: "chart.xyaxis.line")
                    VStack(alignment: .leading, spacing: 8) {
                        tempTableRow("CPU", temp: sensorReadings.cpuAvailable ? sensorReadings.cpuTemperature : nil)
                        tempTableRow("GPU", temp: sensorReadings.gpuAvailable ? sensorReadings.gpuTemperature : nil)
                        tempTableRow("RAM", temp: sensorReadings.memoryAvailable ? sensorReadings.memoryTemperature : nil)
                        tempTableRow("SSD", temp: sensorReadings.ssdAvailable ? sensorReadings.ssdTemperature : nil)
                        if sensorReadings.batteryAvailable {
                            tempTableRow("BAT", temp: sensorReadings.batteryTemperature)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modernCard()
            }

            // Sensor note
            Label {
                Text(loc.tr(.sensorNotice))
            } icon: {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(Color(red: 0.15, green: 0.68, blue: 0.45))
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
        }
    }

    private func tempTableRow(_ label: String, temp: Double?) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 36, alignment: .leading)
            if let temp {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.primary.opacity(0.08))
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(tempColor(temp))
                            .frame(width: max(0, geo.size.width * min(temp / 105.0, 1.0)))
                    }
                }
                .frame(height: 7)
                Text(settings.tempUnit.formatDetailed(temp))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(tempColor(temp))
                    .frame(width: 55, alignment: .trailing)
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
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

    private var thermalDescription: String {
        switch thermalState {
        case .nominal: return loc.tr(.descNormal)
        case .fair: return loc.tr(.descFair)
        case .serious: return loc.tr(.descSerious)
        case .critical: return loc.tr(.descCritical)
        @unknown default: return "Telemetry unavailable"
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
