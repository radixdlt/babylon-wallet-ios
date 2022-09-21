import Profile
import UserDefaultsClient

public extension ProfileLoader {
	static func live(
		userDefaultsClient: UserDefaultsClient
	) -> Self {
		Self(
			loadProfile: {
				guard let profileName = userDefaultsClient.profileName else {
					struct NoProfileFoundInUserDefaults: Swift.Error {}
					throw NoProfileFoundInUserDefaults()
				}
				do {
					return try Profile(name: profileName)
				} catch {
					throw Self.Error.failedToDecode
				}
			}
		)
	}
}

public extension ProfileLoader {
	enum Error: String, Swift.Error, Equatable {
		case failedToDecode
	}
}
