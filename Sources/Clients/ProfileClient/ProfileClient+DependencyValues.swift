import Dependencies
import Foundation

// MARK: - ProfileClient + TestDependencyKey
extension ProfileClient: TestDependencyKey {
	#if DEBUG
	public static let previewValue = Self.mock()
	public static let testValue = Self.unimplemented
	#endif // DEBUG
}

public extension DependencyValues {
	var profileClient: ProfileClient {
		get { self[ProfileClient.self] }
		set { self[ProfileClient.self] = newValue }
	}
}
