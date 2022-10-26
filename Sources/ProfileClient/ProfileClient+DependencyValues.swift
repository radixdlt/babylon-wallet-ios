import ComposableArchitecture
import Foundation

// MARK: - ProfileClientKey
public enum ProfileClientKey: DependencyKey {}
public extension ProfileClientKey {
	typealias Value = ProfileClient
	static let liveValue = ProfileClient.live
	static let testValue = ProfileClient.mock()
}

public extension DependencyValues {
	var profileClient: ProfileClient {
		get { self[ProfileClientKey.self] }
		set { self[ProfileClientKey.self] = newValue }
	}
}
