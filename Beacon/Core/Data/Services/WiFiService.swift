
import Foundation
import CoreLocation
import Network
import NetworkExtension
import Combine

#if os(macOS)
import CoreWLAN
#endif

@MainActor
final class WiFiService: NSObject, WiFiServiceProtocol {

    // MARK: - Private Properties

    private var locationManager: CLLocationManager?
    private var networkMonitor: NWPathMonitor?
    private var scanTask: Task<Void, Never>?
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?

    private var discoveredNetworks: [WiFiNetwork] = []

    private let networksSubject =
        CurrentValueSubject<[WiFiNetwork], Never>([])

    private let isScanningSubject =
        CurrentValueSubject<Bool, Never>(false)

    private var isNetworkAvailable = false

    // MARK: - Public Publishers

    var networks: AnyPublisher<[WiFiNetwork], Never> {
        networksSubject.eraseToAnyPublisher()
    }

    var isScanning: AnyPublisher<Bool, Never> {
        isScanningSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    override init() {
        super.init()

        #if os(iOS)
        setupLocationManager()
        #endif

        setupNetworkMonitor()
    }

    deinit {
        scanTask?.cancel()
        networkMonitor?.cancel()
    }

    // MARK: - Setup

    #if os(iOS)
    private func setupLocationManager() {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager = manager
    }
    #endif

    private func setupNetworkMonitor() {
        let monitor = NWPathMonitor()

        monitor.pathUpdateHandler = {[weak self] path in
            guard let self else{return}
            Task{@MainActor [weak self] in
                self?.isNetworkAvailable = path.status == .satisfied}
        }

        monitor.start(queue: DispatchQueue(label: "NetPulse.WiFiMonitor"))
        networkMonitor = monitor
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        #if os(macOS)
        // CoreWLAN does not require CLLocation authorization.
        return true

        #elseif os(iOS)
        guard let locationManager else {
            return false
        }

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return true

        case .denied, .restricted:
            return false

        case .notDetermined:
            return await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }

        @unknown default:
            return false
        }

        #else
        return false
        #endif
    }

    #if os(iOS)
    private func finishAuthorization(_ granted: Bool) {
        guard let continuation = authorizationContinuation else {
            return
        }

        authorizationContinuation = nil
        continuation.resume(returning: granted)
    }
    #endif

    // MARK: - Scanning

    func startScanning() {
        guard !isScanningSubject.value else {
            return
        }

        scanTask?.cancel()
        discoveredNetworks = []
        networksSubject.send([])
        isScanningSubject.send(true)

        scanTask = Task { [weak self] in
            guard let self else { return }

            let networks = await self.performScan()

            guard !Task.isCancelled else {
                return
            }

            self.discoveredNetworks = networks
            self.networksSubject.send(networks)
            self.isScanningSubject.send(false)
            self.scanTask = nil
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        scanTask = nil
        isScanningSubject.send(false)
    }

    private func performScan() async -> [WiFiNetwork] {
        guard !Task.isCancelled else {
            return []
        }

        #if os(macOS)
        return scanOnMacOS()

        #elseif os(iOS)
        guard isNetworkAvailable else {
            return []
        }

        return await fetchCurrentNetwork()

        #else
        return []
        #endif
    }

    // MARK: - macOS Scanning

    #if os(macOS)

    private func scanOnMacOS() -> [WiFiNetwork] {
        guard let interface = CWWiFiClient.shared().interface() else {
            print("WiFiService: Wi-Fi interface not found")
            return []
        }

        guard interface.powerOn() else {
            print("WiFiService: Wi-Fi is turned off")
            return []
        }

        do {
            let scanned = try interface.scanForNetworks(
                withSSID: nil,
                includeHidden: false
            )

            return scanned
                .compactMap { Self.makeNetwork(from: $0) }
                .sorted { $0.signalStrength > $1.signalStrength }

        } catch {
            print("WiFiService: scan failed: \(error.localizedDescription)")
            return []
        }
    }

    private static func makeNetwork(
        from network: CWNetwork
    ) -> WiFiNetwork? {
        guard let ssid = network.ssid, !ssid.isEmpty else {
            return nil
        }

        let rssi = network.rssiValue
        let channel = network.wlanChannel?.channelNumber ?? 0

        return WiFiNetwork(
            ssid: ssid,
            bssid: network.bssid ?? "",
            signalStrength: rssi,
            channel: channel,
            frequency: frequency(
                for: network.wlanChannel?.channelBand
            ),
            securityType: securityType(for: network),
            distance: estimatedDistance(fromRSSI: rssi)
        )
    }

    private static func frequency(
        for band: CWChannelBand?
    ) -> Double {
        switch band {
        case .band2GHz:
            return 2.4
        case .band5GHz:
            return 5.0
        case .band6GHz:
            return 6.0
        default:
            return 0
        }
    }

    private static func securityType(
        for network: CWNetwork
    ) -> WiFiNetwork.SecurityType {
        if network.supportsSecurity(.wpa3Enterprise) {
            return .wpa3Enterprise
        }

        if network.supportsSecurity(.wpa3Personal) {
            return .wpa3
        }

        if network.supportsSecurity(.wpa2Enterprise) {
            return .wpa2Enterprise
        }

        if network.supportsSecurity(.wpa2Personal) {
            return .wpa2
        }

        if network.supportsSecurity(.wpaPersonal)
            || network.supportsSecurity(.wpaPersonalMixed) {
            return .wpa
        }

        if network.supportsSecurity(.WEP) {
            return .wep
        }

        if network.supportsSecurity(.none) {
            return .none
        }

        return .unknown
    }

    #endif

    // MARK: - iOS Current Network

    #if os(iOS)

    private func fetchCurrentNetwork() async -> [WiFiNetwork] {
        guard !Task.isCancelled else {
            return []
        }

        let current: NEHotspotNetwork? =
            await withCheckedContinuation { continuation in
                NEHotspotNetwork.fetchCurrent {
                    continuation.resume(returning: $0)
                }
            }

        guard !Task.isCancelled,
              let current,
              !current.ssid.isEmpty else {
            return []
        }

        // signalStrength is normalized to 0...1, not measured dBm.
        // This conversion is an approximation for display only.
        let estimatedRSSI = Int(-100 + current.signalStrength * 70)

        return [
            WiFiNetwork(
                ssid: current.ssid,
                bssid: current.bssid,
                signalStrength: estimatedRSSI,
                channel: 0,
                frequency: 0,
                securityType: current.isSecure ? .unknown : .none,
                distance: Self.estimatedDistance(fromRSSI: estimatedRSSI)
            )
        ]
    }

    #endif

    // MARK: - Signal Estimate

    private static func estimatedDistance(fromRSSI rssi: Int) -> Double {
        guard (-100 ... 0).contains(rssi) else {
            return -1
        }

        let txPower = -30
        let ratio = Double(txPower - rssi) / 20.0

        if ratio < 1.0 {
            return pow(10.0, ratio)
        }

        return 0.89976 * pow(ratio, 7.7095) + 0.111
    }
}

// MARK: - CLLocationManagerDelegate

#if os(iOS)
extension WiFiService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            finishAuthorization(true)

        case .denied, .restricted:
            finishAuthorization(false)

        case .notDetermined:
            break

        @unknown default:
            finishAuthorization(false)
        }
    }
}
#endif
