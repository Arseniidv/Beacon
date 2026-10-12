
import Foundation

enum MonitoringStatus: String, Codable, CaseIterable, Sendable {
    case stopped
    case starting
    case running
    case stopping
    case failed
}
