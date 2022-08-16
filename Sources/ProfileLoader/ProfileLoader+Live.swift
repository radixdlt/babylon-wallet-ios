import ComposableArchitecture
import Profile
import UserDefaultsClient

public extension ProfileLoader {
	static func live(
		userDefaultsClient: UserDefaultsClient
	) -> Self {
		Self(
			loadProfile: {
				guard let profileName = userDefaultsClient.profileName else {
					throw Error.noProfileDocumentFoundAtPath("UserDefaults")
				}

				return Profile(name: profileName)
			}
		)
	}
}
