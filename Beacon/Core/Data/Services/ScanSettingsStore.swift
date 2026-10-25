import Foundation
import Combine

/// Хранит настройки сканирования в UserDefaults и публикует изменения.
@MainActor
final class ScanSettingsStore: ObservableObject {
    @Published var settings: ScanSettings {
        didSet { save() }
    }

    private let key = "beacon.scan.settings"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode(ScanSettings.self, from: data) {
            self.settings = saved
        } else {
            self.settings = .initial
        }
    }

    func reset() {
        settings = .initial
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
