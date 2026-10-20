import SwiftUI

struct ProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    // Используем напрямую без круглых скобок!
                    .fill(AppColors.borderSubtle)

                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(max(0, min(progress, 1))))
            }
        }
        .frame(height: 6)
    }
}

// Абсолютно чистое превью без вложенных структур!
#Preview {
    VStack(spacing: AppSpacing.md) {
        ProgressBar(progress: 0.32, color: AppColors.accentPrimary)
        ProgressBar(progress: 0.67, color: AppColors.statusDanger)
        ProgressBar(progress: 0.46, color: AppColors.accentPurple)
    }
    .padding()
    .background(AppColors.backgroundApp)
}
