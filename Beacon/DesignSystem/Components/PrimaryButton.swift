import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }

                Text(title)
                    .font(AppTypography.bodyStrong)
            }
            .foregroundStyle(AppColors.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(AppColors.accentPrimary)
            .cornerRadius(AppRadius.md)
            .opacity(isEnabled ? 1 : 0.55)
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PrimaryButton(title: "Сканировать сеть", icon: "magnifyingglass") {
        print("Button tapped")
    }
    .padding()
}
