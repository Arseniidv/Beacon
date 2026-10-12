import Foundation
import Combine
import SwiftUI

public final class NetworkMapViewModel: ObservableObject {
    // MARK: - Published State
    @Published public private(set) var devices: [Device] = []
    @Published public private(set) var networkEvents: [NetworkEvent] = []
    @Published public private(set) var isLoading: Bool = false

    // Общая статистика подсети (для графиков)
    @Published public private(set) var avgCpuUsage: Double = 0.0
    @Published public private(set) var avgRamUsage: Double = 0.0
    @Published public private(set) var networkSpeedMbps: Double = 0.0

    public let subnetRange: String = "192.168.1.0/24"

    public init() {
        loadMockData()
    }

    // MARK: - Public API
    public func startNetworkScan() {
        isLoading = true
        // Имитация сканирования сети хелпером
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isLoading = false
            self?.loadMockData()
        }
    }

    public var totalCount: Int { devices.count }
    public var freeCount: Int { devices.filter { $0.status == .free }.count }
    public var busyCount: Int { devices.filter { $0.status == .busy }.count }
    public var offlineCount: Int { devices.filter { $0.status == .offline }.count }

    // MARK: - Private Methods
    private func loadMockData() {
        // Подгружаем устройства согласно вашей структуре Device
        self.devices = [
            Device(
                name: "Router",
                ip: "192.168.1.1",
                macAddress: "00:1A:2B:3C:4D:01",
                status: .free,
                ping: 1
            ),
            Device(name: "PC-01-ADMIN", ip: "192.168.1.10", macAddress: "00:18:44:11:3A:B7", status: .free, ping: 1, cpuUsage: 12, ramUsage: 28),
            Device(name: "PC-02-DESIGN", ip: "192.168.1.11", macAddress: "00:18:44:11:3A:B8", status: .busy, ping: 2, cpuUsage: 78, ramUsage: 72),
            Device(name: "PC-03-RENDER", ip: "192.168.1.12", macAddress: "00:18:44:11:3A:B9", status: .free, ping: 1, cpuUsage: 6, ramUsage: 18),
            Device(name: "PC-04-OFFICE", ip: "192.168.1.13", macAddress: "00:18:44:11:3A:C0", status: .busy, ping: 3, cpuUsage: 45, ramUsage: 62),
            Device(name: "PC-05-LAB", ip: "192.168.1.14", macAddress: "00:18:44:11:3A:C1", status: .offline),
            Device(name: "PC-06-TEST", ip: "192.168.1.15", macAddress: "00:18:44:11:3A:C2", status: .free, ping: 2, cpuUsage: 18, ramUsage: 34)
        ]

        // Расчет средних метрик для графиков подсети
        let activeDevices = devices.filter { $0.status != .offline }
        self.avgCpuUsage = activeDevices.compactMap { $0.cpuUsage }.reduce(0, +) / Double(activeDevices.count)
        self.avgRamUsage = activeDevices.compactMap { $0.ramUsage }.reduce(0, +) / Double(activeDevices.count)
        self.networkSpeedMbps = 120.0 // Пример константной текущей утилизации канала

        // Логи последних событий
        self.networkEvents = [
            NetworkEvent(time: "14:28", type: .scanCompleted, message: "Сканирование сети завершено. Найдено 52 устройства (28 свободных)"),
            NetworkEvent(time: "14:17", type: .userLeft, message: "PC-01-ADMIN стал свободен. Пользователь вышел из системы"),
            NetworkEvent(time: "13:52", type: .userJoined, message: "PC-04-OFFICE занят. Пользователь: Е. Козлов"),
            NetworkEvent(time: "12:36", type: .timeout, message: "PC-05-LAB недоступен. Устройство не отвечает (ping timeout)")
        ]
    }
}

// MARK: - Supporting Presentation Models
public struct NetworkEvent: Identifiable {
    public let id = UUID()
    public let time: String
    public let type: EventType
    public let message: String

    public enum EventType {
        case scanCompleted, userLeft, userJoined, timeout

        var iconName: String {
            switch self {
            case .scanCompleted: return "checkmark.circle.fill"
            case .userLeft: return "person.crop.circle.badge.minus"
            case .userJoined: return "person.crop.circle.badge.checkmark"
            case .timeout: return "exclamationmark.triangle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .scanCompleted: return .blue
            case .userLeft: return .green
            case .userJoined: return .red
            case .timeout: return .gray
            }
        }
    }
}
