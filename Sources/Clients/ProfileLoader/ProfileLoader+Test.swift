import Profile
#if DEBUG
import Dependencies
import XCTestDynamicOverlay

// MARK: - ProfileLoader + TestDependencyKey
extension ProfileLoader: TestDependencyKey {
	public static let previewValue = Self(
		loadProfile: { .noProfile }
	)

	public static let testValue = Self(
		loadProfile: unimplemented("\(Self.self).loadProfile")
	)
}
#endif // DEBUG

public extension DependencyValues {
	var profileLoader: ProfileLoader {
		get { self[ProfileLoader.self] }
		set { self[ProfileLoader.self] = newValue }
	}
}
