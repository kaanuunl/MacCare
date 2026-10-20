import Foundation
import IOKit

enum HardwareSensorReader {
    struct SensorReadings: Sendable {
        var cpuTemperature: Double = 0
        var gpuTemperature: Double = 0
        var memoryTemperature: Double = 0
        var ssdTemperature: Double = 0
        var batteryTemperature: Double = 0
        var cpuAvailable: Bool = false
        var gpuAvailable: Bool = false
        var memoryAvailable: Bool = false
        var ssdAvailable: Bool = false
        var batteryAvailable: Bool = false
    }

    // Dynamic IOHIDEventSystemClient bindings
    @_silgen_name("IOHIDEventSystemClientCreate")
    private static func IOHIDEventSystemClientCreate(_ allocator: CFAllocator?) -> Unmanaged<AnyObject>?

    @_silgen_name("IOHIDEventSystemClientSetMatching")
    private static func IOHIDEventSystemClientSetMatching(_ client: AnyObject, _ matches: CFDictionary) -> Int32

    @_silgen_name("IOHIDEventSystemClientCopyServices")
    private static func IOHIDEventSystemClientCopyServices(_ client: AnyObject) -> CFArray?

    @_silgen_name("IOHIDServiceClientCopyProperty")
    private static func IOHIDServiceClientCopyProperty(_ service: AnyObject, _ property: CFString) -> AnyObject?

    @_silgen_name("IOHIDServiceClientCopyEvent")
    private static func IOHIDServiceClientCopyEvent(_ service: AnyObject, _ type: Int64, _ options: Int32, _ timeout: Double) -> AnyObject?

    @_silgen_name("IOHIDEventGetFloatValue")
    private static func IOHIDEventGetFloatValue(_ event: AnyObject, _ field: UInt32) -> Double

    private static let IOHIDEventTypeTemperature: Int64 = 15
    private static let kIOHIDEventFieldTemperatureLevel: UInt32 = (15 << 16)

    static func readTemperatures() -> SensorReadings {
        var readings = SensorReadings()

        // 1. Primary engine: IOHIDEventSystemClient (Apple Silicon M-series & modern macOS)
        if let clientObj = IOHIDEventSystemClientCreate(kCFAllocatorDefault) {
            let client = clientObj.takeRetainedValue()
            let matching: [String: Any] = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 5]
            _ = IOHIDEventSystemClientSetMatching(client, matching as CFDictionary)

            if let services = IOHIDEventSystemClientCopyServices(client) as? [AnyObject], !services.isEmpty {
                var cpuTemps: [Double] = []
                var gpuTemps: [Double] = []
                var memTemps: [Double] = []
                var ssdTemps: [Double] = []
                var batTemps: [Double] = []

                for service in services {
                    guard let name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String else { continue }
                    guard let event = IOHIDServiceClientCopyEvent(service, IOHIDEventTypeTemperature, 0, 0) else { continue }
                    let temp = IOHIDEventGetFloatValue(event, kIOHIDEventFieldTemperatureLevel)
                    guard temp > 0 && temp < 130 else { continue }

                    let lower = name.lowercased()

                    if lower.contains("nand") || lower.contains("ssd") || lower.contains("nvme") || lower.contains("storage") {
                        ssdTemps.append(temp)
                    } else if lower.contains("battery") || lower.contains("gas gauge") {
                        batTemps.append(temp)
                    } else if lower.contains("pmu2 tdie") || lower.contains("lpddr") || lower.contains("dram") || lower.contains("ram") || lower.contains("memory") {
                        memTemps.append(temp)
                    } else if lower.contains("gpu") || lower.contains("graphics") {
                        gpuTemps.append(temp)
                    } else if lower.contains("cpu") || lower.contains("core") {
                        cpuTemps.append(temp)
                    } else if lower.hasPrefix("pmu tdie") {
                        // Apple Silicon PMU die sensors
                        if lower.contains("tdie1") || lower.contains("tdie6") || lower.contains("tdie7") || lower.contains("tdie8") {
                            cpuTemps.append(temp)
                        } else {
                            gpuTemps.append(temp)
                        }
                    }
                }

                if !cpuTemps.isEmpty {
                    readings.cpuTemperature = cpuTemps.reduce(0, +) / Double(cpuTemps.count)
                    readings.cpuAvailable = true
                }
                if !gpuTemps.isEmpty {
                    readings.gpuTemperature = gpuTemps.reduce(0, +) / Double(gpuTemps.count)
                    readings.gpuAvailable = true
                }
                if !memTemps.isEmpty {
                    readings.memoryTemperature = memTemps.reduce(0, +) / Double(memTemps.count)
                    readings.memoryAvailable = true
                }
                if !ssdTemps.isEmpty {
                    readings.ssdTemperature = ssdTemps.reduce(0, +) / Double(ssdTemps.count)
                    readings.ssdAvailable = true
                }
                if !batTemps.isEmpty {
                    readings.batteryTemperature = batTemps.reduce(0, +) / Double(batTemps.count)
                    readings.batteryAvailable = true
                }
            }
        }

        // 2. Fallback to AppleSMC (Legacy Intel Macs)
        if !readings.cpuAvailable {
            let legacy = readLegacySMC()
            if legacy.cpuAvailable { readings.cpuTemperature = legacy.cpuTemperature; readings.cpuAvailable = true }
            if legacy.gpuAvailable { readings.gpuTemperature = legacy.gpuTemperature; readings.gpuAvailable = true }
            if legacy.memoryAvailable { readings.memoryTemperature = legacy.memoryTemperature; readings.memoryAvailable = true }
            if legacy.ssdAvailable { readings.ssdTemperature = legacy.ssdTemperature; readings.ssdAvailable = true }
        }

        return readings
    }

    private static func readLegacySMC() -> SensorReadings {
        var readings = SensorReadings()
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
        guard service != 0 else { return readings }
        var conn: io_connect_t = 0
        guard IOServiceOpen(service, mach_task_self_, 0, &conn) == kIOReturnSuccess else {
            IOObjectRelease(service)
            return readings
        }
        defer {
            IOServiceClose(conn)
            IOObjectRelease(service)
        }

        func fourCC(_ str: String) -> UInt32 {
            var res: UInt32 = 0
            for c in str.utf8.prefix(4) { res = (res << 8) | UInt32(c) }
            return res
        }

        struct SMCKeyData {
            var key: UInt32 = 0
            var vers = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt16(0))
            var pLimit = (UInt16(0), UInt16(0), UInt32(0), UInt32(0), UInt32(0))
            var keyInfo = (UInt32(0), UInt32(0), UInt8(0))
            var result: UInt8 = 0
            var status: UInt8 = 0
            var data8: UInt8 = 0
            var data32: UInt32 = 0
            var bytes = (UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0),
                         UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0), UInt8(0))
        }

        func readKey(_ key: String) -> Double? {
            var inS = SMCKeyData()
            var outS = SMCKeyData()
            inS.key = fourCC(key)
            inS.data8 = 9
            var outSize = MemoryLayout<SMCKeyData>.size
            let r1 = withUnsafeMutablePointer(to: &inS) { inP in
                withUnsafeMutablePointer(to: &outS) { outP in
                    IOConnectCallStructMethod(conn, 2, inP, MemoryLayout<SMCKeyData>.size, outP, &outSize)
                }
            }
            guard r1 == kIOReturnSuccess && outS.result == 0 else { return nil }

            inS.keyInfo = outS.keyInfo
            inS.data8 = 5
            outS = SMCKeyData()
            outSize = MemoryLayout<SMCKeyData>.size

            let r2 = withUnsafeMutablePointer(to: &inS) { inP in
                withUnsafeMutablePointer(to: &outS) { outP in
                    IOConnectCallStructMethod(conn, 2, inP, MemoryLayout<SMCKeyData>.size, outP, &outSize)
                }
            }
            guard r2 == kIOReturnSuccess && outS.result == 0 else { return nil }

            if inS.keyInfo.1 == fourCC("flt ") {
                var f: Float = 0
                withUnsafeBytes(of: outS.bytes) { f = $0.load(as: Float.self) }
                return Double(f)
            } else if inS.keyInfo.1 == fourCC("sp78") {
                var b0: UInt8 = 0, b1: UInt8 = 0
                withUnsafeBytes(of: outS.bytes) { b0 = $0[0]; b1 = $0[1] }
                return Double((Int16(b0) << 8) | Int16(b1)) / 256.0
            }
            return nil
        }

        let cpuKeys = ["TC0P", "TC0H", "TC0D", "TC0E", "TC0F", "TC1C", "TC2C"]
        var cTemps: [Double] = []
        for k in cpuKeys { if let t = readKey(k), t > 0 && t < 120 { cTemps.append(t) } }
        if !cTemps.isEmpty { readings.cpuTemperature = cTemps.reduce(0, +) / Double(cTemps.count); readings.cpuAvailable = true }

        let gpuKeys = ["TG0P", "TG0H", "TG0D", "TG1D", "TG0T"]
        var gTemps: [Double] = []
        for k in gpuKeys { if let t = readKey(k), t > 0 && t < 120 { gTemps.append(t) } }
        if !gTemps.isEmpty { readings.gpuTemperature = gTemps.reduce(0, +) / Double(gTemps.count); readings.gpuAvailable = true }

        let memKeys = ["TM0P", "TM1P"]
        var mTemps: [Double] = []
        for k in memKeys { if let t = readKey(k), t > 0 && t < 120 { mTemps.append(t) } }
        if !mTemps.isEmpty { readings.memoryTemperature = mTemps.reduce(0, +) / Double(mTemps.count); readings.memoryAvailable = true }

        let ssdKeys = ["TH0P", "TN0D", "Th1H"]
        var sTemps: [Double] = []
        for k in ssdKeys { if let t = readKey(k), t > 0 && t < 120 { sTemps.append(t) } }
        if !sTemps.isEmpty { readings.ssdTemperature = sTemps.reduce(0, +) / Double(sTemps.count); readings.ssdAvailable = true }

        return readings
    }
}
