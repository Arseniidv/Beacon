import Foundation
import SwiftUI
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let fetchDevicesUseCase: FetchDevicesUseCaseProtocol

    init(fetchDevicesUseCase: FetchDevicesUseCaseProtocol) {
        self.fetchDevicesUseCase = fetchDevicesUseCase
    }

    func loadDashboard() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let devices = try await fetchDevicesUseCase.execute()
                summary = calculateSummary(from: devices)
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func calculateSummary(from devices: [Device]) -> DashboardSummary {
        let total = devices.count
        let free = devices.filter { $0.status == .free }.count
        let busy = devices.filter { $0.status == .busy }.count
        let offline = devices.filter { $0.status == .offline }.count

        let onlineDevices = devices.filter { $0.status != .offline }
        let avgCpu = onlineDevices.compactMap { $0.cpuUsage }.reduce(0, +) / Double(max(onlineDevices.count, 1))
        let avgRam = onlineDevices.compactMap { $0.ramUsage }.reduce(0, +) / Double(max(onlineDevices.count, 1))

        return DashboardSummary(
            totalDevices: total,
            freeDevices: free,
            busyDevices: busy,
            offlineDevices: offline,
            averageCpuUsage: avgCpu,
            averageRamUsage: avgRam,
            freeDiskSpace: "1.2 TB",
            totalDiskSpace: "2.4 TB",
            currentSubnet: "192.168.1.0/24",
            lastScanDate: Date()
        )
    }
}
