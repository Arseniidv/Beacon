import Foundation
import SwiftUI

public enum DeviceStatus: String, Codable, Hashable {
    case free = "Свободен"
    case busy = "Занят"
    case offline = "Недоступен"

    public var color: Color {
        switch self {
        case .free:
            return AppColors.statusSuccess
        case .busy:
            return AppColors.statusDanger
        case .offline:
            return AppColors.statusOffline
        }
    }
}
