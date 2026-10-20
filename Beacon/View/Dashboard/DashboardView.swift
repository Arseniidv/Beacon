import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel = DIContainer.shared.makeDashboardViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection

                summaryCardsSection

                currentSubnetSection

                deviceStatusSection
            }
            .padding(AppSpacing.screenPadding)
        }
        .background(AppColors.backgroundApp)
        .onAppear {
            viewModel.loadDashboard()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Сетевые ресурсы")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("Поиск и мониторинг компьютеров в локальной сети")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
    
    private var summaryCardsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AppSpacing.cardGap),
            GridItem(.flexible(), spacing: AppSpacing.cardGap)
        ], spacing: AppSpacing.cardGap) {
            if let summary = viewModel.summary {
                StatCard(
                    title: "Свободных устройств",
                    value: "\(summary.freeDevices)",
                    subtitle: "из \(summary.totalDevices) в сети",
                    change: "+\(summary.freeDevicesChange)",
                    changeColor: AppColors.statusSuccess,
                    icon: "checkmark.circle"
                )
                
                StatCard(
                    title: "Средняя загрузка CPU",
                    value: "\(Int(summary.averageCpuUsage))%",
                    subtitle: "по всем устройствам",
                    change: "\(Int(summary.cpuUsageChange))%",
                    changeColor: AppColors.statusSuccess,
                    icon: "cpu"
                )
                
                StatCard(
                    title: "Средняя загрузка RAM",
                    value: "\(Int(summary.averageRamUsage))%",
                    subtitle: "по всем устройствам",
                    change: "+\(Int(summary.ramUsageChange))%",
                    changeColor: AppColors.statusDanger,
                    icon: "memorychip"
                )
                
                StatCard(
                    title: "Свободно на дисках",
                    value: summary.freeDiskSpace,
                    subtitle: "из \(summary.totalDiskSpace)",
                    change: nil,
                    changeColor: nil,
                    icon: "internaldrive"
                )
            }
        }
    }
    
    private var currentSubnetSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Текущая подсеть")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.xs) {
                        Text("Bluetooth")
                            .font(AppTypography.bodyStrong)
                            .foregroundStyle(AppColors.textPrimary)
                        
                        Text("\(viewModel.bluetoothDevices.count) устройств по сигналу")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
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
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusDanger)
            }

            if viewModel.isScanningBluetooth {
                PrimaryButton(title: "Остановить сканирование", icon: "stop.circle") {
                    viewModel.stopBluetoothScan()
                }
            } else {
                PrimaryButton(title: "Сканировать", icon: "antenna.radiowaves.left.and.right") {
                    Task {
                        await viewModel.startBluetoothScan()
                    }
                }
            }
            
            if let lastScan = viewModel.summary?.lastScanDate {
                Text("Последнее сканирование: \(formatDate(lastScan))")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
    
    private var deviceStatusSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Статус устройств")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                
                Spacer()
                
                Button("Подробнее") {
                    
                }
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.accentPrimary)
            }
            
            HStack(spacing: AppSpacing.lg) {
                statusLegendItem(title: "Свободны", count: viewModel.summary?.freeDevices ?? 28, color: AppColors.statusSuccess)
                statusLegendItem(title: "Заняты", count: viewModel.summary?.busyDevices ?? 18, color: AppColors.statusDanger)
                statusLegendItem(title: "Недоступны", count: viewModel.summary?.offlineDevices ?? 6, color: AppColors.statusOffline)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
    
    private func statusLegendItem(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            
            Text("\(count)")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "Сегодня, HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
