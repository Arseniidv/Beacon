import SwiftUI

struct ProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppColors.backgroundElevated)
                
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(color)
                    .frame(width: geometry.size.width * CGFloat(progress))
            }
        }
        .frame(height: 6)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        ProgressBar(progress: 0.32, color: AppColors.accentPrimary)
        ProgressBar(progress: 0.67, color: AppColors.statusDanger)
        ProgressBar(progress: 0.46, color: AppColors.accentPurple)
    }
    .padding()
    .background(AppColors.backgroundApp)
}
