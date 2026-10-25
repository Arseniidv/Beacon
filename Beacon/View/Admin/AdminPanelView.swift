import SwiftUI

struct AdminPanelView: View {
    @StateObject private var viewModel: AdminPanelViewModel

    init(viewModel: AdminPanelViewModel = DIContainer.shared.makeAdminPanelViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerSection

                scanSettingsSection

                usersSection

                systemSettingsSection
            }
            .padding(AppSpacing.screenPadding)
        }
        .background(AppColors.backgroundApp)
        .onAppear {
            viewModel.loadUsers()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Админ-панель")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("Управление доступом, сканированием и системными настройками")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Настройки сканирования

    private var scanSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Сканирование")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            subnetField

            Stepper(
                value: Binding(
                    get: { viewModel.scanSettings.pingTimeoutSeconds },
                    set: { viewModel.setPingTimeout($0) }
                ),
                in: 1...10,
                step: 1
            ) {
                settingLabel(
                    title: "Таймаут отклика",
                    value: "\(Int(viewModel.scanSettings.pingTimeoutSeconds)) с"
                )
            }

            Stepper(
                value: Binding(
                    get: { viewModel.scanSettings.autoRefreshIntervalSeconds },
                    set: { viewModel.setAutoRefreshInterval($0) }
                ),
                in: 0...300,
                step: 30
            ) {
                settingLabel(
                    title: "Автосканирование",
                    value: autoRefreshText
                )
            }

            Divider()
                .background(AppColors.borderSubtle)

            ForEach(ScanSource.allCases) { source in
                sourceRow(source)
            }

            Button {
                viewModel.resetScanSettings()
            } label: {
                Text("Сбросить настройки сканирования")
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.accentPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.backgroundElevated)
                    .cornerRadius(AppRadius.md)
            }
            .buttonStyle(.plain)

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.statusDanger)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }

    private var subnetField: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Подсеть локального сигнала")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            TextField(
                ScanSettings.defaultSubnet,
                text: Binding(
                    get: { viewModel.subnetDraft },
                    set: { viewModel.updateSubnet($0) }
                )
            )
            .font(AppTypography.body)
            .foregroundStyle(AppColors.textPrimary)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled()
            .padding(AppSpacing.sm)
            .background(AppColors.backgroundElevated)
            .cornerRadius(AppRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .strokeBorder(
                        viewModel.isSubnetValid ? AppColors.borderSubtle : AppColors.statusDanger,
                        lineWidth: 1
                    )
            )

            Text("Формат: адрес/префикс, например 192.168.1.0/24")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private func sourceRow(_ source: ScanSource) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: source.icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.accentPrimary)
                .frame(width: 24)

            Text(source.rawValue)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { viewModel.scanSettings.isEnabled(source) },
                set: { viewModel.setSource(source, isEnabled: $0) }
            ))
            .labelsHidden()
            .tint(AppColors.accentPrimary)
        }
    }

    private var autoRefreshText: String {
        let interval = viewModel.scanSettings.autoRefreshIntervalSeconds
        return interval == 0 ? "Выключено" : "\(Int(interval)) с"
    }

    private func settingLabel(title: String, value: String) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Text(value)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Пользователи

    private var usersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Доступ")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text("\(viewModel.adminCount) админ.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.users.isEmpty {
                Text("Нет зарегистрированных пользователей")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.users) { user in
                        UserRow(user: user, onToggleRole: {
                            viewModel.toggleUserRole(user)
                        })
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }

    // MARK: - Системные настройки

    private var systemSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Системные настройки")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            settingRow(title: "Режим обслуживания", icon: "wrench", isOn: Binding(
                get: { viewModel.isMaintenanceMode },
                set: { _ in viewModel.toggleMaintenanceMode() }
            ))
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }

    private func settingRow(title: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(AppColors.accentPrimary)
                .frame(width: 24)

            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.accentPrimary)
        }
    }
}

struct UserRow: View {
    let user: UserAccount
    let onToggleRole: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(AppColors.accentPrimary)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(user.name)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text(user.email)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text(user.roleDisplayName)
                .font(AppTypography.caption)
                .foregroundStyle(user.isAdmin ? AppColors.statusDanger : AppColors.accentPrimary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background((user.isAdmin ? AppColors.statusDanger : AppColors.accentPrimary).opacity(0.12))
                .cornerRadius(AppRadius.sm)

            Button(action: onToggleRole) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(AppSpacing.sm)
        .background(AppColors.backgroundElevated)
        .cornerRadius(AppRadius.md)
    }
}

#Preview {
    NavigationStack {
        AdminPanelView()
    }
}
