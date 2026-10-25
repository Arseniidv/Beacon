import SwiftUI

struct WiFiAnnotationView:View {
    let network:WiFiNetwork
    
    var body: some View {
        VStack(spacing:2){
            ZStack{
                Circle()
                    .fill(AppColors.accentCyan)
                    .frame(width: 28,height: 28)
                    .shadow(radius: 2)
                Image(systemName: "wifi")
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
            }
        }
    }
}
