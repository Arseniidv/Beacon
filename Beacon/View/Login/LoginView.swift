import SwiftUI


struct LoginView:View {
    @State private var viewModel = LoginViewModel(
        id:UUID(),
        name: "",
        email: "",
        password: "",
        currentPassword: ""
    )
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
#Preview {
    LoginView()
}
