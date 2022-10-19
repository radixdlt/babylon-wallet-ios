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
    public var getAppPreferences: GetAppPreferences
    public var setAppPreferences: SetAppPreferences
    
    
}

public extension WalletClient {
    // ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
    typealias InjectProfileSnapshot = @Sendable (ProfileSnapshot) throws -> Void
    typealias ExtractProfileSnapshot = @Sendable () throws -> ProfileSnapshot
    typealias GetAccounts = @Sendable () throws -> [OnNetwork.Account]
    typealias GetAppPreferences = @Sendable () throws -> AppPreferences
    typealias SetAppPreferences = @Sendable (AppPreferences) throws -> Void
    // ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
}


public extension WalletClient {
    static let live: Self = {
        let profileHolder = ProfileHolder()
        return Self(
            injectProfileSnapshot: {
                try profileHolder.injectProfileSnapshot($0)
            },
            extractProfileSnapshot: {
                try profileHolder.takeProfileSnapshot()
            },
            getAccounts: {
                try profileHolder.get { profile in
                    profile.primaryNet.accounts.rawValue.elements
                }
            },
            getAppPreferences: {
                try profileHolder.get { profile in
                    profile.appPreferences
                }
            },
            setAppPreferences: { appPreferences in
                try profileHolder.setting { profile in
                    profile.appPreferences = appPreferences
                }
            }
        )
    }()
}

private final class ProfileHolder {
    private var profile: Profile?
    
    struct NoProfile: Swift.Error {}
    
    
    @discardableResult
    func get<T>(_ withProfile: (Profile) throws -> T) throws -> T {
        guard let profile else {
            throw NoProfile()
        }
        return try withProfile(profile)
    }
    
    func setting(_ setProfile: (inout Profile) throws -> Void) throws -> Void {
        guard var profile else {
            throw NoProfile()
        }
        try setProfile(&profile)
        self.profile = profile
        return
    }
    
    func injectProfileSnapshot(_ profileSnapshot: ProfileSnapshot) throws {
        self.profile = try .init(snapshot: profileSnapshot)
    }
    
    func takeProfileSnapshot() throws -> ProfileSnapshot {
        try get { profile in
            profile.snaphot()
        }
    }
}

public extension WalletClient {
    static func mock() -> Self {
        Self(
            injectProfileSnapshot: { _ in /* No op */ },
            extractProfileSnapshot: { fatalError("Impl me") },
            getAccounts: {
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
