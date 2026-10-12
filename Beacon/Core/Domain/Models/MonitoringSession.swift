
import Foundation

struct MonitoringSession: Identifiable, Codable, Sendable {
    let id: UUID
    let interfaceID: String
    let startedAt: Date

    private(set) var endedAt: Date?
    private(set) var status: MonitoringStatus

    init(
        id: UUID = UUID(),
        interfaceID: String,
        startedAt: Date = .now
    ) {
        self.id = id
        self.interfaceID = interfaceID
        self.startedAt = startedAt
        self.endedAt = nil
        self.status = .running
    }

    mutating func finish(
        at date: Date = .now,
        status: MonitoringStatus = .stopped
    ) {
        guard endedAt == nil else {
            return
        }

        guard status == .stopped || status == .failed else {
            return
        }

        endedAt = max(date, startedAt)
        self.status = status
    }
}
