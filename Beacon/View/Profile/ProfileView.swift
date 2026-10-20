import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel = DIContainer.shared.makeProfileViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                header

                userCard

                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        sectionTitle("Внешний вид")

                        settingsToggle(
                            title: "Темная тема",
                            icon: viewModel.isDarkModeOn ? "moon.fill" : "sun.max.fill",
                            isOn: $viewModel.isDarkModeOn
                        )
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        sectionTitle("Настройки")

                        settingsToggle(
                            title: "Push-уведомления",
                            icon: viewModel.user.isNotificationOn ? "bell.badge" : "bell.fill",
                            isOn: Binding(
                                get: { viewModel.user.isNotificationOn },
                                set: { _ in viewModel.toggleNotifications() }
                            )
                            )
                    }
                }

                Button(action: viewModel.logout) {
                    Text("Выйти из аккаунта")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.statusDanger)
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.md)
                        .background(AppColors.backgroundCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md)
                                .strokeBorder(AppColors.statusDanger.opacity(0.35), lineWidth: 1)
                        )
                        .cornerRadius(AppRadius.md)
                }
                .buttonStyle(.plain)
            }
            .padding(AppSpacing.screenPadding)
        }
        .background(AppColors.backgroundApp)
        .   preferredColorScheme(viewModel.isDarkModeOn ? .dark : .light)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Профиль")
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text("Учетная запись и параметры приложения")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var userCard: some View {
        AppCard {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .foregroundStyle(AppColors.accentPrimary)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(viewModel.user.name)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(viewModel.user.email)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(viewModel.user.roleDisplayName)
                        .font(AppTypography.caption)
                        .foregroundStyle(viewModel.user.isAdmin ? AppColors.statusDanger : AppColors.accentPrimary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background((viewModel.user.isAdmin ? AppColors.statusDanger : AppColors.accentPrimary).opacity(0.12))
                        .cornerRadius(AppRadius.sm)
                }

                Spacer()
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)
    }

    private func settingsToggle(title: String, icon: String, isOn: Binding<Bool>) -> some View {
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

#Preview {
    NavigationStack {
        ProfileView()
    }
}
