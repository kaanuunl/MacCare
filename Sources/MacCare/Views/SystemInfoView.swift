import SwiftUI

struct SystemInfoView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var settings = AppSettings.shared
    let cpuUsage: Double
    let memoryUsage: (used: UInt64, total: UInt64)
    let diskUsage: (used: Int64, total: Int64)
    let sensorReadings: HardwareSensorReader.SensorReadings

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(loc.tr(.systemInfoTitle))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.6)
                }
                Text(loc.tr(.systemInfoSubtitle))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // Specs Cards (Hardware & Software)
            HStack(spacing: 14) {
                // Hardware specs
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel(loc.tr(.hardwareSection), icon: "cpu")
                    sysInfoRow(loc.tr(.modelIdentifier), value: SystemInfoHelper.macModelName())
                    sysInfoRow(loc.tr(.processor), value: SystemInfoHelper.cpuBrandString())
                    sysInfoRow(loc.tr(.cpuCores), value: "\(ProcessInfo.processInfo.activeProcessorCount) Cores")
                    sysInfoRow(loc.tr(.totalMemory), value: SystemInfoHelper.formatBytes(Int64(ProcessInfo.processInfo.physicalMemory)))
                    sysInfoRow(loc.tr(.diskCapacity), value: SystemInfoHelper.formatBytes(diskUsage.total))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modernCard()

                // Software specs
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel(loc.tr(.softwareSection), icon: "gearshape")
                    sysInfoRow(loc.tr(.osVersion), value: "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    sysInfoRow(loc.tr(.uptime), value: SystemInfoHelper.uptimeString(isTurkish: loc.language == .turkish))
                    sysInfoRow(loc.tr(.currentUser), value: NSFullUserName())
                    sysInfoRow(loc.tr(.hostName), value: ProcessInfo.processInfo.hostName)
                    sysInfoRow(loc.tr(.sensorInterface), value: "Apple IOHID / SMC")
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modernCard()
            }

            // Real-Time Telemetry Bar
            VStack(alignment: .leading, spacing: 12) {
                cardLabel(loc.tr(.liveTelemetry), icon: "waveform.path.ecg")
                HStack(spacing: 14) {
                    liveStatusItem("CPU", value: String(format: "%.1f%%", cpuUsage))
                    liveStatusItem("RAM", value: SystemInfoHelper.formatBytes(Int64(memoryUsage.used)))
                    liveStatusItem("SSD", value: SystemInfoHelper.formatBytes(diskUsage.used))
                    if sensorReadings.cpuAvailable {
                        liveStatusItem("CPU Temp", value: settings.tempUnit.format(sensorReadings.cpuTemperature))
                    }
                    if sensorReadings.ssdAvailable {
                        liveStatusItem("SSD Temp", value: settings.tempUnit.format(sensorReadings.ssdTemperature))
                    }
                    if sensorReadings.batteryAvailable {
                        liveStatusItem("Battery", value: settings.tempUnit.format(sensorReadings.batteryTemperature))
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modernCard()
        }
    }

    private func sysInfoRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 115, alignment: .leading)
            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private func liveStatusItem(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
}
