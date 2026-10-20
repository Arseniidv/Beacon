import SwiftUI

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(AppTypography.bodyStrong)
            }
            .foregroundStyle(AppColors.textPrimary) // Чистый вызов без скобок
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            // Исправленный правильный порядок скругления фона:
            .background(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .fill(AppColors.backgroundElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        SecondaryButton(title: "Wake-on-LAN", icon: "power") {}
        SecondaryButton(title: "Изменить", icon: nil) {}
    }
    .padding()
    .background(AppColors.backgroundApp)
}
