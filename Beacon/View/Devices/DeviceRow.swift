
import SwiftUI

struct DeviceRow: View {
    let device: Device
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                headerSection

                metricsSection

                footerSection
            }
            .padding(AppSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.backgroundCard)
            .cornerRadius(AppRadius.lg)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(device.name)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: AppSpacing.xs) {
                    Text(device.ip)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)

                    if let ping = device.ping {
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)

                        Text("\(ping) мс")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }

            Spacer(minLength: AppSpacing.xs)

            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                StatusBadge(status: device.status)

                if let currentUser = device.currentUser,
                   device.status == .busy {
                    Text(currentUser)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    // MARK: - Metrics

    @ViewBuilder
    private var metricsSection: some View {
        let hasMetrics =
            device.cpuUsage != nil ||
            device.ramUsage != nil ||
            device.diskUsage != nil

        if hasMetrics {
            VStack(spacing: AppSpacing.sm) {
                if let cpu = device.cpuUsage {
                    metricRow(
                        title: "CPU",
                        value: cpu,
                        color: AppColors.accentPrimary
                    )
                }

                if let ram = device.ramUsage {
                    metricRow(
                        title: "RAM",
                        value: ram,
                        color: AppColors.accentPurple
                    )
                }

                if let disk = device.diskUsage {
                    metricRow(
                        title: "Disk",
                        value: disk,
                        color: AppColors.accentOrange
                    )
                }
            }
        }
    }

    private func metricRow(
        title: String,
        value: Double,
        color: Color
    ) -> some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text(title)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer()

                Text("\(Int(value))%")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
            }

            ProgressView(value: min(max(value, 0), 100), total: 100)
                .tint(color)
                .scaleEffect(x: 1, y: 0.8, anchor: .center)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: AppSpacing.sm) {
            Label(
                device.status == .offline ? "Нет связи" : "Сетевое устройство",
                systemImage: device.status == .offline
                    ? "wifi.slash"
                    : "network"
            )
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textTertiary)

            Spacer()

            if let uptime = device.uptime, uptime > 0 {
                Text(formattedUptime(TimeInterval(uptime)))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func formattedUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "В сети \(hours) ч \(minutes) мин"
        }

        return "В сети \(minutes) мин"
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        DeviceRow(
            device: Device(
                id: UUID(),
                name: "PC-01-ADMIN",
                ip: "192.168.1.10",
                macAddress: "00:18:44:11:3A:B7",
                status: .free,
                ping: 1,
                currentUser: nil,
                cpuUsage: 15.0,
                ramUsage: 32.0,
                diskUsage: 45.0,
                gpu: "NVIDIA RTX 3060",
                uptime: 7200,
                os: "Windows 11 Pro",
                processor: "Intel Core i7-12700K",
                storage: "512 GB SSD",
                networkAdapter: "Intel I219-V"
            )
        )

        DeviceRow(
            device: Device(
                id: UUID(),
                name: "PC-02-DESIGN",
                ip: "192.168.1.11",
                macAddress: "00:18:44:22:4C:C8",
                status: .busy,
                ping: 2,
                currentUser: "ivan.petrov",
                cpuUsage: 67.0,
                ramUsage: 78.0,
                diskUsage: 62.0,
                gpu: "NVIDIA RTX 4070",
                uptime: 14400,
                os: "Windows 11 Pro",
                processor: "AMD Ryzen 9 5900X",
                storage: "1 TB NVMe",
                networkAdapter: "Realtek 8125"
            )
        )
    }
    .padding()
    .background(AppColors.backgroundApp)
}
