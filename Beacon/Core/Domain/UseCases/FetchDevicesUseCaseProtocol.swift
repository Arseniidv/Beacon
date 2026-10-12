import Foundation

protocol FetchDevicesUseCaseProtocol {
    func execute() async throws -> [Device]
}
