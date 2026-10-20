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

            Text("Управление пользователями и системными настройками")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var usersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Пользователи")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.accentPrimary)
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
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

    private var systemSettingsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Системные настройки")
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColors.textPrimary)

            settingRow(title: "Режим обслуживания", icon: "wrench", isOn: Binding(
                get: { viewModel.isMaintenanceMode },
                set: { _ in viewModel.toggleMaintenanceMode() }
            ))

            settingRow(title: "Автоматическое сканирование", icon: "antenna.radiowaves.left.and.right", isOn: Binding(
                get: { viewModel.isAutoScanEnabled },
                set: { _ in viewModel.toggleAutoScan() }
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
