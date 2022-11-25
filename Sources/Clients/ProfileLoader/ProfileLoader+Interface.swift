import Dependencies
import Foundation
import Profile

// MARK: - ProfileSnapshot.Version + Sendable
extension ProfileSnapshot.Version: @unchecked Sendable {}

// MARK: - ProfileLoader
public struct ProfileLoader: Sendable, DependencyKey {
	public var loadProfile: @Sendable () async -> Result
}

// MARK: ProfileLoader.Result
public extension ProfileLoader {
	enum Result: Sendable, Equatable {
		case noProfile
		case profileVersionOutdated(json: Data, version: ProfileSnapshot.Version)

		case decodingFailure(json: Data, JSONDecodingError)

		// This might happen to due to incompatible version, and some
		// potential discrepancy in version check, or due to some internal
		// error when creatin a profile from a snapshot.
		case failedToCreateProfileFromSnapshot(FailedToCreateProfileFromSnapshot)
		case compatibleProfile(Profile)
	}
}

public extension ProfileLoader {
	struct FailedToCreateProfileFromSnapshot: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.snapshot == rhs.snapshot && lhs.errorDescription == rhs.errorDescription
		}

		public let snapshot: ProfileSnapshot
		public let error: Swift.Error
		public var errorDescription: String? { "Failed to create profile from snapshot, error: \(String(describing: error)), snapshot: \(String(describing: snapshot))" }
	}

	enum JSONDecodingError: Sendable, LocalizedError, Equatable {
		case known(KnownDecodingError)
		case unknown(UnknownDecodingError)
	}
}

public extension ProfileLoader.JSONDecodingError {
	// Swift.DecodingError made `Equatable` inside `EngineToolkit`
	struct KnownDecodingError: Sendable, LocalizedError, Equatable {
		public let decodingError: Swift.DecodingError
		public var errorDescription: String? { "Failed to decode profile: \(String(describing: decodingError))" }
	}

	struct UnknownDecodingError: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.errorDescription == rhs.errorDescription
		}

		public let error: Swift.Error
		public var errorDescription: String? { "Failed to decode profile: \(String(describing: error))" }
	}
}
