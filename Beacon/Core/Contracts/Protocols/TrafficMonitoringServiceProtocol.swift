import Foundation


protocol TrafficMonitoringServiceProtocol:Sendable{
    func startMonitoring(interfaceId:String) async throws
    func stopMonitoring(interfaceId:String) async throws
    func fetchLatestSnapshot(interfaceId:String) async throws -> TrafficSnapshot
}
