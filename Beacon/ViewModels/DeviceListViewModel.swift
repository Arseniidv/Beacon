
import Foundation
import Combine

@MainActor
final class DeviceListViewModel: ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published private(set) var filteredDevices: [Device] = []
    @Published var searchText = "" {
        didSet {
            applyFiltersAndSort()
        }
    }
    @Published var selectedFilter: Device.InterfaceFilter = .all {
        didSet {
            applyFiltersAndSort()
        }
    }
    @Published var sortOption: SortOption = .ip {
        didSet {
            applyFiltersAndSort()
        }
    }
    @Published private(set) var isScanning = false
  @Published private(set) var errorMessage: String? = nil

    private let scanner: LocalNetworkScanner

    init(scanner: LocalNetworkScanner = LocalNetworkScanner()) {
        self.scanner = scanner
    }

    func updateDevices(_ newDevices: [Device]) {
        devices = newDevices
        applyFiltersAndSort()
    }
    private func applyFiltersAndSort() {
        var result = devices
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(query)
                || $0.ip.localizedCaseInsensitiveContains(query)
                || $0.macAddress.localizedCaseInsensitiveContains(query)
            }
        }
        switch selectedFilter {
        case .all:
            break

        case .active:
            result = result.filter { $0.status != .offline }

        case .inactive:
            result = result.filter { $0.status == .offline }
        }

        // 3. Сортировка.
        switch sortOption {
        case .ip:
            result.sort {
                Self.ipSortKey($0.ip) < Self.ipSortKey($1.ip)
            }

        case .hostname:
            result.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name)
                    == .orderedAscending
            }

        case .status:
            result.sort {
                String(describing: $0.status)
                    < String(describing: $1.status)
            }

        case .latency:
            result.sort {
                switch ($0.ping, $1.ping) {
                case let (lhs?, rhs?):
                    return lhs < rhs
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return $0.ip < $1.ip
                }
            }

        case .traffic:
            // Модель Device пока не содержит измеренного трафика.
            // Поэтому используем IP как стабильный порядок.
            result.sort {
                Self.ipSortKey($0.ip) < Self.ipSortKey($1.ip)
            }
        }
        filteredDevices = result
    }
    private static func ipSortKey(_ ip: String) -> UInt64 {
        let octets = ip.split(separator: ".").compactMap {
            UInt64($0)
        }
        guard octets.count == 4, octets.allSatisfy({ $0 <= 255 }) else {
            return UInt64.max
        }
        return octets.reduce(UInt64(0)) {
            ($0 << 8) | $1
        }
    }
    
 
    func scanNetwork(
        subnet: String? = nil,
        timeout: TimeInterval = 1.0
    ) async {
        guard !isScanning else { return }

        isScanning = true
        errorMessage = nil

        defer {
            isScanning = false
        }

        let hosts = await scanner.scan(
            subnet: subnet,
            timeout: timeout
        )

        let mappedDevices = DeviceMapper.map(hosts)
        updateDevices(mappedDevices)

        if mappedDevices.isEmpty {
            errorMessage = "Устройства не обнаружены. Проверь подключение к сети."
        }
    }

}
