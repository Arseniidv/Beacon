import SwiftUI

struct DeviceAnnotationView:View {
    let device:BluetoothDevice
    var body: some View {
        ZStack{
            Circle()
                .fill(Color.blue)
                .frame(width: 28,height: 28)
                .shadow(radius: 2)
            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 12))
                .foregroundStyle(.white)
        }
    }
}

