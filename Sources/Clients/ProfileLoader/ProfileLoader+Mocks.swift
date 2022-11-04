import Profile
import XCTestDynamicOverlay

#if DEBUG
public extension ProfileLoader {
	static let testValue = Self(
		loadProfile: unimplemented("\(Self.self).loadProfile")
	)
}
#endif
