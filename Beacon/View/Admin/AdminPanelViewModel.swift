import Foundation
import Combine

@MainActor
final class AdminPanelViewModel: ObservableObject {
    @Published var users: [UserAccount] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isMaintenanceMode = false
    @Published var isAutoScanEnabled = true

    private let authRepository: AuthRepositoryProtocol

    init(authRepository: AuthRepositoryProtocol = AuthRepository()) {
        self.authRepository = authRepository
    }

    func loadUsers() {
        isLoading = true
        // Simulate loading users
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.users = self.getAllUsers()
            self.isLoading = false
        }
    }

    func toggleUserRole(_ user: UserAccount) {
        guard let index = users.firstIndex(where: { $0.id == user.id }) else { return }

        let newRole = user.userRole == .admin ? "user" : "admin"
        users[index] = UserAccount(
            id: user.id,
            name: user.name,
            email: user.email,
            role: newRole
        )

        // Update in storage
        updateUserRole(userId: user.id, newRole: newRole)
    }

    func toggleMaintenanceMode() {
        isMaintenanceMode.toggle()
    }

    func toggleAutoScan() {
        isAutoScanEnabled.toggle()
    }

    private func getAllUsers() -> [UserAccount] {
        // This would normally fetch from repository
        // For now, return mock data including current user
        var allUsers: [UserAccount] = []

        if let currentUser = authRepository.loadSession() {
            allUsers.append(currentUser)
        }

        // Add mock users for demonstration
        allUsers.append(contentsOf: [
            UserAccount(name: "Иван Петров", email: "ivan@example.com", role: "user"),
            UserAccount(name: "Мария Иванова", email: "maria@example.com", role: "user")
        ])

        return allUsers
    }

    private func updateUserRole(userId: UUID, newRole: String) {
        // Implement actual role update in repository
        // This would involve updating the stored accounts
    }
}
