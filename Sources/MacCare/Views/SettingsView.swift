import SwiftUI

struct SettingsView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var themeMgr = ThemeManager.shared
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(loc.tr(.settingsTitle))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .tracking(-0.5)
                }
                Text(loc.tr(.settingsSubtitle))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            // General: Launch at Login
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(loc.tr(.generalSection), icon: "power")

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(loc.tr(.launchAtLogin))
                            .font(.system(size: 13, weight: .semibold))
                        Text(loc.tr(.launchAtLoginDesc))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { settings.launchAtLoginActual },
                        set: { settings.setLaunchAtLogin($0) }
                    ))
                    .toggleStyle(.switch)
                }
                .padding(16)
                .modernCard()

                if let err = settings.launchAtLoginError {
                    Text(err)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                }
            }

            // Appearance: Theme Switcher & Language
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(loc.tr(.appearanceSection), icon: "paintpalette.fill")

                VStack(spacing: 14) {
                    // Theme Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc.tr(.theme))
                            .font(.system(size: 12, weight: .semibold))

                        HStack(spacing: 12) {
                            ForEach(AppTheme.allCases) { th in
                                themeCard(th)
                            }
                        }
                    }

                    Divider()

                    // Language Selector
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(loc.tr(.language))
                                .font(.system(size: 13, weight: .semibold))
                            Text("Choose your preferred display language.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $loc.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text("\(lang.flag)  \(lang.displayName)").tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
                .padding(16)
                .modernCard()
            }

            // Monitoring & Sensors
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(loc.tr(.monitoringSection), icon: "waveform.path.ecg")

                VStack(spacing: 14) {
                    // Temperature Unit
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(loc.tr(.tempUnit))
                                .font(.system(size: 13, weight: .semibold))
                            Text("Select temperature display unit.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $settings.tempUnitStored) {
                            Text(loc.tr(.tempUnitCelsius)).tag("celsius")
                            Text(loc.tr(.tempUnitFahrenheit)).tag("fahrenheit")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }

                    Divider()

                    // Refresh Interval
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(loc.tr(.refreshInterval))
                                .font(.system(size: 13, weight: .semibold))
                            Text("How frequently live sensor telemetry refreshes.")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $settings.refreshInterval) {
                            Text("1 sec").tag(1.0)
                            Text("2 sec").tag(2.0)
                            Text("3 sec").tag(3.0)
                            Text("5 sec").tag(5.0)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    Divider()

                    // Sound Effects
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(loc.tr(.soundEffects))
                                .font(.system(size: 13, weight: .semibold))
                            Text(loc.tr(.soundEffectsDesc))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $settings.soundEffects)
                            .toggleStyle(.switch)
                    }
                }
                .padding(16)
                .modernCard()
            }

            // About & Reset
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(loc.tr(.aboutSection), icon: "info.circle")

                HStack(spacing: 16) {
                    MacCareLogoView(size: 42)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("MacCare")
                                .font(.system(size: 14, weight: .bold))
                            Text("v1.0.0 (Build 1)")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.08), in: Capsule())
                        }
                        Text(loc.tr(.developer))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(loc.tr(.resetToDefaults)) {
                        withAnimation {
                            settings.resetToDefaults()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(16)
                .modernCard()
            }
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 4)
    }

    private func themeCard(_ themeOption: AppTheme) -> some View {
        let isSelected = (themeMgr.theme == themeOption)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                themeMgr.theme = themeOption
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: themeOption.iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                Text(loc.tr(themeOption.displayNameKey))
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.20), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.primary.opacity(0.03))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
