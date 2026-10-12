import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let change: String?
    let changeColor: Color?
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(AppColors.textSecondary)
                    .font(.system(size: 16))

                Spacer()

                if let change = change, let changeColor = changeColor {
                    Text(change)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(changeColor)
                }
            }

            Text(value)
                .font(AppTypography.metricMedium)
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }
}

#Preview {
    StatCard(
        title: "Свободных устройств",
        value: "28",
        subtitle: "из 52 в сети",
        change: "+5",
        changeColor: AppColors.statusSuccess,
        icon: "checkmark.circle"
    )
}
