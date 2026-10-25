import SwiftUI

struct NetworkDeviceDetailView: View {
    let device: Device
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack {
                    Image(systemName: "desktopcomputer")
                        .font(.largeTitle)
                        .foregroundStyle(device.status == .offline ? .gray : AppColors.accentPrimary)
                    
                    VStack(alignment: .leading) {
                        Text(device.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("IP: \(device.ip)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top)
                
                Divider()
                //Доделать опциональный mac - адресс
                Spacer()
                
                Button(action: {
                    onSelect()
                    dismiss()
                }) {
                    Text("Показать на карте")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.accentPrimary)
                        .foregroundStyle(.white)
                        .cornerRadius(AppRadius.md)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .navigationTitle("Информация об устройстве")
#if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
}
