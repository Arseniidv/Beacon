import Foundation

protocol  TrafficMonitoringServiceProtocol:Sendable{
    var status:MonitoringStatus{get async}
    func availableInterface() async throws->[NetworkInterface]
    func startMonitoring(interfaceID:String) async throws
    func stopMonitoring() async throws
    func snapshots() ->AsyncStream<TrafficSnapshot> 
}
