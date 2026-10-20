import SwiftUI

struct GoogleAuthButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.textPrimary)

                Text(title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()
            }
            .padding(AppSpacing.md)
            .background(AppColors.backgroundCard)
            .cornerRadius(AppRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct GoogleAuthCircleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.backgroundCard)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                    )

                Image(systemName: "g.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AppleAuthCircleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.backgroundCard)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
                    )

                Image(systemName: "applelogo")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: AppSpacing.lg) {
        GoogleAuthButton(title: "Войти через Google") {}

        HStack(spacing: AppSpacing.md) {
            GoogleAuthCircleButton {}
            AppleAuthCircleButton {}
        }
    }
    .padding()
    .background(AppColors.backgroundApp)
}
