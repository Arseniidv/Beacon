import SwiftUI

struct DeviceRow: View {
    let device: Device
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(device.name)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xs) {
                    Text(device.ip)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    
                    if let ping = device.ping {
                        Text("•")
                            .foregroundStyle(AppColors.textTertiary)
                        Text("\(ping) мс")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                StatusBadge(status: device.status)
                
                if let currentUser = device.currentUser, device.status == .busy {
                    Text(currentUser)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            Image(systemName: "ellipsis")
                .foregroundStyle(AppColors.textTertiary)
                .padding(.leading, AppSpacing.sm)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.backgroundCard)
        .cornerRadius(AppRadius.lg)
        .contentShape(Rectangle())
        .onTapGesture {
            
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.sm) {
        DeviceRow(device: Device(
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
        ))
        
        DeviceRow(device: Device(
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
        ))
    }
    .padding()
    .background(AppColors.backgroundApp)
}
