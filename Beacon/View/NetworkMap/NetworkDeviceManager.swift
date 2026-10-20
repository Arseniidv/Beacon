import SwiftUI
import Combine

class NetworkDeviceManager: ObservableObject {
    @Published var totalDevices: Int = 0
    @Published var freeDevices: Int = 0
    @Published var lastChange: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        startMonitoringModules()
    }

    private func startMonitoringModules() {
        Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                let newTotal = Int.random(in: 45...60)
                let newFree = Int.random(in: 15...35)


                let changeDiff = newFree - self.freeDevices
                self.lastChange = changeDiff

                // Обновляем состояние
                self.totalDevices = newTotal
                self.freeDevices = newFree
            }
            .store(in: &cancellables)
    }

    var changeText: String {
        if lastChange >= 0 {
            return "+\(lastChange)"
        } else {
            return "\(lastChange)"
        }
    }

    var changeColor: Color {
        if lastChange > 0 {
            return AppColors.statusSuccess
        } else if lastChange < 0 {
            return AppColors.statusDanger
        } else {
            return AppColors.statusOffline
        }
    }
}
