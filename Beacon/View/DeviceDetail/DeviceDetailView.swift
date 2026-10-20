import SwiftUI
import Combine

// TODO: Implement DeviceDetailViewModel
@MainActor
final class DeviceDetailViewModel: ObservableObject {
    @Published var device: Device
    @Published var allDevices: [Device] = []
    @Published var selectedTab: DetailTab = .characteristics

    init(device: Device) {
        self.device = device
        self.allDevices = [device]
    }

    func selectDevice(_ device: Device) {
        self.device = device
    }

    func connectToDevice() {}
    func reserveDevice() {}
    func wakeOnLAN() {}
}

enum DetailTab: String, CaseIterable {
    case characteristics = "Характеристики"
    case graphs = "Графики"
    case processes = "Процессы"
    case services = "Сервисы"
}

struct DeviceDetailView: View {
    @StateObject private var viewModel: DeviceDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(device: Device) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(device: device))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection
                devicesCarouselSection
                actionButtons
                detailContent
            }
            .padding(AppSpacing.screenPadding)
        }
        .background(AppColors.backgroundApp)
        #if os(iOS)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .foregroundStyle(AppColors.textPrimary)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(AppColors.textPrimary)
                }
            }
        }
        #else
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                }
            }

            ToolbarItem(placement: .automatic) {
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                }
            }
        }
        #endif
    }

    // MARK: - Carousel Section
    private var devicesCarouselSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Устройства в сети")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppSpacing.md) {
                    ForEach(viewModel.allDevices) { device in
                        Button(action: {
                            viewModel.selectDevice(device)
                        }) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "desktopcomputer")
                                    .font(.system(size: 20))
                                    .foregroundStyle(device.id == viewModel.device.id ? AppColors.backgroundApp : AppColors.accentPrimary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(device.name)
                                        .font(AppTypography.bodyStrong)
                                        .foregroundStyle(device.id == viewModel.device.id ? AppColors.backgroundApp : AppColors.textPrimary)

                                    Text(device.ip)
                                        .font(.system(size: 12))
                                        .foregroundStyle(device.id == viewModel.device.id ? AppColors.backgroundApp.opacity(0.7) : AppColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(
                                device.id == viewModel.device.id ? AppColors.accentPrimary : AppColors.backgroundCard
                            )
                            .cornerRadius(AppRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(AppColors.borderSubtle, lineWidth: device.id == viewModel.device.id ? 0 : 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenPadding)
            }
        }
        .padding(.horizontal, -AppSpacing.screenPadding)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.accentPrimary)
                .frame(width: 64, height: 64)
                .background(AppColors.backgroundElevated)
                .cornerRadius(AppRadius.md)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(viewModel.device.name)
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(viewModel.device.ip)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)

                HStack(spacing: AppSpacing.sm) {
                    StatusBadge(status: viewModel.device.status)

                    if let ping = viewModel.device.ping {
                        Text("\(ping) мс")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            PrimaryButton(title: "Подключиться", icon: "cable.connected") {
                viewModel.connectToDevice()
            }

            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(title: "Забронировать", icon: "bookmark") {
                    viewModel.reserveDevice()
                }

                SecondaryButton(title: "Wake-on-LAN", icon: "power") {
                    viewModel.wakeOnLAN()
                }
            }
        }
    }

    // MARK: - Detail Content & Tabs
    @ViewBuilder
    private var detailContent: some View {
        VStack(spacing: AppSpacing.md) {
            tabSelector

            switch viewModel.selectedTab {
            case .characteristics:
                characteristicsTab
            case .graphs:
                graphsTab
            case .processes:
                processesTab
            case .services:
                servicesTab
            }
        }
    }

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    viewModel.selectedTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(viewModel.selectedTab == tab ? AppColors.accentPrimary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(viewModel.selectedTab == tab ? AppColors.backgroundElevated : Color.clear)
                }
            }
        }
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.md)
    }

    private var characteristicsTab: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Основные характеристики")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            characteristicRow(title: "Пользователь", value: viewModel.device.currentUser ?? "Не используется")
            characteristicRow(title: "IP-адрес", value: viewModel.device.ip)
            characteristicRow(title: "MAC-адрес", value: viewModel.device.macAddress)
            characteristicRow(title: "Статус", value: viewModel.device.status.rawValue)

            characteristicRow(title: "Время работы", value: viewModel.device.formattedUptime)

            Divider()
                .background(AppColors.borderSubtle)

            Text("Аппаратное обеспечение")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            characteristicRow(title: "Процессор", value: viewModel.device.processor ?? "-")
            characteristicRow(title: "Оперативная память", value: viewModel.device.storage ?? "-")
            characteristicRow(title: "Видеокарта", value: viewModel.device.gpu ?? "-")
            characteristicRow(title: "Накопитель", value: viewModel.device.storage ?? "-")

            Divider()
                .background(AppColors.borderSubtle)

            Text("Система")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            characteristicRow(title: "Операционная система", value: viewModel.device.os ?? "-")
            characteristicRow(title: "Сетевой адаптер", value: viewModel.device.networkAdapter ?? "-")
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }

    private func characteristicRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Spacer()
            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
        }
    }

    private var graphsTab: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Загрузка CPU")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                if let cpuUsage = viewModel.device.cpuUsage {
                    ProgressBar(progress: cpuUsage / 100, color: AppColors.accentPrimary)
                    Text("\(Int(cpuUsage))%")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                } else {
                    Text("Нет данных")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Загрузка RAM")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                if let ramUsage = viewModel.device.ramUsage {
                    ProgressBar(progress: ramUsage / 100, color: AppColors.accentPrimary)
                    Text("\(Int(ramUsage))%")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                } else {
                    Text("Нет данных")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
// Пустые заглушки для остальных вкладок, чтобы не было ошибок компиляции
private var processesTab: some View { Text("Процессы").foregroundStyle(AppColors.textPrimary) }
private var servicesTab: some View { Text("Сервисы").foregroundStyle(AppColors.textPrimary) }
}
