import SwiftUI

struct DeviceCard: View {
    let device: Device

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            statusIndicator

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(device.name)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)

                Text(device.ip)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "network")
                        .font(.system(size: 12))
                    Text(device.formattedPing)
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                }

                if let currentUser = device.currentUser {
                    Text(currentUser)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(device.status.color)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(AppColors.backgroundCard, lineWidth: 2)
            )
    }
}

#Preview {
    VStack(spacing: AppSpacing.cardGap) {
        DeviceCard(device: Device(
            id: UUID(),
            name: "MacBook Pro",
            ip: "192.168.1.10",
            macAddress: "00:1A:2B:3C:4D:5E",
            status: .free,
            ping: 12,
            currentUser: "user1",
            cpuUsage: 25.5,
            ramUsage: 45.2,
            diskUsage: 60.0,
            gpu: "M2 Pro",
            uptime: 86400,
            os: "macOS 14.0",
            processor: "Apple M2 Pro",
            storage: "512 GB SSD",
            networkAdapter: "Wi-Fi 6"
        ))

        DeviceCard(device: Device(
            id: UUID(),
            name: "Windows PC",
            ip: "192.168.1.11",
            macAddress: "00:1A:2B:3C:4D:5F",
            status: .busy,
            ping: 15,
            currentUser: "user2",
            cpuUsage: 78.3,
            ramUsage: 85.1,
            diskUsage: 75.5,
            gpu: "RTX 4070",
            uptime: 172800,
            os: "Windows 11",
            processor: "Intel i7-13700K",
            storage: "1 TB NVMe",
            networkAdapter: "Ethernet"
        ))
    }
    .padding()
    .background(AppColors.backgroundApp)
}
