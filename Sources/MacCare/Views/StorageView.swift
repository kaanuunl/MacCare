import SwiftUI

struct StorageView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var settings = AppSettings.shared
    let diskUsage: (used: Int64, total: Int64)
    let sensorReadings: HardwareSensorReader.SensorReadings
    let trashSize: Int64
    let downloadsSize: Int64
    let onNavigateToCleaner: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: "internaldrive")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(loc.tr(.storageManagement))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.6)
                }
                Text(loc.tr(.storageSubtitle))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // Disk Usage Breakdown
            VStack(alignment: .leading, spacing: 16) {
                cardLabel(loc.tr(.diskDistribution), icon: "chart.bar.fill")

                HStack(spacing: 24) {
                    ZStack {
                        AnimatedRing(
                            progress: diskUsage.total > 0 ? Double(diskUsage.used) / Double(diskUsage.total) : 0,
                            color: Color.primary.opacity(0.85),
                            lineWidth: 10
                        )
                        .frame(width: 90, height: 90)

                        VStack(spacing: 1) {
                            Text(diskUsage.total > 0 ? String(format: "%.0f%%", Double(diskUsage.used) / Double(diskUsage.total) * 100) : "—")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                            Text(loc.tr(.filled))
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        storageRow(loc.tr(.totalSSD), value: SystemInfoHelper.formatBytes(diskUsage.total), color: .primary)
                        storageRow(loc.tr(.usedSpace), value: SystemInfoHelper.formatBytes(diskUsage.used), color: Color.primary.opacity(0.8))
                        storageRow(loc.tr(.freeSpace), value: SystemInfoHelper.formatBytes(max(0, diskUsage.total - diskUsage.used)), color: Color(red: 0.15, green: 0.68, blue: 0.45))
                        Divider()
                        storageRow(loc.tr(.trash), value: SystemInfoHelper.formatBytes(trashSize), color: .orange)
                        storageRow(loc.tr(.downloads), value: SystemInfoHelper.formatBytes(downloadsSize), color: .blue)
                    }
                }
            }
            .padding(20)
            .modernCard()

            // SSD Live Temperature Sensor
            if sensorReadings.ssdAvailable {
                VStack(alignment: .leading, spacing: 12) {
                    cardLabel(loc.tr(.ssdSensorTitle), icon: "thermometer.medium")
                    HStack(spacing: 16) {
                        TemperatureGaugeView(
                            temperature: sensorReadings.ssdTemperature,
                            label: "SSD",
                            icon: "internaldrive"
                        )
                        VStack(alignment: .leading, spacing: 3) {
                            Text(settings.tempUnit.formatDetailed(sensorReadings.ssdTemperature))
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundStyle(tempColor(sensorReadings.ssdTemperature))
                            Text(loc.tr(.ssdSensorSub))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .modernCard()
            }

            // Quick shortcut to cleaner
            Button(action: onNavigateToCleaner) {
                Label(loc.tr(.goToCleaner), systemImage: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func storageRow(_ title: String, value: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
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
}
