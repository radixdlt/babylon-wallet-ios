import Profile
import XCTestDynamicOverlay

#if DEBUG
public extension ProfileLoader {
	static let unimplemented = Self(
		loadProfileSnapshot: XCTUnimplemented("\(Self.self).loadProfileSnapshot is unimplemented"),
		loadProfile: XCTUnimplemented("\(Self.self).loadProfile is unimplemented")
	)
}
#endif
