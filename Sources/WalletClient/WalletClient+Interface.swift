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
    public var setDisplayAppPreferences: SetDisplayAppPreferences
    
    
}

public extension WalletClient {
    // ALL METHOD MUST BE THROWING! SINCE IF A PROFILE HAS NOT BEEN INJECTED WE SHOULD THROW AN ERROR
    typealias InjectProfileSnapshot = @Sendable (ProfileSnapshot) throws -> Void
    typealias ExtractProfileSnapshot = @Sendable () throws -> ProfileSnapshot
    typealias GetAccounts = @Sendable () throws -> [OnNetwork.Account]
    typealias GetAppPreferences = @Sendable () throws -> AppPreferences
    typealias SetDisplayAppPreferences = @Sendable (AppPreferences.Display) throws -> Void
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
            setDisplayAppPreferences: { display in
                try profileHolder.setting { profile in
                    
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
