import SwiftUI


struct AppCard<Content: View>: View {
    private let tint: Color?
    private let content: Content

    init(
        tint: Color? = nil, @ViewBuilder content: () -> Content
    ) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .fill(AppColors.backgroundCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill((tint ?? .clear).opacity(0.10))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
    }
}


