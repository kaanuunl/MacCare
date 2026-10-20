import Foundation

struct CacheEntry: Identifiable, Sendable {
    let id: UUID
    let name: String
    let path: URL
    let size: Int64
    let fileCount: Int
    let area: CleanupArea
    let isDirectory: Bool
}

enum CleanupArea: String, Sendable, CaseIterable {
    case userCache
    case systemCache
    case userLogs
    case systemLogs
    case systemVarLogs
    case xcodeDerived
    case xcodeArchives
    case homebrewCache

    func title(isTurkish: Bool) -> String {
        switch self {
        case .userCache: return isTurkish ? "Kullanıcı Önbelleği" : "User Cache"
        case .systemCache: return isTurkish ? "Sistem Önbelleği" : "System Cache"
        case .userLogs: return isTurkish ? "Kullanıcı Günlüğü" : "User Logs"
        case .systemLogs: return isTurkish ? "Sistem Günlüğü" : "System Logs"
        case .systemVarLogs: return isTurkish ? "macOS Sistem Günlüğü" : "macOS System Logs"
        case .xcodeDerived: return isTurkish ? "Xcode Türev Verileri" : "Xcode DerivedData"
        case .xcodeArchives: return isTurkish ? "Xcode Arşivleri" : "Xcode Archives"
        case .homebrewCache: return isTurkish ? "Homebrew Önbelleği" : "Homebrew Cache"
        }
    }

    var iconName: String {
        switch self {
        case .userCache, .systemCache: return "folder.fill"
        case .userLogs, .systemLogs, .systemVarLogs: return "doc.text.fill"
        case .xcodeDerived, .xcodeArchives: return "hammer.fill"
        case .homebrewCache: return "mug.fill"
        }
    }

    var rootURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch self {
        case .userCache:
            return home.appending(path: "Library/Caches", directoryHint: .isDirectory)
        case .systemCache:
            return URL(fileURLWithPath: "/Library/Caches", isDirectory: true)
        case .userLogs:
            return home.appending(path: "Library/Logs", directoryHint: .isDirectory)
        case .systemLogs:
            return URL(fileURLWithPath: "/Library/Logs", isDirectory: true)
        case .systemVarLogs:
            return URL(fileURLWithPath: "/private/var/log", isDirectory: true)
        case .xcodeDerived:
            return home.appending(path: "Library/Developer/Xcode/DerivedData", directoryHint: .isDirectory)
        case .xcodeArchives:
            return home.appending(path: "Library/Developer/Xcode/Archives", directoryHint: .isDirectory)
        case .homebrewCache:
            return home.appending(path: "Library/Caches/Homebrew", directoryHint: .isDirectory)
        }
    }

    var requiresAdministrator: Bool {
        switch self {
        case .systemCache, .systemLogs, .systemVarLogs: return true
        case .userCache, .userLogs, .xcodeDerived, .xcodeArchives, .homebrewCache: return false
        }
    }
}

enum CacheScanner {
    // Prohibited system paths that must never be targeted under any circumstances
    private static let forbiddenPaths: Set<String> = [
        "/",
        "/System",
        "/Library",
        "/Applications",
        "/Users",
        "/bin",
        "/sbin",
        "/usr",
        "/var",
        "/private",
        "/etc",
        "/dev"
    ]

    static func scan() -> [CacheEntry] {
        var entries: [CacheEntry] = []
        let allAreas: [CleanupArea] = CleanupArea.allCases

        for area in allAreas {
            let root = area.rootURL.standardizedFileURL
            guard FileManager.default.fileExists(atPath: root.path) else { continue }

            switch area {
            case .userCache, .systemCache, .xcodeDerived, .xcodeArchives:
                entries.append(contentsOf: scanCacheDirectories(in: root, area: area))
            case .homebrewCache:
                let (size, fileCount) = measure(root)
                if fileCount > 0 {
                    entries.append(CacheEntry(
                        id: UUID(),
                        name: "Homebrew Cache",
                        path: root,
                        size: size,
                        fileCount: fileCount,
                        area: area,
                        isDirectory: true
                    ))
                }
            default:
                entries.append(contentsOf: scanLogFiles(in: root, area: area))
            }
        }
        return entries.sorted { $0.size > $1.size }
    }

    static func remove(_ entries: [CacheEntry]) throws {
        guard !entries.isEmpty else { return }

        let userEntries = entries.filter { !$0.area.requiresAdministrator }
        let administratorEntries = entries.filter(\.area.requiresAdministrator)

        // Strict validation pass before removing anything
        for entry in entries {
            try validate(entry)
        }

        if !administratorEntries.isEmpty {
            try administratorRemove(administratorEntries)
        }
        for entry in userEntries {
            try FileManager.default.removeItem(at: entry.path)
        }
    }

    private static func scanCacheDirectories(in root: URL, area: CleanupArea) -> [CacheEntry] {
        guard let directories = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return directories.compactMap { directory in
            guard let values = try? directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
                  values.isDirectory == true, values.isSymbolicLink != true else { return nil }

            let (size, fileCount) = measure(directory)
            guard fileCount > 0 else { return nil }

            return CacheEntry(
                id: UUID(),
                name: directory.lastPathComponent,
                path: directory,
                size: size,
                fileCount: fileCount,
                area: area,
                isDirectory: true
            )
        }
    }

    private static func scanLogFiles(in root: URL, area: CleanupArea) -> [CacheEntry] {
        let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
        var entries: [CacheEntry] = []
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) { _, _ in
            return true
        }

        while let file = enumerator?.nextObject() as? URL {
            guard let values = try? file.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey, .isSymbolicLinkKey]) else {
                continue
            }
            if values.isSymbolicLink == true {
                enumerator?.skipDescendants()
                continue
            }
            guard values.isDirectory != true,
                  let modifiedAt = values.contentModificationDate,
                  modifiedAt < cutoff,
                  ["log", "crash", "ips"].contains(file.pathExtension.lowercased()) else {
                continue
            }
            entries.append(CacheEntry(
                id: UUID(),
                name: file.lastPathComponent,
                path: file,
                size: Int64(values.fileSize ?? 0),
                fileCount: 1,
                area: area,
                isDirectory: false
            ))
        }

        return entries
    }

    private static func validate(_ entry: CacheEntry) throws {
        let rootPath = entry.area.rootURL.resolvingSymlinksInPath().standardizedFileURL.path
        let entryPath = entry.path.resolvingSymlinksInPath().standardizedFileURL.path

        // Reject control characters or null bytes in path
        guard !entryPath.contains("\0"), !entryPath.contains("\n"), !entryPath.contains("\r") else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "Invalid characters in path: \(entry.name)"])
        }

        // Prevent critical system directory deletion
        guard !forbiddenPaths.contains(entryPath) else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "Security policy prohibits removing protected path: \(entryPath)"])
        }

        let isDirectChild = URL(fileURLWithPath: entryPath).deletingLastPathComponent().standardizedFileURL.path == rootPath
        let isDescendant = entryPath.hasPrefix(rootPath + "/")
        let isCacheOrDev = [CleanupArea.userCache, .systemCache, .xcodeDerived, .xcodeArchives].contains(entry.area)
        let isHomebrew = entry.area == .homebrewCache

        if isHomebrew {
            guard entryPath == rootPath || entryPath.hasPrefix(rootPath + "/") else {
                throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "Path boundary violation for \(entry.name)"])
            }
        } else {
            guard entryPath != rootPath, isCacheOrDev ? isDirectChild : isDescendant else {
                throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "Path boundary violation for \(entry.name)"])
            }
        }

        // Verify that target exists and is not a symlink
        let values = try entry.path.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
        guard values.isSymbolicLink != true, values.isDirectory == entry.isDirectory else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "\(entry.name) is invalid or points to a symlink."])
        }

        // Additional age check for logs
        if !isCacheOrDev && !isHomebrew {
            let cutoff = Date.now.addingTimeInterval(-7 * 24 * 60 * 60)
            let allowedExtensions = ["log", "crash", "ips"]
            guard allowedExtensions.contains(entry.path.pathExtension.lowercased()),
                  let modifiedAt = try entry.path.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                  modifiedAt < cutoff else {
                throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "\(entry.name) is active; skipped."])
            }
        }
    }

    private static func administratorRemove(_ entries: [CacheEntry]) throws {
        for entry in entries {
            try validate(entry)
        }

        let script = """
        on run argv
            set commandText to "/bin/rm -rf --"
            repeat with targetPath in argv
                set commandText to commandText & " " & quoted form of targetPath
            end repeat
            do shell script commandText with administrator privileges
        end run
        """
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script, "--"] + entries.map { $0.path.path }
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let result = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let details = String(data: result, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = details.flatMap { $0.isEmpty ? nil : $0 }
                ?? "Administrator authorization was cancelled or cleanup failed."
            throw NSError(
                domain: "MacCare.Cleanup",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
    }

    private static func measure(_ directory: URL) -> (size: Int64, fileCount: Int) {
        var size: Int64 = 0
        var fileCount = 0
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) { _, _ in
            return true
        }

        while let item = enumerator?.nextObject() as? URL {
            guard let values = try? item.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey, .isSymbolicLinkKey]),
                  values.isDirectory != true,
                  values.isSymbolicLink != true else { continue }
            size += Int64(values.fileSize ?? 0)
            fileCount += 1
        }

        return (size, fileCount)
    }
}
