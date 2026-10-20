import SwiftUI

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case turkish = "tr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .turkish: return "Türkçe"
        }
    }

    var flag: String {
        switch self {
        case .english: return "🇺🇸"
        case .turkish: return "🇹🇷"
        }
    }
}

// MARK: - Localization Strings

enum L10nKey: String {
    // App
    case appName
    case appSubtitle
    case safeModeActive

    // Navigation
    case navWorkspace
    case navOverview
    case navTemperatures
    case navCleaner
    case navStorage
    case navSystemInfo
    case navSettings

    // Header & Actions
    case headerSubtitle
    case refresh
    case scanning
    case scan
    case live
    case sensorsActive

    // Overview Cards
    case cpuUsage
    case memoryUsage
    case liveTemperatures
    case systemStorage
    case coresActive
    case availableSpace
    case used
    case total
    case quickActions
    case viewTemperatures
    case cleanSystem
    case manageStorage
    case systemSpecs

    // Temperatures View
    case hardwareTemperatures
    case realHardwareSensorsSub
    case sensorNotice
    case cpu
    case gpu
    case ram
    case ssd
    case battery
    case noSensor
    case thermalState
    case tempTable
    case statusNormal
    case statusFair
    case statusSerious
    case statusCritical
    case descNormal
    case descFair
    case descSerious
    case descCritical

    // Cleaner View
    case macCleaner
    case cleanerSubtitle
    case userCaches
    case systemCaches
    case systemLogs
    case xcodeDerived
    case xcodeArchives
    case homebrewCache
    case trash
    case downloads
    case mailDownloads
    case cleanableItems
    case cleanableItemsSub
    case cleanSelected
    case selectAll
    case deselectAll
    case noItemsToClean
    case noItemsToCleanDesc
    case items
    case cleanupSuccessTitle
    case cleanupSuccessDesc
    case cleanupConfirmTitle
    case cleanupConfirmMsg
    case cancel
    case safetyNote

    // Storage View
    case storageManagement
    case storageSubtitle
    case diskDistribution
    case filled
    case totalSSD
    case usedSpace
    case freeSpace
    case ssdSensorTitle
    case ssdSensorSub
    case goToCleaner

    // System Info View
    case systemInfoTitle
    case systemInfoSubtitle
    case hardwareSection
    case softwareSection
    case liveTelemetry
    case modelIdentifier
    case processor
    case cpuCores
    case totalMemory
    case diskCapacity
    case osVersion
    case uptime
    case currentUser
    case hostName
    case sensorInterface

    // Settings View
    case settingsTitle
    case settingsSubtitle
    case generalSection
    case launchAtLogin
    case launchAtLoginDesc
    case appearanceSection
    case theme
    case themeSystem
    case themeDark
    case themeLight
    case language
    case monitoringSection
    case refreshInterval
    case tempUnit
    case tempUnitCelsius
    case tempUnitFahrenheit
    case soundEffects
    case soundEffectsDesc
    case aboutSection
    case version
    case developer
    case resetToDefaults

    // Menu Bar
    case openMacCare
}

// MARK: - Localization Manager

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @AppStorage("app_language") var currentLanguage: String = "en" {
        didSet {
            objectWillChange.send()
        }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: currentLanguage) ?? .english }
        set { currentLanguage = newValue.rawValue }
    }

    func tr(_ key: L10nKey, _ args: CVarArg...) -> String {
        let isTurkish = (language == .turkish)
        let format = isTurkish ? turkishStrings[key] ?? englishStrings[key] ?? key.rawValue
                               : englishStrings[key] ?? key.rawValue
        if args.isEmpty {
            return format
        }
        return String(format: format, arguments: args)
    }

    private let englishStrings: [L10nKey: String] = [
        .appName: "MacCare",
        .appSubtitle: "Hardware & Maintenance Hub",
        .safeModeActive: "Safe Mode Active",

        .navWorkspace: "WORKSPACE",
        .navOverview: "Overview",
        .navTemperatures: "Temperatures",
        .navCleaner: "Cleaner",
        .navStorage: "Storage",
        .navSystemInfo: "System Info",
        .navSettings: "Settings",

        .headerSubtitle: "Monitor your Mac's hardware health & free up space safely.",
        .refresh: "Refresh",
        .scanning: "Scanning…",
        .scan: "Scan",
        .live: "Live",
        .sensorsActive: "Hardware Sensors Active",

        .cpuUsage: "CPU USAGE",
        .memoryUsage: "MEMORY USAGE (RAM)",
        .liveTemperatures: "LIVE HARDWARE TEMPERATURES",
        .systemStorage: "SYSTEM STORAGE",
        .coresActive: "%d cores active",
        .availableSpace: "%@ available",
        .used: "used",
        .total: "Total",
        .quickActions: "Quick Actions",
        .viewTemperatures: "Temperatures",
        .cleanSystem: "Clean System",
        .manageStorage: "Storage",
        .systemSpecs: "System Specs",

        .hardwareTemperatures: "Real Hardware Temperatures",
        .realHardwareSensorsSub: "Apple Hardware Sensors · Direct, live component thermal telemetry",
        .sensorNotice: "All temperatures are read directly from Apple internal hardware sensors (PMU dies, NAND flash, battery gas gauge). No simulated or artificial values.",
        .cpu: "CPU (Processor)",
        .gpu: "GPU (Graphics)",
        .ram: "RAM (Memory)",
        .ssd: "SSD (Storage)",
        .battery: "Battery",
        .noSensor: "No Sensor",
        .thermalState: "THERMAL STATE",
        .tempTable: "LIVE TEMPERATURE TABLE",
        .statusNormal: "Normal",
        .statusFair: "Fair",
        .statusSerious: "Elevated",
        .statusCritical: "Critical",
        .descNormal: "Your Mac is running within optimal thermal range.",
        .descFair: "Slight warmth detected; performance remains unaffected.",
        .descSerious: "High thermal load; cooling fans may accelerate.",
        .descCritical: "Critical temperature! Thermal throttling may activate to protect hardware.",

        .macCleaner: "Mac Cleaner",
        .cleanerSubtitle: "Safely clear app caches, Xcode junk, old logs, and temporary files.",
        .userCaches: "User Caches",
        .systemCaches: "System Caches",
        .systemLogs: "Logs & Crash Reports",
        .xcodeDerived: "Xcode DerivedData",
        .xcodeArchives: "Xcode Archives",
        .homebrewCache: "Homebrew Cache",
        .trash: "Trash Bin",
        .downloads: "Downloads",
        .mailDownloads: "Mail Downloads",
        .cleanableItems: "Cleanable Items",
        .cleanableItemsSub: "Application caches, diagnostic logs, Xcode build caches, and package downloads.",
        .cleanSelected: "Clean Selected · %@",
        .selectAll: "Select All",
        .deselectAll: "Deselect All",
        .noItemsToClean: "No Items to Clean",
        .noItemsToCleanDesc: "Your supported cache and log directories are completely clean.",
        .items: "items",
        .cleanupSuccessTitle: "Cleanup Completed Successfully!",
        .cleanupSuccessDesc: "%@ of disk space was reclaimed.",
        .cleanupConfirmTitle: "Delete selected items?",
        .cleanupConfirmMsg: "%d items totaling %@ will be removed permanently. System files may require administrator authorization.",
        .cancel: "Cancel",
        .safetyNote: "Only selected temporary caches and logs older than 7 days are removed. Operating system core files and personal documents are never touched.",

        .storageManagement: "Storage & Disk Management",
        .storageSubtitle: "Inspect internal SSD usage and reclaim gigabytes of storage.",
        .diskDistribution: "DISK DISTRIBUTION",
        .filled: "used",
        .totalSSD: "Total SSD",
        .usedSpace: "Used Space",
        .freeSpace: "Free Space",
        .ssdSensorTitle: "SSD TEMPERATURE (LIVE HARDWARE SENSOR)",
        .ssdSensorSub: "Direct thermal sensor reading from internal NAND Flash controller",
        .goToCleaner: "Open Cleaner & Reclaim Space",

        .systemInfoTitle: "System & Hardware Specs",
        .systemInfoSubtitle: "Detailed technical specifications and real-time status of your Mac.",
        .hardwareSection: "HARDWARE",
        .softwareSection: "SOFTWARE & SYSTEM",
        .liveTelemetry: "REAL-TIME TELEMETRY",
        .modelIdentifier: "Model Identifier",
        .processor: "Processor",
        .cpuCores: "CPU Cores",
        .totalMemory: "Physical Memory",
        .diskCapacity: "Storage Capacity",
        .osVersion: "macOS Version",
        .uptime: "System Uptime",
        .currentUser: "Current User",
        .hostName: "Network Hostname",
        .sensorInterface: "Sensor Interface",

        .settingsTitle: "Preferences & Settings",
        .settingsSubtitle: "Customize theme, language, startup behavior, and sensor options.",
        .generalSection: "GENERAL",
        .launchAtLogin: "Launch at Login",
        .launchAtLoginDesc: "Start MacCare automatically when you log into your Mac.",
        .appearanceSection: "APPEARANCE",
        .theme: "Theme Mode",
        .themeSystem: "System Default",
        .themeDark: "Dark Mode",
        .themeLight: "Light Mode",
        .language: "Language",
        .monitoringSection: "MONITORING & TELEMETRY",
        .refreshInterval: "Sensor Refresh Rate",
        .tempUnit: "Temperature Unit",
        .tempUnitCelsius: "Celsius (°C)",
        .tempUnitFahrenheit: "Fahrenheit (°F)",
        .soundEffects: "Sound Effects",
        .soundEffectsDesc: "Play audio confirmation when cleaning finishes.",
        .aboutSection: "ABOUT MACCARE",
        .version: "Version",
        .developer: "Engineered with Swift & SwiftUI for macOS",
        .resetToDefaults: "Reset All Preferences",

        .openMacCare: "Open MacCare"
    ]

    private let turkishStrings: [L10nKey: String] = [
        .appName: "MacCare",
        .appSubtitle: "Donanım & Bakım Merkezi",
        .safeModeActive: "Güvenli Mod Devrede",

        .navWorkspace: "ÇALIŞMA ALANI",
        .navOverview: "Genel Bakış",
        .navTemperatures: "Sıcaklıklar",
        .navCleaner: "Temizleyici",
        .navStorage: "Depolama",
        .navSystemInfo: "Sistem Bilgisi",
        .navSettings: "Ayarlar",

        .headerSubtitle: "Mac'inizin donanım sağlığını izleyin ve güvenle alan açın.",
        .refresh: "Yenile",
        .scanning: "Taranıyor…",
        .scan: "Tara",
        .live: "Canlı",
        .sensorsActive: "Donanım Sensörleri Aktif",

        .cpuUsage: "İŞLEMCİ KULLANIMI",
        .memoryUsage: "BELLEK KULLANIMI (RAM)",
        .liveTemperatures: "CANLI DONANIM SICAKLIKLARI",
        .systemStorage: "SİSTEM DEPOLAMA",
        .coresActive: "%d çekirdek aktif",
        .availableSpace: "%@ kullanılabilir",
        .used: "kullanılıyor",
        .total: "Toplam",
        .quickActions: "Hızlı İşlemler",
        .viewTemperatures: "Sıcaklıklar",
        .cleanSystem: "Sistemi Temizle",
        .manageStorage: "Depolama",
        .systemSpecs: "Sistem Bilgisi",

        .hardwareTemperatures: "Gerçek Donanım Sıcaklıkları",
        .realHardwareSensorsSub: "Apple Donanım Sensörleri · Doğrudan canlı bileşen termal telemetrisi",
        .sensorNotice: "Tüm sıcaklıklar Apple dahili donanım sensörlerinden (PMU die, NAND flash, pil gaz göstergesi) doğrudan okunur. Yapay veya tahminî değer kullanılmaz.",
        .cpu: "İşlemci (CPU)",
        .gpu: "Grafik (GPU)",
        .ram: "Bellek (RAM)",
        .ssd: "Depolama (SSD)",
        .battery: "Batarya (Pil)",
        .noSensor: "Sensör Yok",
        .thermalState: "TERMAL DURUM",
        .tempTable: "CANLI SICAKLIK TABLOSU",
        .statusNormal: "Normal",
        .statusFair: "Ilık",
        .statusSerious: "Yüksek",
        .statusCritical: "Kritik",
        .descNormal: "Mac'iniz ideal termal aralıkta çalışıyor.",
        .descFair: "Hafif ısınma mevcut; performans etkilenmez.",
        .descSerious: "Yüksek termal yük; soğutma fanları devreye girebilir.",
        .descCritical: "Kritik sıcaklık! Donanımı korumak için sistem yavaşlayabilir.",

        .macCleaner: "Mac Temizleyici",
        .cleanerSubtitle: "Uygulama önbelleklerini, Xcode kalıntılarını, eski günlükleri ve geçici dosyaları güvenle silin.",
        .userCaches: "Kullanıcı Önbellekleri",
        .systemCaches: "Sistem Önbellekleri",
        .systemLogs: "Günlükler ve Hata Raporları",
        .xcodeDerived: "Xcode DerivedData",
        .xcodeArchives: "Xcode Arşivleri",
        .homebrewCache: "Homebrew Önbelleği",
        .trash: "Çöp Kutusu",
        .downloads: "İndirilenler",
        .mailDownloads: "Mail İndirmeleri",
        .cleanableItems: "Temizlenebilir Öğeler",
        .cleanableItemsSub: "Uygulama önbellekleri, tanı günlükleri, Xcode derleme önbellekleri ve paket indirmeleri.",
        .cleanSelected: "Seçilenleri Temizle · %@",
        .selectAll: "Tümünü Seç",
        .deselectAll: "Seçimi Kaldır",
        .noItemsToClean: "Temizlenecek Öğe Yok",
        .noItemsToCleanDesc: "Desteklenen önbellek ve günlük klasörleriniz tamamen temiz.",
        .items: "öğe",
        .cleanupSuccessTitle: "Temizlik Başarıyla Tamamlandı!",
        .cleanupSuccessDesc: "%@ disk alanı geri kazanıldı.",
        .cleanupConfirmTitle: "Seçili öğeler silinsin mi?",
        .cleanupConfirmMsg: "%d öğe toplam %@ alan boşaltılarak kalıcı olarak silinecektir. Sistem dosyaları için yönetici onayı gerekebilir.",
        .cancel: "Vazgeç",
        .safetyNote: "Yalnızca seçtiğiniz geçici önbellekler ve 7 günden eski günlük dosyaları silinir. İşletim sistemi çekirdek dosyaları ve kişisel belgeler asla silinmez.",

        .storageManagement: "Depolama & Disk Yönetimi",
        .storageSubtitle: "Dahili SSD kullanımını inceleyin ve gigabaytlarca yer kazanın.",
        .diskDistribution: "DİSK DAĞILIMI",
        .filled: "dolu",
        .totalSSD: "Toplam SSD",
        .usedSpace: "Kullanılan Alan",
        .freeSpace: "Boş Alan",
        .ssdSensorTitle: "SSD SICAKLIĞI (CANLI DONANIM SENSÖRÜ)",
        .ssdSensorSub: "Dahili NAND Flash kontrolcüsünden doğrudan termal sensör verisi",
        .goToCleaner: "Temizleyiciye Git ve Alan Aç",

        .systemInfoTitle: "Sistem ve Donanım Bilgisi",
        .systemInfoSubtitle: "Mac'inizin ayrıntılı teknik özellikleri ve anlık canlı telemetrisi.",
        .hardwareSection: "DONANIM",
        .softwareSection: "YAZILIM VE SİSTEM",
        .liveTelemetry: "ANLIK TELEMETRİ",
        .modelIdentifier: "Model Tanımı",
        .processor: "İşlemci",
        .cpuCores: "CPU Çekirdek Sayısı",
        .totalMemory: "Fiziksel Bellek",
        .diskCapacity: "Depolama Kapasitesi",
        .osVersion: "macOS Sürümü",
        .uptime: "Çalışma Süresi",
        .currentUser: "Geçerli Kullanıcı",
        .hostName: "Ağ Adı",
        .sensorInterface: "Sensör Arayüzü",

        .settingsTitle: "Tercihler ve Ayarlar",
        .settingsSubtitle: "Tema, dil, başlangıç davranışı ve sensör seçeneklerini özelleştirin.",
        .generalSection: "GENEL",
        .launchAtLogin: "Sistem Başlangıcında Çalıştır",
        .launchAtLoginDesc: "Mac'inize giriş yaptığınızda MacCare otomatik olarak başlasın.",
        .appearanceSection: "GÖRÜNÜM",
        .theme: "Tema Modu",
        .themeSystem: "Sistem Varsayılanı",
        .themeDark: "Koyu Tema",
        .themeLight: "Açık Tema",
        .language: "Dil",
        .monitoringSection: "İZLEME VE TELEMETRİ",
        .refreshInterval: "Sensör Yenileme Sıklığı",
        .tempUnit: "Sıcaklık Birimi",
        .tempUnitCelsius: "Celsius (°C)",
        .tempUnitFahrenheit: "Fahrenheit (°F)",
        .soundEffects: "Ses Efektleri",
        .soundEffectsDesc: "Temizlik tamamlandığında bildirim sesi çal.",
        .aboutSection: "MACCARE HAKKINDA",
        .version: "Sürüm",
        .developer: "macOS için Swift & SwiftUI ile geliştirildi",
        .resetToDefaults: "Varsayılan Ayarlara Sıfırla",

        .openMacCare: "MacCare'i Aç"
    ]
}

extension View {
    func tr(_ key: L10nKey, _ args: CVarArg...) -> String {
        LocalizationManager.shared.tr(key, args)
    }
}
