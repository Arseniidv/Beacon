import Foundation
import Combine

/// Протокол репозитория для управления профилями сетей
public protocol NetworkProfileRepositoryProtocol {
    /// Все профили сетей
    var profiles: AnyPublisher<[NetworkProfile], Never> { get }

    /// Активный профиль
    var activeProfile: AnyPublisher<NetworkProfile?, Never> { get }

    /// Создать новый профиль
    func createProfile(_ profile: NetworkProfile) throws

    /// Обновить профиль
    func updateProfile(_ profile: NetworkProfile) throws

    /// Удалить профиль
    func deleteProfile(id: UUID) throws

    /// Установить активный профиль
    func setActiveProfile(id: UUID) throws

    /// Получить профиль по ID
    func getProfile(id: UUID) -> NetworkProfile?

    /// Валидация профиля перед сохранением
    func validateProfile(_ profile: NetworkProfile) throws
}

/// Репозиторий профилей сетей с сохранением в UserDefaults
@MainActor
public final class NetworkProfileRepository: NetworkProfileRepositoryProtocol {
    @Published private var _profiles: [NetworkProfile] = []
    @Published private var _activeProfileID: UUID?

    private let keyProfiles = "beacon.network.profiles"
    private let keyActiveProfile = "beacon.network.activeProfile"
    private let defaults: UserDefaults

    public var profiles: AnyPublisher<[NetworkProfile], Never> {
        $_profiles.eraseToAnyPublisher()
    }

    public var activeProfile: AnyPublisher<NetworkProfile?, Never> {
        $_activeProfileID
            .map { [weak self] id in
                guard let id = id else { return nil }
                return self?._profiles.first { $0.id == id }
            }
            .eraseToAnyPublisher()
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadProfiles()
        loadActiveProfile()
    }

    // MARK: - CRUD Operations

    public func createProfile(_ profile: NetworkProfile) throws {
        try validateProfile(profile)

        // Проверяем уникальность имени
        if _profiles.contains(where: { $0.name == profile.name }) {
            throw NetworkProfileError.duplicateName(profile.name)
        }

        var newProfile = profile
        newProfile.touch()
        _profiles.append(newProfile)
        saveProfiles()
    }

    public func updateProfile(_ profile: NetworkProfile) throws {
        try validateProfile(profile)

        guard let index = _profiles.firstIndex(where: { $0.id == profile.id }) else {
            throw NetworkProfileError.profileNotFound(profile.id)
        }

        // Проверяем уникальность имени (исключая сам профиль)
        if _profiles.contains(where: { $0.name == profile.name && $0.id != profile.id }) {
            throw NetworkProfileError.duplicateName(profile.name)
        }

        var updatedProfile = profile
        updatedProfile.touch()
        _profiles[index] = updatedProfile
        saveProfiles()
    }

    public func deleteProfile(id: UUID) throws {
        guard let index = _profiles.firstIndex(where: { $0.id == id }) else {
            throw NetworkProfileError.profileNotFound(id)
        }

        // Если удаляем активный профиль, сбрасываем активный
        if _activeProfileID == id {
            _activeProfileID = nil
            saveActiveProfile()
        }

        _profiles.remove(at: index)
        saveProfiles()
    }

    public func setActiveProfile(id: UUID) throws {
        guard _profiles.contains(where: { $0.id == id }) else {
            throw NetworkProfileError.profileNotFound(id)
        }

        _activeProfileID = id

        // Деактивируем все остальные профили
        for index in _profiles.indices {
            _profiles[index].isActive = (_profiles[index].id == id)
        }

        saveProfiles()
        saveActiveProfile()
    }

    public func getProfile(id: UUID) -> NetworkProfile? {
        _profiles.first { $0.id == id }
    }

    // MARK: - Validation

    public func validateProfile(_ profile: NetworkProfile) throws {
        // Проверка имени
        guard !profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NetworkProfileError.emptyName
        }

        // Валидация IPv4 конфигурации
        if let ipv4 = profile.ipv4Config {
            try validateIPv4Configuration(ipv4)
        }

        // Валидация сегментов
        for segment in profile.segments {
            try validateSegment(segment)
        }
    }

    private func validateIPv4Configuration(_ config: IPv4Configuration) throws {
        // Проверка подсети
        guard ScanSettings.isValidSubnet(config.subnet) else {
            throw NetworkProfileError.invalidSubnet(config.subnet)
        }

        // Проверка шлюза
        if let gateway = config.gateway {
            guard (try? IPAddress(gateway)) != nil else {
                throw NetworkProfileError.invalidGateway(gateway)
            }
        }

        // Проверка DHCP диапазона
        if let dhcp = config.dhcpRange {
            guard (try? IPAddress(dhcp.startIP)) != nil else {
                throw NetworkProfileError.invalidIPAddress(dhcp.startIP)
            }
            guard (try? IPAddress(dhcp.endIP)) != nil else {
                throw NetworkProfileError.invalidIPAddress(dhcp.endIP)
            }
        }

        // Проверка DNS серверов
        for dns in config.dnsServers {
            guard (try? IPAddress(dns)) != nil else {
                throw NetworkProfileError.invalidIPAddress(dns)
            }
        }
    }

    private func validateSegment(_ segment: NetworkSegment) throws {
        // Проверка подсети
        guard ScanSettings.isValidSubnet(segment.subnet) else {
            throw NetworkProfileError.invalidSubnet(segment.subnet)
        }

        // Проверка VLAN ID
        if let vlanID = segment.vlanID {
            guard (0...4095).contains(vlanID) else {
                throw NetworkProfileError.invalidVLANID(vlanID)
            }
        }
    }

    // MARK: - Persistence

    private func loadProfiles() {
        guard let data = defaults.data(forKey: keyProfiles),
              let profiles = try? JSONDecoder().decode([NetworkProfile].self, from: data) else {
            _profiles = []
            return
        }
        _profiles = profiles
    }

    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(_profiles) else { return }
        defaults.set(data, forKey: keyProfiles)
    }

    private func loadActiveProfile() {
        if let data = defaults.data(forKey: keyActiveProfile),
           let id = try? JSONDecoder().decode(UUID.self, from: data) {
            _activeProfileID = id
        }
    }

    private func saveActiveProfile() {
        guard let id = _activeProfileID,
              let data = try? JSONEncoder().encode(id) else {
            defaults.removeObject(forKey: keyActiveProfile)
            return
        }
        defaults.set(data, forKey: keyActiveProfile)
    }
}

/// Ошибки репозитория профилей сетей
public enum NetworkProfileError: LocalizedError, Equatable {
    case emptyName
    case duplicateName(String)
    case profileNotFound(UUID)
    case invalidSubnet(String)
    case invalidGateway(String)
    case invalidIPAddress(String)
    case invalidVLANID(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Название профиля не может быть пустым"
        case .duplicateName(let name):
            return "Профиль с названием '\(name)' уже существует"
        case .profileNotFound(let id):
            return "Профиль с ID \(id.uuidString) не найден"
        case .invalidSubnet(let subnet):
            return "Некорректная подсеть: \(subnet)"
        case .invalidGateway(let gateway):
            return "Некорректный шлюз: \(gateway)"
        case .invalidIPAddress(let ip):
            return "Некорректный IP-адрес: \(ip)"
        case .invalidVLANID(let vlan):
            return "Некорректный VLAN ID: \(vlan). Допустимый диапазон: 0-4095"
        }
    }
}
