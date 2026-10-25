import MapKit
import SwiftUI


@available(iOS 17.0, *)
struct NetworkMapView: View {
 @StateObject private var viewModel: NetworkMapViewModel
    
    init(viewModel: NetworkMapViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        content
            .background(AppColors.backgroundApp)
            .onAppear {
                // 🟢 Fixed: Removed '$' and invoked method properly
                viewModel.requestLocationAuthorization()
                viewModel.startScan()
            }
            .sheet(item: $viewModel.selectedDevice) { device in
                NetworkDeviceDetailView(device: device) {
                    viewModel.select(device)
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
#if os(macOS)
        HStack(spacing: 0) {
            mapCanvas
            deviceListPanel
                .frame(width: AppLayout.detailPanelWidth)
        }
#else
        VStack(spacing: 0) {
            mapCanvas
                .frame(minHeight: 280)
            deviceListPanel
        }
#endif
    }
    
    private var mapCanvas: some View {
        ZStack {
            Map(position: $viewModel.cameraPosition) {
                // 🟢 Fixed: Removed '$' to pass regular elements instead of Bindings
                ForEach(viewModel.deviceClusters) { cluster in
                    Annotation(cluster.title, coordinate: cluster.coordinate) {
                        NetworkClusterAnnotationView(cluster: cluster) {
                            if cluster.isCluster {
                                viewModel.focus(on: cluster)
                            } else if let device = cluster.devices.first {
                                viewModel.select(device)
                            }
                        }
                    }
                }
                
                ForEach(viewModel.bluetoothDevices) { device in
                    Annotation(device.name, coordinate: device.coordinate.clLocationCoordinate) {
                        DeviceAnnotationView(device: device)
                    }
                }
                
                ForEach(viewModel.mappedWiFiNetworks) { network in
                    if let coordinate = network.coordinate {
                        Annotation(network.ssid, coordinate: coordinate.clLocationCoordinate) {
                            WiFiAnnotationView(network: network)
                        }
                    }
                }
                
                UserAnnotation()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                viewModel.updateVisibleRegion(context.region)
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    mapControls
                }
                .padding(AppSpacing.md)
            }
        }
    }

    private var mapControls: some View {
        VStack(spacing: AppSpacing.xs) {
            Button {
                viewModel.startScan()
            } label: {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(viewModel.isScanning ? AppColors.accentPrimary : AppColors.textPrimary)
                    .frame(width: 40, height: 40)
            }
            .disabled(viewModel.isScanning)
            .buttonStyle(.plain)

            Button {
                viewModel.stopScan()
            } label: {
                Image(systemName: "stop.circle")
                    .font(.title2)
                    .foregroundStyle(AppColors.statusDanger)
                    .frame(width: 40, height: 40)
            }
            .disabled(!viewModel.isScanning)
            .buttonStyle(.plain)

            Button {
                viewModel.centerOnUserLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.accentPrimary)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
    }

    // MARK: - Панель устройств

    private var deviceListPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            panelHeader

            if viewModel.listMode == .localSignal {
                statusFilterBar
            }

            panelContent
        }
        .background(AppColors.backgroundSidebar)
        #if os(macOS)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppColors.borderSubtle)
                .frame(width: 1)
        }
        #else
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppColors.borderSubtle)
                .frame(height: 1)
        }
        #endif
    }

    private var panelHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Устройства")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(panelSubtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                if viewModel.isScanning {
                    HStack(spacing: AppSpacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Сканирование")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accentCyan)
                    }
                }
            }

            Picker("Источник", selection: $viewModel.listMode) {
                ForEach(viewModel.availableSources) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
    }

    private var panelSubtitle: String {
        switch viewModel.listMode {
        case .localSignal:
            return "\(viewModel.filteredNetworkDevices.count) из \(viewModel.totalCount) в сети"
        case .wifi:
            return "\(viewModel.wifiNetworks.count) WiFi-сетей найдено"
        case .bluetooth:
            return "\(viewModel.bluetoothCount) найдено по Bluetooth"
        }
    }

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(DeviceFilter.allCases) { filter in
                    MapFilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.statusFilter == filter
                    ) {
                        viewModel.statusFilter = filter
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
        }
    }

    @ViewBuilder
    private var panelContent: some View {
        switch viewModel.listMode {
        case .localSignal:
            if viewModel.filteredNetworkDevices.isEmpty {
                emptyState(
                    icon: "desktopcomputer",
                    title: "Устройства не найдены",
                    message: "Измените фильтр по статусу, чтобы увидеть другие устройства"
                )
            } else {
                networkDeviceList
            }
        case .wifi:
            if viewModel.wifiNetworks.isEmpty {
                emptyState(
                    icon: "wifi",
                    title: "Сети не найдены",
                    message: "Убедитесь, что Wi-Fi включен на устройстве"
                )
            } else {
                wifiNetworkList
            }
        case .bluetooth:
            if viewModel.bluetoothDevices.isEmpty {
                emptyState(
                    icon: "wave.3.left",
                    title: "Bluetooth устройства не найдены",
                    message: "Убедитесь, что Bluetooth включен на устройстве"
                )
            } else {
                bluetoothDeviceList
            }
        }
    }

    // Пример заглушек для недостающих View компонентов в вашем сниппете:
    @ViewBuilder
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack {
            Image(systemName: icon)
            Text(title)
            Text(message)
        }
    }
    
    private var networkDeviceList: some View { Text("Список") }
    private var wifiNetworkList: some View { Text("Wi-Fi") }
    private var bluetoothDeviceList: some View { Text("Bluetooth") }
}

#Preview {
    if #available(iOS 17.0, *) {
        NetworkMapView(viewModel: DIContainer.shared.makeNetworkMapViewModel())
    } else {
            // Fallback on earlier versions
        Text("Предпросмотр возможен лишь с IOS 17 и новее")
    }
}
