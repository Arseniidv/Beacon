
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    let name:String

    var body: some View {
        List {
            // MARK: - Информация о пользователе

            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(AppColors.textSecondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.user.name)
                            .font(.headline)
                            .foregroundColor(AppColors.textPrimary)

                        Text(viewModel.user.email)
                            .font(.subheadline)
                            .foregroundColor(AppColors.textSecondary)

                        Text(viewModel.user.role)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColors.backgroundElevated)
                            .foregroundColor(AppColors.accentPrimary)
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - Внешний вид

            Section {
                Toggle(isOn: $viewModel.isDarkModeOn) {
                    Label {
                        Text("Темная тема")
                            .foregroundColor(AppColors.textPrimary)
                    } icon: {
                        Image(
                            systemName: viewModel.isDarkModeOn
                                ? "moon.fill"
                                : "sun.max.fill"
                        )
                        .foregroundColor(AppColors.accentPrimary)
                    }
                }
            } header: {
                Text("Внешний вид")
                    .foregroundColor(AppColors.textTertiary)
            }

            // MARK: - Настройки

            Section {
                Toggle(
                    "Включить push-уведомления",
                    isOn: Binding(
                        get: {
                            viewModel.user.isNotificationOn
                        },
                        set: { _ in
                            viewModel.toggleNotifications()
                        }
                    )
                )
                .toggleStyle(
                    SwitchToggleStyle(tint: AppColors.statusSuccess)
                )

                .toggleStyle(
                    SwitchToggleStyle(
                        tint: AppColors.statusSuccess
                    )
                )
            } header: {
                Text("Настройки")
                    .foregroundColor(AppColors.textTertiary)
            }


            Section {
                Button(
                    role: .destructive,
                    action: viewModel.logout
                ) {
                    HStack {
                        Spacer()
                        Text("Выйти из аккаунта")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Профиль")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView(name: String())
    }
}
