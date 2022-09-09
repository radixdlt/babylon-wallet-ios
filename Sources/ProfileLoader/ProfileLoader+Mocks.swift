import Profile
import XCTestDynamicOverlay

#if DEBUG
public extension ProfileLoader {
	static let noop = Self(
		loadProfile: {
			Profile(name: "profileName")
		}
	)

	static let unimplemented = Self(
		loadProfile: XCTUnimplemented("\(Self.self).loadProfile")
	)
}
#endif
