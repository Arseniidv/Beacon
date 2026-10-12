import SwiftUI

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
                    ProgressBar(progress: ramUsage / 100, color: AppColors.accentPurple)
                    Text("\(Int(ramUsage))%")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                } else {
                    Text("Нет данных")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Загрузка диска")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                
                if let diskUsage = viewModel.device.diskUsage {
                    ProgressBar(progress: diskUsage / 100, color: AppColors.accentTeal)
                    Text("\(Int(diskUsage))%")
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
    
    private var processesTab: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Список процессов")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("Функционал в разработке")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
    
    private var servicesTab: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Системные службы")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("Функционал в разработке")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
}

#Preview {
    NavigationStack {
        DeviceDetailView(device: Device(
            id: UUID(),
            name: "PC-01-ADMIN",
            ip: "192.168.1.10",
            macAddress: "00:18:44:11:3A:B7",
            status: .free,
            ping: 1,
            currentUser: nil,
            cpuUsage: 15.0,
            ramUsage: 32.0,
            diskUsage: 45.0,
            gpu: "NVIDIA RTX 3060",
            uptime: 7200,
            os: "Windows 11 Pro",
            processor: "Intel Core i7-12700K",
            storage: "512 GB SSD",
            networkAdapter: "Intel I219-V"
        ))
    }
}
