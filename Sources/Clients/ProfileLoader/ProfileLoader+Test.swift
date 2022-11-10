import Dependencies
import Profile
import XCTestDynamicOverlay

// MARK: - ProfileLoader + TestDependencyKey
extension ProfileLoader: TestDependencyKey {
	public static let previewValue = Self(
		loadProfile: { nil }
	)

	public static let testValue = Self(
		loadProfile: unimplemented("\(Self.self).loadProfile")
	)
}

public extension DependencyValues {
	var profileLoader: ProfileLoader {
		get { self[ProfileLoader.self] }
		set { self[ProfileLoader.self] = newValue }
	}
}
