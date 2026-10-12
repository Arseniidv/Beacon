import SwiftUI

struct StatusBadge: View {
    let status: DeviceStatus
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(status.rawValue)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(statusColor.opacity(0.1))
        .cornerRadius(AppRadius.sm)
    }
    
    private var statusColor: Color {
        switch status {
        case .free:
            return AppColors.statusSuccess
        case .busy:
            return AppColors.statusDanger
        case .offline:
            return AppColors.statusOffline
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        StatusBadge(status: .free)
        StatusBadge(status: .busy)
        StatusBadge(status: .offline)
    }
    .padding()
    .background(AppColors.backgroundApp)
}
