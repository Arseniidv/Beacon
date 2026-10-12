import Foundation

struct DashboardSummary {
    let totalDevices: Int
    let freeDevices: Int
    let busyDevices: Int
    let offlineDevices: Int
    let averageCpuUsage: Double
    let averageRamUsage: Double
    let freeDiskSpace: String
    let totalDiskSpace: String
    let currentSubnet: String
    let lastScanDate: Date

    var freeDevicesChange: Int {
        freeDevices
    }

    var cpuUsageChange: Double {
        averageCpuUsage
    }

    var ramUsageChange: Double {
        averageRamUsage
    }
}
