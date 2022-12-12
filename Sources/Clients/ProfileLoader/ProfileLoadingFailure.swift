import Foundation
import Profile
import Version

// MARK: - ProfileLoader.ProfileLoadingFailure
public extension ProfileLoader {
	enum ProfileLoadingFailure: Sendable, Swift.Error, Equatable {
		case profileVersionOutdated(json: Data, version: ProfileSnapshot.Version)

		case decodingFailure(json: Data, JSONDecodingError)

		// This might happen to due to incompatible version, and some
		// potential discrepancy in version check, or due to some internal
		// error when creatin a profile from a snapshot.
		case failedToCreateProfileFromSnapshot(FailedToCreateProfileFromSnapshot)
	}
}

public extension ProfileLoader {
	struct FailedToCreateProfileFromSnapshot: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.version == rhs.version && lhs.errorDescription == rhs.errorDescription
		}

		public let version: ProfileSnapshot.Version
		public let error: Swift.Error
		public init(version: ProfileSnapshot.Version, error: Error) {
			self.version = version
			self.error = error
		}

		public var errorDescription: String? { "Failed to create profile from snapshot, error: \(String(describing: error)), version: \(String(describing: version))" }
	}

	enum JSONDecodingError: Sendable, LocalizedError, Equatable {
		case known(KnownDecodingError)
		case unknown(UnknownDecodingError)
	}
}

public extension ProfileLoader.JSONDecodingError {
	var errorDescription: String? {
		switch self {
		case let .known(error):
			return error.localizedDescription
		case let .unknown(error):
			return error.localizedDescription
		}
	}

	// Swift.DecodingError made `Equatable` inside `EngineToolkit`
	struct KnownDecodingError: Sendable, LocalizedError, Equatable {
		public let decodingError: Swift.DecodingError
		public init(decodingError: DecodingError) {
			self.decodingError = decodingError
		}

		public var errorDescription: String? { "Failed to decode profile: \(String(describing: decodingError))" }
	}

	struct UnknownDecodingError: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.errorDescription == rhs.errorDescription
		}

		public let error: Swift.Error
		public var errorDescription: String? { "Failed to decode profile: \(String(describing: error))" }

		public init(error: Error) {
			self.error = error
		}
	}
}
