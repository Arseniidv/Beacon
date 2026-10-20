import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct NetworkMapView: View {
    @StateObject private var viewModel: NetworkMapViewModel

    @available(iOS 17.0, *)
    init(viewModel: NetworkMapViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            mapCanvas
            deviceListPanel
                .frame(width: AppLayout.detailPanelWidth)
        }
        .background(AppColors.backgroundApp)
        .onAppear {
            viewModel.requestLocationAuthorization()
        }
        #else
        VStack(spacing: 0) {
            mapCanvas
                .frame(minHeight: 280)
            deviceListPanel
        }
        .background(AppColors.backgroundApp)
        .onAppear {
            viewModel.requestLocationAuthorization()
        }
        #endif
    }

    private var mapCanvas: some View {
        ZStack {
            Map(position: $viewModel.cameraPosition) {
                ForEach(viewModel.bluetoothDevices) { device in
                    Annotation(device.name, coordinate: device.coordinate.clLocationCoordinate) {
                        DeviceAnnotationView(device: device)
                    }
                }
                UserAnnotation()
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
                Task {
                    await viewModel.startBluetoothScan()
                }
            } label: {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(viewModel.isScanningBluetooth ? AppColors.accentPrimary : AppColors.textPrimary)
                    .frame(width: 40, height: 40)
            }
            .disabled(viewModel.isScanningBluetooth)
            .buttonStyle(.plain)

            Button {
                viewModel.stopBluetoothScan()
            } label: {
                Image(systemName: "stop.circle")
                    .font(.title2)
                    .foregroundStyle(AppColors.statusDanger)
                    .frame(width: 40, height: 40)
            }
            .disabled(!viewModel.isScanningBluetooth)
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

    private var deviceListPanel: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Устройства")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("\(viewModel.bluetoothCount) найдено по Bluetooth")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                if viewModel.isScanningBluetooth {
                    HStack(spacing: AppSpacing.xs) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Сканирование")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.accentCyan)
                    }
                }

            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.md)

            if viewModel.bluetoothDevices.isEmpty {
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.textTertiary)

                    Text("Устройства не найдены")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Запустите сканирование, чтобы увидеть Bluetooth-устройства рядом")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppSpacing.lg)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(viewModel.bluetoothDevices) { device in
                            Button {
                                viewModel.focus(on: device)
                            } label: {
                                BluetoothDeviceRow(device: device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.md)
                }
            }
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
}

struct DeviceAnnotationView: View {
    let device: BluetoothDevice

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            ZStack {
                Circle()
                    .fill(device.signalStrength.color)
                    .frame(width: 40, height: 40)

                Image(systemName: device.signalStrength.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(AppColors.textOnAccent)
            }
            .shadow(radius: 3)

            Text(device.name)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.xs)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColors.backgroundCard)
                .cornerRadius(AppRadius.sm)
        }
    }
}

struct BluetoothDeviceRow: View {
    let device: BluetoothDevice

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(device.signalStrength.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(device.name)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                Text(device.identifier)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(device.formattedRSSI)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text(device.formattedDistance)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    if #available(iOS 17.0, *) {
        NetworkMapView(viewModel: DIContainer.shared.makeNetworkMapViewModel())
    } else {
            // Fallback on earlier versions
        Text("Предпросмотр возможен лишь с IOS 17 и новее")
    }
}
