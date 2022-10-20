import Foundation
import Profile
import ProfileLoader
import WalletClient
import KeychainClient

public extension WalletClientLoader {
    
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
            loadWalletClient: {
                var wallet = WalletClient.live
                if let profileSnapshot = try await profileLoader.loadProfileSnapshot() {
                    try wallet.injectProfileSnapshot(profileSnapshot)
                }
                return wallet
            }
        )
    }
}
