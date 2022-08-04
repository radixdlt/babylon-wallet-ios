import ComposableArchitecture
import Profile

// MARK: - ProfileLoader
public struct ProfileLoader {
	public var loadProfile: () -> Effect<Profile, Error>
}

public extension ProfileLoader {
	enum Error: Swift.Error, Equatable {
		case noProfileDocumentFoundAtPath(String)
		case failedToLoadProfileFromDocument
	}
}

#if DEBUG
public extension ProfileLoader {
	static let noop = Self(
		loadProfile: { .none }
	)
}
#endif // DEBUG
