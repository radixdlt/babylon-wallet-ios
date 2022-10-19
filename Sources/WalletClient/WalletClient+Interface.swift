import Foundation
import Profile
import Mnemonic

public extension JSONEncoder {
    static var iso8601: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}


// MARK: - WalletClient
public struct WalletClient {
    public var injectProfileSnapshot: InjectProfileSnapshot
    public var extractProfileSnapshot: ExtractProfileSnapshot
    public var getAccounts: GetAccounts
    
}

public extension WalletClient {
    // ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
    typealias InjectProfileSnapshot = @Sendable (ProfileSnapshot) async throws -> Void
    typealias ExtractProfileSnapshot = @Sendable () async throws -> ProfileSnapshot
    typealias GetAccounts = @Sendable (NetworkID) async throws -> [OnNetwork.Account]
    // ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
}



public extension WalletClient {
    static let live: Self = {
        let actor = WalletClientActor()
        return Self.init(
            injectProfileSnapshot: {
                try await actor.injectProfileSnapshot($0)
            },
            extractProfileSnapshot: {
                try await actor.takeProfileSnapshot()
            },
            getAccounts: { networkID in
                try await actor.withProfile { profile in
                    try profile.perNetwork.onNetwork(id: networkID).accounts.rawValue.elements
                }
            })
    }()
}

final actor WalletClientActor {
    private var profile: Profile?
    
    struct NoProfile: Swift.Error {}
    
    
    @discardableResult
    func withProfile<T>(_ withProfile: (Profile) throws -> T) throws -> T {
        guard let profile else {
            throw NoProfile()
        }
        return try withProfile(profile)
    }
    
    func injectProfileSnapshot(_ profileSnapshot: ProfileSnapshot) throws {
        self.profile = try .init(snapshot: profileSnapshot)
    }
    
    func takeProfileSnapshot() throws -> ProfileSnapshot {
        try withProfile { profile in
            profile.snaphot()
        }
    }
}

public extension WalletClient {
    static func mock() -> Self {
        Self(
            injectProfileSnapshot: { _ in /* No op */ },
            extractProfileSnapshot: { fatalError("Impl me") },
            getAccounts: { _ in
                [
                    try! OnNetwork.Account(
                        address: OnNetwork.Account.EntityAddress(
                            address: "account_tdx_a_1qwv0unmwmxschqj8sntg6n9eejkrr6yr6fa4ekxazdzqhm6wy5"
                        ),
                        securityState: .unsecured(.init(
                            genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
                                factorSourceReference: .init(
                                    factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
                                    factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
                                ),
                                publicKey: .curve25519(.init(
                                    compressedRepresentation: Data(
                                        hexString: "7bf9f97c0cac8c6c112d716069ccc169283b9838fa2f951c625b3d4ca0a8f05b")
                                )),
                                derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H")))
                            )
                        )),
                        index: 0,
                        derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/0H/1238H"),
                        displayName: "Main"
                    ),
                    try! OnNetwork.Account(
                        address: OnNetwork.Account.EntityAddress(
                            address: "account_tdx_a_1qvlrgnqrvk6tzmg8z6lusprl3weupfkmu52gkfhmncjsnhn0kp"
                        ),
                        securityState: .unsecured(.init(
                            genesisFactorInstance: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorInstance(.init(
                                factorSourceReference: .init(
                                    factorSourceKind: .curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSourceKind,
                                    factorSourceID: "09bfa80bcc9b75d6ad82d59730f7b179cbc668ba6ad4008721d5e6a179ff55f1"
                                ),
                                publicKey: .curve25519(.init(
                                    compressedRepresentation: Data(
                                        hexString: "b862c4ef84a4a97c37760636f6b94d1fba7b4881ac15a073f6c57e2996bbeca8")
                                )),
                                derivationPath: .accountPath(.init(derivationPath: "m/44H/1022H/10H/525H/1H/1238H")))
                            )
                        )),
                        index: 1,
                        derivationPath: .init(derivationPath: "m/44H/1022H/10H/525H/1H/1238H"),
                        displayName: "Secondary"
                    )
                ]
            }
        )
    }
}
