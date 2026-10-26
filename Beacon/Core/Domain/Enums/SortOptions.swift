import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case ip = "IP-адрес"
    case hostname = "Имя устройства"
    case status = "Статус"
    case latency = "Задержка"
    case traffic = "Трафик"

    var id: String {
        rawValue
    }
}

