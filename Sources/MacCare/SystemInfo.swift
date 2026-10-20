import AppKit
import Foundation

enum SystemInfoHelper {
    static func diskUsage() -> (used: Int64, total: Int64) {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            let total = (attrs[.systemSize] as? Int64) ?? 0
            let free = (attrs[.systemFreeSize] as? Int64) ?? 0
            return (max(0, total - free), total)
        } catch {
            return (0, 0)
        }
    }

    static func memoryUsage() -> (used: UInt64, total: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total) }
        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        return (min(total, active + wired + compressed), total)
    }

    static func cpuUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCPU: natural_t = 0
        var numCPUInfo: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPU, &cpuInfo, &numCPUInfo)
        guard result == KERN_SUCCESS, let info = cpuInfo else { return 0 }

        var totalUser: Int32 = 0, totalSystem: Int32 = 0, totalIdle: Int32 = 0
        for i in 0..<Int(numCPU) {
            let offset = Int(CPU_STATE_MAX) * i
            totalUser += info[offset + Int(CPU_STATE_USER)]
            totalSystem += info[offset + Int(CPU_STATE_SYSTEM)]
            totalIdle += info[offset + Int(CPU_STATE_IDLE)]
        }

        let total = totalUser + totalSystem + totalIdle
        guard total > 0 else { return 0 }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(numCPUInfo) * vm_size_t(MemoryLayout<integer_t>.size))

        return Double(totalUser + totalSystem) / Double(total) * 100.0
    }

    static func macModelName() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "Mac" }
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    static func cpuBrandString() -> String {
        var size = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return "Apple Silicon" }
        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        let str = String(cString: brand).trimmingCharacters(in: .whitespacesAndNewlines)
        return str.isEmpty ? "Apple Silicon" : str
    }

    static func uptimeString(isTurkish: Bool) -> String {
        let uptime = ProcessInfo.processInfo.systemUptime
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        if hours > 24 {
            let days = hours / 24
            let remainingHours = hours % 24
            if isTurkish {
                return "\(days) gün \(remainingHours) saat"
            } else {
                return "\(days)d \(remainingHours)h"
            }
        }
        if isTurkish {
            return "\(hours) saat \(minutes) dakika"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }

    static func trashSize() -> Int64 {
        let trashURL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".Trash", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: trashURL.path) else { return 0 }
        var totalSize: Int64 = 0
        let enumerator = FileManager.default.enumerator(
            at: trashURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        while let file = enumerator?.nextObject() as? URL {
            if let values = try? file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               values.isDirectory != true {
                totalSize += Int64(values.fileSize ?? 0)
            }
        }
        return totalSize
    }

    static func downloadsSize() -> Int64 {
        let downloadsURL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Downloads", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: downloadsURL.path) else { return 0 }
        var totalSize: Int64 = 0
        let enumerator = FileManager.default.enumerator(
            at: downloadsURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        while let file = enumerator?.nextObject() as? URL {
            if let values = try? file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               values.isDirectory != true {
                totalSize += Int64(values.fileSize ?? 0)
            }
        }
        return totalSize
    }

    static func mailDownloadsSize() -> Int64 {
        let mailURL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library/Containers/com.apple.mail/Data/Library/Mail Downloads", directoryHint: .isDirectory)
        guard FileManager.default.fileExists(atPath: mailURL.path) else { return 0 }
        var totalSize: Int64 = 0
        let enumerator = FileManager.default.enumerator(
            at: mailURL,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: []
        )
        while let file = enumerator?.nextObject() as? URL {
            if let values = try? file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
               values.isDirectory != true {
                totalSize += Int64(values.fileSize ?? 0)
            }
        }
        return totalSize
    }

    static func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
