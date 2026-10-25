import SwiftUI

struct NetworkClusterAnnotationView: View {
    let cluster: DeviceCluster
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(statusColor(cluster.dominantStatus))
                    .frame(width: cluster.isCluster ? 40 : 28, height: cluster.isCluster ? 40 : 28)
                    .shadow(radius: 3)
                
                if cluster.isCluster {
                    Text("\(cluster.devices.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func statusColor(_ status: DeviceStatus) -> Color {
        switch status {
        case .free: return AppColors.accentPrimary // Например, зеленый/синий
        case .busy: return .orange
        case .offline: return AppColors.statusDanger
        }
    }
}
