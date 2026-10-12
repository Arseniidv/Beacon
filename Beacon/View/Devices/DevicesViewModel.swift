
import Foundation
import SwiftUI
import Combine

// MARK: - Device Filter

public enum DeviceFilter: String, CaseIterable, Identifiable {
    case all = "Все"
    case free = "Свободен"
    case busy = "Занят"
    case offline = "Оффлайн"

    public var id: Self { self }
}

// MARK: - Device Sorting

enum DeviceSortOption: String, CaseIterable, Identifiable {
    case name = "По имени"
    case ip = "По IP"
    case status = "По статусу"
    case ping = "По пингу"

    var id: Self { self }
}

// MARK: - Device ViewModel

@MainActor
final class DeviceViewModel: ObservableObject {

    // MARK: - Dependencies

    private let fetchDevicesUseCase: FetchDevicesUseCaseProtocol
    private let scanNetworkUseCase: ScanNetworkUseCaseProtocol
    private let reserveDeviceUseCase: ReserveDeviceUseCaseProtocol
    private let connectDeviceUseCase: ConnectDeviceUseCaseProtocol

    // MARK: - State

    @Published var devices: [Device] = []

    @Published var searchText = ""
    @Published var selectedFilter: DeviceFilter = .all
    @Published var selectedSort: DeviceSortOption = .name
    @Published var isLoading = false

    // MARK: - Init

    init(
        fetchDevicesUseCase: FetchDevicesUseCaseProtocol,
        scanNetworkUseCase: ScanNetworkUseCaseProtocol,
        reserveDeviceUseCase: ReserveDeviceUseCaseProtocol,
        connectDeviceUseCase: ConnectDeviceUseCaseProtocol
    ) {
        self.fetchDevicesUseCase = fetchDevicesUseCase
        self.scanNetworkUseCase = scanNetworkUseCase
        self.reserveDeviceUseCase = reserveDeviceUseCase
        self.connectDeviceUseCase = connectDeviceUseCase
    }

    // MARK: - Filtered Devices

    var filteredDevices: [Device] {
        let filtered = devices.filter { device in
            matchesFilter(device) && matchesSearch(device)
        }

        return filtered.sorted(by: compareDevices)
    }

    // MARK: - Statistics

    var totalDevices: Int {
        devices.count
    }

    var freeDevicesCount: Int {
        devices.filter { $0.status == .free }.count
    }

    var busyDevicesCount: Int {
        devices.filter { $0.status == .busy }.count
    }

    var offlineDevicesCount: Int {
        devices.filter { $0.status == .offline }.count
    }

    // MARK: - Actions

    func loadDevices() {
        isLoading = true

        Task {
            do {
                let fetchedDevices = try await fetchDevicesUseCase.execute()
                devices = fetchedDevices
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }

    func scanNetwork(subnet: String = "192.168.1.0/24") {
        isLoading = true

        Task {
            do {
                let scannedDevices = try await scanNetworkUseCase.execute(subnet: subnet)
                devices = scannedDevices
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }

    func reserveDevice(_ device: Device) {
        Task {
            do {
                try await reserveDeviceUseCase.execute(device)
            } catch {
            }
        }
    }

    func connectToDevice(_ device: Device) {
        Task {
            do {
                try await connectDeviceUseCase.execute(device)
            } catch {
            }
        }
    }

    func clearSearch() {
        searchText = ""
    }

    func resetFilters() {
        searchText = ""
        selectedFilter = .all
        selectedSort = .name
    }

    // MARK: - Filtering

    private func matchesFilter(_ device: Device) -> Bool {
        switch selectedFilter {
        case .all:
            return true
        case .free:
            return device.status == .free
        case .busy:
            return device.status == .busy
        case .offline:
            return device.status == .offline
        }
    }

    private func matchesSearch(_ device: Device) -> Bool {
        let query = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return true
        }

        if device.name.localizedCaseInsensitiveContains(query) {
            return true
        }

        if device.ip.localizedCaseInsensitiveContains(query) {
            return true
        }

        if let currentUser = device.currentUser, currentUser.localizedCaseInsensitiveContains(query) {
            return true
        }

        return false
    }

    // MARK: - Sorting

    private func compareDevices(
        _ lhs: Device,
        _ rhs: Device
    ) -> Bool {
        switch selectedSort {
        case .name:
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending

        case .ip:
            return lhs.ip.localizedStandardCompare(rhs.ip) == .orderedAscending

        case .status:
            return statusOrder(lhs.status) < statusOrder(rhs.status)

        case .ping:
            switch (lhs.ping, rhs.ping) {
            case let (left?, right?):
                return left < right
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.name < rhs.name
            }
        }
    }

    private func statusOrder(_ status: DeviceStatus) -> Int {
        switch status {
        case .free:
            return 0
        case .busy:
            return 1
        case .offline:
            return 2
        }
    }
}
