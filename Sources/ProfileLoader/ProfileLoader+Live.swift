import Combine
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
					return Fail(
						outputType: Profile.self,
						failure: Error.noProfileDocumentFoundAtPath("UserDefaults")
					)
					.eraseToEffect()
				}

				return Just(Profile(name: profileName))
					.setFailureType(to: Error.self)
					.eraseToEffect()
			}
		)
	}
}
