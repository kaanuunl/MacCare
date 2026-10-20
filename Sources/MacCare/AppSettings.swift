import Foundation
import ServiceManagement
import SwiftUI

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "celsius"
    case fahrenheit = "fahrenheit"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }

    func format(_ celsiusValue: Double) -> String {
        guard celsiusValue > 0 else { return "—" }
        switch self {
        case .celsius:
            return String(format: "%.0f°C", celsiusValue)
        case .fahrenheit:
            let f = celsiusValue * 9.0 / 5.0 + 32.0
            return String(format: "%.0f°F", f)
        }
    }

    func formatDetailed(_ celsiusValue: Double) -> String {
        guard celsiusValue > 0 else { return "—" }
        switch self {
        case .celsius:
            return String(format: "%.1f°C", celsiusValue)
        case .fahrenheit:
            let f = celsiusValue * 9.0 / 5.0 + 32.0
            return String(format: "%.1f°F", f)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("launch_at_login") var launchAtLoginStored: Bool = false
    @AppStorage("refresh_interval") var refreshInterval: Double = 3.0
    @AppStorage("temp_unit") var tempUnitStored: String = "celsius"
    @AppStorage("sound_effects") var soundEffects: Bool = true

    @Published var launchAtLoginActual: Bool = false
    @Published var launchAtLoginError: String? = nil

    var tempUnit: TemperatureUnit {
        get { TemperatureUnit(rawValue: tempUnitStored) ?? .celsius }
        set {
            tempUnitStored = newValue.rawValue
            objectWillChange.send()
        }
    }

    init() {
        checkLaunchAtLoginStatus()
    }

    func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            launchAtLoginActual = (status == .enabled)
        } else {
            launchAtLoginActual = launchAtLoginStored
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLoginError = nil
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                launchAtLoginActual = (SMAppService.mainApp.status == .enabled)
                launchAtLoginStored = launchAtLoginActual
            } catch {
                launchAtLoginError = error.localizedDescription
                launchAtLoginStored = enabled
                launchAtLoginActual = enabled
            }
        } else {
            launchAtLoginStored = enabled
            launchAtLoginActual = enabled
        }
    }

    func playChimeIfEnabled() {
        guard soundEffects else { return }
        NSSound.beep()
    }

    func resetToDefaults() {
        ThemeManager.shared.theme = .system
        LocalizationManager.shared.language = .english
        tempUnit = .celsius
        refreshInterval = 3.0
        soundEffects = true
        setLaunchAtLogin(false)
    }
}
