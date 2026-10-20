import SwiftUI

struct AuthView: View {
    @StateObject private var viewModel: AuthViewModel

    init(viewModel: AuthViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppColors.backgroundApp
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    header
                    formCard
                }
                .frame(maxWidth: 440)
                .padding(AppSpacing.xl)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(AppColors.accentPrimary)
                .frame(width: 72, height: 72)
                .background(AppColors.accentPrimary.opacity(0.12))
                .cornerRadius(AppRadius.lg)

            VStack(spacing: AppSpacing.xs) {
                Text("Beacon")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(viewModel.mode == .login
                     ? "Войдите, чтобы сканировать устройства вокруг"
                     : "Создайте аккаунт, чтобы начать работу")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, AppSpacing.xl)
    }

    private var formCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                modePicker

                if viewModel.mode == .register {
                    AppTextField(
                        title: "Имя",
                        placeholder: "Как к вам обращаться",
                        text: $viewModel.name
                    )
                }

                AppTextField(
                    title: "Email",
                    placeholder: "name@company.com",
                    text: $viewModel.email
                )
                #if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                #endif
                .autocorrectionDisabled()

                AppTextField(
                    title: "Пароль",
                    placeholder: "Не менее 6 символов",
                    text: $viewModel.password,
                    isSecure: true
                )

                if viewModel.mode == .register {
                    AppTextField(
                        title: "Повторите пароль",
                        placeholder: "Ещё раз тот же пароль",
                        text: $viewModel.confirmPassword,
                        isSecure: true
                    )
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.statusDanger)
                }

                PrimaryButton(
                    title: viewModel.isLoading ? "Подождите…" : viewModel.primaryActionTitle,
                    icon: viewModel.mode == .login ? "arrow.right.circle" : "person.badge.plus",
                    isEnabled: !viewModel.isLoading,
                    action: viewModel.submit
                )

                // MARK: - Circle Auth Buttons
                HStack(spacing: AppSpacing.xl) {
                    GoogleAuthCircleButton {
                        viewModel.authenticateWithGoogle()
                    }

                    AppleAuthCircleButton {
                        viewModel.authenticateWithApple()
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    viewModel.switchMode(to: viewModel.mode == .login ? .register : .login)
                } label: {
                    Text(viewModel.mode == .login
                         ? "Нет аккаунта? Зарегистрироваться"
                         : "Уже есть аккаунт? Войти")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.accentPrimary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(AuthScreenMode.allCases, id: \.self) { mode in
                Button {
                    viewModel.switchMode(to: mode)
                } label: {
                    Text(mode.rawValue)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(viewModel.mode == mode ? AppColors.textPrimary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(viewModel.mode == mode ? AppColors.backgroundElevated : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(AppColors.backgroundApp)
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
        )
    }
}

#Preview {
    AuthView(viewModel: DIContainer.shared.makeAuthViewModel())
}
