import SwiftUI

struct DashboardView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var themeMgr = ThemeManager.shared
    @ObservedObject private var settings = AppSettings.shared

    @State private var selectedSection = "Overview"
    @State private var cacheEntries: [CacheEntry] = []
    @State private var selectedCacheIDs = Set<UUID>()
    @State private var isScanning = false
    @State private var isConfirmingCleanup = false
    @State private var notice: Notice?
    @State private var lastScanDate: Date?
    @State private var thermalState = ProcessInfo.processInfo.thermalState
    @State private var sensorReadings = HardwareSensorReader.SensorReadings()
    @State private var cpuUsage: Double = 0
    @State private var memoryUsage: (used: UInt64, total: UInt64) = (0, 0)
    @State private var diskUsage: (used: Int64, total: Int64) = (0, 0)
    @State private var trashSize: Int64 = 0
    @State private var downloadsSize: Int64 = 0
    @State private var mailDownloadsSize: Int64 = 0
    @State private var cleanedSizeFeedback: Int64? = nil
    @State private var showCleanSuccessBanner = false

    private var selectedEntries: [CacheEntry] {
        cacheEntries.filter { selectedCacheIDs.contains($0.id) }
    }

    private var selectedSize: Int64 {
        selectedEntries.reduce(0) { $0 + $1.size }
    }

    private let navItems: [(key: String, l10n: L10nKey, icon: String)] = [
        ("Overview", .navOverview, "square.grid.2x2.fill"),
        ("Temperatures", .navTemperatures, "thermometer.medium"),
        ("Cleaner", .navCleaner, "trash.fill"),
        ("Storage", .navStorage, "internaldrive"),
        ("System Info", .navSystemInfo, "info.circle.fill"),
        ("Settings", .navSettings, "gearshape.fill")
    ]

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            mainDetailView
        }
        .navigationSplitViewStyle(.balanced)
        .tint(Color.primary)
        .onReceive(Timer.publish(every: settings.refreshInterval, on: .main, in: .common).autoconnect()) { _ in
            thermalState = ProcessInfo.processInfo.thermalState
            refreshSensors()
        }
        .alert(item: $notice) { currentNotice in
            Alert(
                title: Text(currentNotice.title),
                message: Text(currentNotice.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            loc.tr(.cleanupConfirmTitle),
            isPresented: $isConfirmingCleanup,
            titleVisibility: .visible
        ) {
            Button(loc.tr(.cleanSelected, SystemInfoHelper.formatBytes(selectedSize)), role: .destructive, action: cleanSelectedCaches)
            Button(loc.tr(.cancel), role: .cancel) {}
        } message: {
            Text(loc.tr(.cleanupConfirmMsg, selectedEntries.count, SystemInfoHelper.formatBytes(selectedSize)))
        }
        .task {
            refreshSensors()
            scanCaches()
            refreshExtraInfo()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Title & Logo
            HStack(spacing: 12) {
                MacCareLogoView(size: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.tr(.appName))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text(loc.tr(.appSubtitle))
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)

            // Nav list
            VStack(alignment: .leading, spacing: 4) {
                Text(loc.tr(.navWorkspace))
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 4)

                ForEach(navItems, id: \.key) { item in
                    sidebarButton(key: item.key, title: loc.tr(item.l10n), icon: item.icon)
                }
            }

            Spacer()

            // Quick Theme Switcher Pill in Sidebar
            HStack(spacing: 6) {
                ForEach(AppTheme.allCases) { th in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            themeMgr.theme = th
                        }
                    } label: {
                        Image(systemName: th.iconName)
                            .font(.system(size: 12))
                            .foregroundStyle(themeMgr.theme == th ? Color.primary : Color.secondary)
                            .frame(maxWidth: .infinity, minHeight: 28)
                            .background {
                                if themeMgr.theme == th {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.primary.opacity(0.12))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 8)

            // Safe Mode Active Label
            Label(loc.tr(.safeModeActive), systemImage: "checkmark.shield.fill")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color(red: 0.15, green: 0.68, blue: 0.45))
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
        }
        .padding(12)
        .frame(minWidth: 215, idealWidth: 235, maxWidth: 260)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func sidebarButton(key: String, title: String, icon: String) -> some View {
        let isSelected = (selectedSection == key)

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                selectedSection = key
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .frame(width: 18)
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                Spacer()
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Detail Router

    private var mainDetailView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Success Banner
                if showCleanSuccessBanner, let cleaned = cleanedSizeFeedback {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color(red: 0.15, green: 0.68, blue: 0.45))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc.tr(.cleanupSuccessTitle))
                                .font(.system(size: 13, weight: .bold))
                            Text(loc.tr(.cleanupSuccessDesc, SystemInfoHelper.formatBytes(cleaned)))
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("✕") {
                            withAnimation { showCleanSuccessBanner = false }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color(red: 0.15, green: 0.68, blue: 0.45).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(red: 0.15, green: 0.68, blue: 0.45).opacity(0.3)))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                switch selectedSection {
                case "Temperatures":
                    TemperaturesView(
                        sensorReadings: sensorReadings,
                        thermalState: thermalState,
                        onRefresh: { refreshSensors() }
                    )
                case "Cleaner":
                    CleanerView(
                        cacheEntries: $cacheEntries,
                        selectedCacheIDs: $selectedCacheIDs,
                        isScanning: $isScanning,
                        isConfirmingCleanup: $isConfirmingCleanup,
                        trashSize: trashSize,
                        downloadsSize: downloadsSize,
                        mailDownloadsSize: mailDownloadsSize,
                        onScan: { scanCaches() },
                        onClean: { isConfirmingCleanup = true }
                    )
                case "Storage":
                    StorageView(
                        diskUsage: diskUsage,
                        sensorReadings: sensorReadings,
                        trashSize: trashSize,
                        downloadsSize: downloadsSize,
                        onNavigateToCleaner: {
                            withAnimation { selectedSection = "Cleaner" }
                        }
                    )
                case "System Info":
                    SystemInfoView(
                        cpuUsage: cpuUsage,
                        memoryUsage: memoryUsage,
                        diskUsage: diskUsage,
                        sensorReadings: sensorReadings
                    )
                case "Settings":
                    SettingsView()
                default:
                    OverviewView(
                        cpuUsage: cpuUsage,
                        memoryUsage: memoryUsage,
                        diskUsage: diskUsage,
                        sensorReadings: sensorReadings,
                        thermalState: thermalState,
                        onNavigate: { target in
                            withAnimation { selectedSection = target }
                        },
                        onRefresh: {
                            refreshSensors()
                            scanCaches()
                            refreshExtraInfo()
                        },
                        isScanning: isScanning
                    )
                }
            }
            .padding(28)
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    // MARK: - Actions

    private func refreshSensors() {
        sensorReadings = HardwareSensorReader.readTemperatures()
        cpuUsage = SystemInfoHelper.cpuUsage()
        memoryUsage = SystemInfoHelper.memoryUsage()
        diskUsage = SystemInfoHelper.diskUsage()
    }

    private func refreshExtraInfo() {
        Task.detached {
            let trash = SystemInfoHelper.trashSize()
            let downloads = SystemInfoHelper.downloadsSize()
            let mail = SystemInfoHelper.mailDownloadsSize()
            await MainActor.run {
                trashSize = trash
                downloadsSize = downloads
                mailDownloadsSize = mail
            }
        }
    }

    private func scanCaches() {
        guard !isScanning else { return }
        isScanning = true

        let entries = CacheScanner.scan()
        cacheEntries = entries
        selectedCacheIDs.formIntersection(Set(entries.map(\.id)))
        lastScanDate = .now
        isScanning = false
    }

    private func cleanSelectedCaches() {
        let entries = selectedEntries
        let freedBytes = selectedSize
        selectedCacheIDs.removeAll()
        isScanning = true

        Task {
            do {
                try await Task.detached {
                    try CacheScanner.remove(entries)
                }.value
                isScanning = false
                cleanedSizeFeedback = freedBytes
                withAnimation { showCleanSuccessBanner = true }
                settings.playChimeIfEnabled()
                scanCaches()
                refreshExtraInfo()
            } catch {
                isScanning = false
                scanCaches()
                notice = Notice(title: "Cleanup Incomplete", message: error.localizedDescription)
            }
        }
    }
}
