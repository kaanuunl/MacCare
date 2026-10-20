import AppKit
import Combine
import SwiftUI

// MARK: - App Entry Point

@main
struct MacCareApp: App {
    @State private var showSplash = true
    @StateObject private var themeMgr = ThemeManager.shared
    @StateObject private var loc = LocalizationManager.shared
    @StateObject private var settings = AppSettings.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ZStack {
                DashboardView()
                    .frame(minWidth: 940, minHeight: 680)
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.45)) {
                            showSplash = false
                        }
                    }
                }
            }
            .preferredColorScheme(themeMgr.theme.colorScheme)
        }
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra {
            MenuBarContentView()
                .preferredColorScheme(themeMgr.theme.colorScheme)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "thermometer.medium")
                if let temp = MenuBarState.shared.cpuTemp {
                    Text(settings.tempUnit.format(temp))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate for Menu Bar

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            let readings = HardwareSensorReader.readTemperatures()
            Task { @MainActor in
                MenuBarState.shared.cpuTemp = readings.cpuAvailable ? readings.cpuTemperature : nil
                MenuBarState.shared.gpuTemp = readings.gpuAvailable ? readings.gpuTemperature : nil
                MenuBarState.shared.memTemp = readings.memoryAvailable ? readings.memoryTemperature : nil
                MenuBarState.shared.ssdTemp = readings.ssdAvailable ? readings.ssdTemperature : nil
                MenuBarState.shared.batTemp = readings.batteryAvailable ? readings.batteryTemperature : nil
                MenuBarState.shared.thermalState = ProcessInfo.processInfo.thermalState
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}

// MARK: - Menu Bar State

@MainActor
final class MenuBarState: ObservableObject {
    static let shared = MenuBarState()
    @Published var cpuTemp: Double?
    @Published var gpuTemp: Double?
    @Published var memTemp: Double?
    @Published var ssdTemp: Double?
    @Published var batTemp: Double?
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
}

// MARK: - Menu Bar Content View

private struct MenuBarContentView: View {
    @ObservedObject private var state = MenuBarState.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                MacCareLogoView(size: 22)
                Text(loc.tr(.appName))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                PulsingDot(color: Color(red: 0.15, green: 0.68, blue: 0.45))
                Text(loc.tr(.live))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 0.15, green: 0.68, blue: 0.45))
            }

            Divider()

            menuBarRow(loc.tr(.cpu), icon: "cpu", temp: state.cpuTemp)
            menuBarRow(loc.tr(.gpu), icon: "gpu", temp: state.gpuTemp)
            menuBarRow(loc.tr(.ram), icon: "memorychip", temp: state.memTemp)
            menuBarRow(loc.tr(.ssd), icon: "internaldrive", temp: state.ssdTemp)
            if let bat = state.batTemp {
                menuBarRow(loc.tr(.battery), icon: "battery.100", temp: bat)
            }

            Divider()

            HStack(spacing: 6) {
                Image(systemName: thermalSymbol)
                    .foregroundStyle(thermalColor)
                Text("\(loc.tr(.thermalState)): \(thermalTitle)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Button {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeKey {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                Text(loc.tr(.openMacCare))
                    .font(.system(size: 12, weight: .semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(16)
        .frame(width: 260)
    }

    private func menuBarRow(_ label: String, icon: String, temp: Double?) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 12))
                .frame(width: 18)
                .foregroundStyle(.secondary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
            Spacer()
            if let temp {
                Text(settings.tempUnit.format(temp))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(tempColor(temp))
            } else {
                Text("—")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp < 45 { return Color(red: 0.15, green: 0.68, blue: 0.45) }
        if temp < 70 { return Color(red: 0.92, green: 0.68, blue: 0.16) }
        if temp < 85 { return Color(red: 0.94, green: 0.45, blue: 0.16) }
        return Color(red: 0.88, green: 0.25, blue: 0.24)
    }

    private var thermalTitle: String {
        switch state.thermalState {
        case .nominal: return loc.tr(.statusNormal)
        case .fair: return loc.tr(.statusFair)
        case .serious: return loc.tr(.statusSerious)
        case .critical: return loc.tr(.statusCritical)
        @unknown default: return "Unknown"
        }
    }

    private var thermalSymbol: String {
        switch state.thermalState {
        case .nominal: return "checkmark.circle.fill"
        case .fair: return "thermometer.low"
        case .serious: return "thermometer.high"
        case .critical: return "exclamationmark.triangle.fill"
        @unknown default: return "questionmark"
        }
    }

    private var thermalColor: Color {
        switch state.thermalState {
        case .nominal: return Color(red: 0.15, green: 0.68, blue: 0.45)
        case .fair: return Color(red: 0.20, green: 0.54, blue: 0.83)
        case .serious: return Color(red: 0.92, green: 0.57, blue: 0.16)
        case .critical: return Color(red: 0.88, green: 0.25, blue: 0.24)
        @unknown default: return .secondary
        }
    }
}
