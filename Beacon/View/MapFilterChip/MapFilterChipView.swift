import SwiftUI

struct MapFilterChip:View {
    let title:String
    let isSelected:Bool
    let action:()->Void
    
    var body: some View {
        Button(action: action){
            Text(title)
                .font(AppTypography.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(isSelected ? AppColors.accentPrimary : AppColors.backgroundCard)
                .foregroundStyle(isSelected ? Color.white : AppColors.textPrimary)
                .cornerRadius(AppRadius.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .strokeBorder(isSelected ? Color.clear : AppColors.borderSubtle, lineWidth: 1)
                )
        }.buttonStyle(.plain)
    }
}

