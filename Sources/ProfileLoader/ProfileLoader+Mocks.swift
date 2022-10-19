import Profile
import XCTestDynamicOverlay

#if DEBUG
public extension ProfileLoader {
	static let unimplemented = Self(
		loadProfile: XCTUnimplemented("\(Self.self).loadProfile")
	)
}
#endif
