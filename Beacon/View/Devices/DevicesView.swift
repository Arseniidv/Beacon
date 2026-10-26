import SwiftUI

struct DevicesView: View {
    @StateObject private var viewModel: DeviceViewModel

    init(viewModel: DeviceViewModel = DIContainer.shared.makeDeviceViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    filtersSection

                    if viewModel.filteredDevices.isEmpty {
                        emptyState
                    } else {
                        devicesList
                    }
                }
                .padding(AppSpacing.screenPadding)
            }
        }
        .background(AppColors.backgroundApp)
        .onAppear {
            viewModel.loadDevices()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Устройства")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("\(viewModel.totalDevices) устройств в сети")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.screenPadding)
        .background(AppColors.backgroundSidebar)
    }

    private var filtersSection: some View {
        HStack(spacing: AppSpacing.sm) {
            Picker("Фильтр", selection: $viewModel.selectedFilter) {
                ForEach(DeviceFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            Picker("Сортировка", selection: $viewModel.selectedSort) {
                ForEach(DeviceSortOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)

            Spacer()

            if !viewModel.searchText.isEmpty {
                Button("Сброс") {
                    viewModel.resetFilters()
                }
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.accentPrimary)
            }
        }
    }

    private var devicesList: some View {
        LazyVStack(spacing: AppSpacing.cardGap) {
            ForEach(viewModel.filteredDevices) { device in
                DeviceCard(device: device)
            }
        }
    }
    
    private var scanningSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Button {
                viewModel.scanNetwork()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(AppColors.textPrimary)
                    } else {
                        Image(systemName: "network")
                    }

                    Text(
                        viewModel.isLoading
                            ? "Сканирование сети..."
                            : "Сканировать сеть"
                    )
                    .font(AppTypography.bodyStrong)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .foregroundStyle(AppColors.textPrimary)
                .background(AppColors.accentPrimary)
                .clipShape(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                )
            }
            .disabled(viewModel.isLoading)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textTertiary)

            Text("Устройства не найдены")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("Попробуйте изменить фильтры или поиск")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

#Preview {
    DevicesView()
}
