import Foundation

/// Профиль локальной сети для администратора
/// Содержит ожидаемую конфигурацию сети для сравнения с фактическим состоянием
public struct NetworkProfile: Identifiable, Codable, Equatable {
    public let id: UUID
    /// Название профиля сети
    public var name: String
    /// Назначение сети (описание использования)
    public var purpose: String
    /// Тип сети
    public var networkType: NetworkType
    /// IPv4 конфигурация
    public var ipv4Config: IPv4Configuration?
    /// Сетевые сегменты
    public var segments: [NetworkSegment]
    /// Известная инфраструктура (маршрутизаторы, коммутаторы и т.д.)
    public var infrastructure: [NetworkInfrastructure]
    /// Является ли профиль активным
    public var isActive: Bool
    /// Дата создания
    public var createdAt: Date
    /// Дата последнего изменения
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        purpose: String = "",
        networkType: NetworkType = .home,
        ipv4Config: IPv4Configuration? = nil,
        segments: [NetworkSegment] = [],
        infrastructure: [NetworkInfrastructure] = [],
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.networkType = networkType
        self.ipv4Config = ipv4Config
        self.segments = segments
        self.infrastructure = infrastructure
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Обновляет дату изменения при любых изменениях профиля
    public mutating func touch() {
        updatedAt = Date()
    }
}

/// Тип сети
public enum NetworkType: String, Codable, CaseIterable, Identifiable {
    case home = "Домашняя"
    case office = "Офисная"
    case server = "Серверная"
    case other = "Другая"

    public var id: String { rawValue }
}

/// IPv4 конфигурация сети
public struct IPv4Configuration: Codable, Equatable {
    /// Подсеть в формате CIDR
    public var subnet: String
    /// Шлюз по умолчанию
    public var gateway: String?
    /// DHCP диапазон
    public var dhcpRange: DHCPRange?
    /// DNS серверы
    public var dnsServers: [String]

    public init(
        subnet: String,
        gateway: String? = nil,
        dhcpRange: DHCPRange? = nil,
        dnsServers: [String] = []
    ) {
        self.subnet = subnet
        self.gateway = gateway
        self.dhcpRange = dhcpRange
        self.dnsServers = dnsServers
    }
}

/// DHCP диапазон
public struct DHCPRange: Codable, Equatable {
    /// Начальный адрес
    public var startIP: String
    /// Конечный адрес
    public var endIP: String

    public init(startIP: String, endIP: String) {
        self.startIP = startIP
        self.endIP = endIP
    }
}

/// Сетевой сегмент
public struct NetworkSegment: Identifiable, Codable, Equatable {
    public let id: UUID
    /// Название сегмента
    public var name: String
    /// Подсеть в формате CIDR
    public var subnet: String
    /// VLAN ID (опционально)
    public var vlanID: Int?
    /// Описание сегмента
    public var description: String?

    public init(
        id: UUID = UUID(),
        name: String,
        subnet: String,
        vlanID: Int? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.subnet = subnet
        self.vlanID = vlanID
        self.description = description
    }
}

/// Элемент сетевой инфраструктуры
public struct NetworkInfrastructure: Identifiable, Codable, Equatable {
    public let id: UUID
    /// Тип оборудования
    public var type: InfrastructureType
    /// Название/идентификатор устройства
    public var name: String
    /// IP-адрес (если известен)
    public var ipAddress: String?
    /// MAC-адрес (если известен)
    public var macAddress: String?
    /// Описание/примечания
    public var notes: String?

    public init(
        id: UUID = UUID(),
        type: InfrastructureType,
        name: String,
        ipAddress: String? = nil,
        macAddress: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.notes = notes
    }
}

/// Тип сетевого оборудования
public enum InfrastructureType: String, Codable, CaseIterable, Identifiable {
    case router = "Маршрутизатор"
    case `switch` = "Коммутатор"
    case accessPoint = "Точка доступа"
    case server = "Сервер"
    case firewall = "Межсетевой экран"
    case gateway = "Шлюз"
    case other = "Другое"

    public var id: String { rawValue }
}
