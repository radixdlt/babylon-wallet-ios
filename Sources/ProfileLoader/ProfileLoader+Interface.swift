import ComposableArchitecture
import Profile

// MARK: - ProfileLoader
public struct ProfileLoader {
	public var loadProfile: @Sendable () async throws -> Profile
}

public extension ProfileLoader {
	enum Error: Swift.Error, Equatable {
		case noProfileDocumentFoundAtPath(String)
		case failedToLoadProfileFromDocument
	}
}
