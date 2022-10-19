import Foundation
import Profile
import ProfileLoader
import WalletClient

public extension WalletLoader {
    //        public var loadWallet: @Sendable () async throws -> WalletClient
    
    static func live(
        keychainClient: KeychainClient = .live(),
        jsonDecoder: JSONDecoder = .iso8601
    ) -> Self {
        Self.live(profileLoader: .live(keychainClient: keychainClient, jsonDecoder: jsonDecoder))
    }
    static func live(
        profileLoader: ProfileLoader
    ) -> Self {
        Self.init(
            loadWallet: {
                let profile = try await profileLoader.loadProfile()
                let wallet = WalletClient.
            }
        )
    }
}
