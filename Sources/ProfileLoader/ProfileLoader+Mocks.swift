import Foundation
import Profile

#if DEBUG
public extension ProfileLoader {
	static let noop = Self(
		loadProfile: {
			Profile(name: "profileName")
		}
	)
}
#endif
