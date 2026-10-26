import Foundation
import Combine

@MainActor
final class NetworkProfileViewModel: ObservableObject {
    @Published var profiles: [NetworkProfile] = []
    @Published var activeProfile: NetworkProfile?
    @Published var errorMessage: String?
    @Published var isEditing: Bool = false
    @Published var editingProfile: NetworkProfile?

    private let repository: NetworkProfileRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(repository: NetworkProfileRepositoryProtocol) {
        self.repository = repository

        repository.profiles
            .receive(on: RunLoop.main)
            .assign(to: &$profiles)

        repository.activeProfile
            .receive(on: RunLoop.main)
            .assign(to: &$activeProfile)
    }

    // MARK: - Profile Management

    func createProfile(
        name: String,
        purpose: String,
        networkType: NetworkType,
        subnet: String,
        gateway: String? = nil
    ) {
        do {
            let ipv4Config = IPv4Configuration(
                subnet: subnet,
                gateway: gateway
            )

            let profile = NetworkProfile(
                name: name,
                purpose: purpose,
                networkType: networkType,
                ipv4Config: ipv4Config
            )

            try repository.createProfile(profile)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateProfile(_ profile: NetworkProfile) {
        do {
            try repository.updateProfile(profile)
            errorMessage = nil
            isEditing = false
            editingProfile = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProfile(_ profile: NetworkProfile) {
        do {
            try repository.deleteProfile(id: profile.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setActiveProfile(_ profile: NetworkProfile) {
        do {
            try repository.setActiveProfile(id: profile.id)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Editing

    func startEditing(_ profile: NetworkProfile) {
        editingProfile = profile
        isEditing = true
        errorMessage = nil
    }

    func cancelEditing() {
        editingProfile = nil
        isEditing = false
        errorMessage = nil
    }

    func createNewProfile() {
        editingProfile = NetworkProfile(
            name: "",
            purpose: "",
            networkType: .home
        )
        isEditing = true
        errorMessage = nil
    }

    // MARK: - Validation Helpers

    func validateSubnet(_ subnet: String) -> Bool {
        ScanSettings.isValidSubnet(subnet)
    }

    func validateIPAddress(_ ip: String) -> Bool {
        (try? IPAddress(ip)) != nil
    }
}
