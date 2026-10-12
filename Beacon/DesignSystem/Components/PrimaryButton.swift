import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PrimaryButton(title: "Сканировать сеть", icon: "magnifyingglass") {
        print("Button tapped")
    }
    .padding()
}
