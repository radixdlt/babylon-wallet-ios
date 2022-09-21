import Profile
import XCTestDynamicOverlay

#if DEBUG
public extension ProfileLoader {
	static let noop = Self(
		loadProfile: {
			try! Profile(name: "profileName")
		}
	)

	static let unimplemented = Self(
		loadProfile: XCTUnimplemented("\(Self.self).loadProfile")
	)
}
#endif
