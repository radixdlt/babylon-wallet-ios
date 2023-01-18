import ClientPrelude
import Profile

// MARK: - Profile.LoadingFailure
public extension Profile {
	enum LoadingFailure: Sendable, Swift.Error, Equatable {
		case profileVersionOutdated(json: Data, version: ProfileSnapshot.Version)
		case decodingFailure(json: Data, JSONDecodingError)

		// This might happen to due to incompatible version, and some
		// potential discrepancy in version check, or due to some internal
		// error when creating a profile from a snapshot.
		case failedToCreateProfileFromSnapshot(FailedToCreateProfileFromSnapshot)
	}
}

public extension Profile {
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

		public var errorDescription: String? { L10n.ProfileLoad.failedToCreateProfileFromSnapshotError(error, version) }
	}

	enum JSONDecodingError: Sendable, LocalizedError, Equatable {
		case known(KnownDecodingError)
		case unknown(UnknownDecodingError)
	}
}

public extension Profile.JSONDecodingError {
	var errorDescription: String? {
		switch self {
		case let .known(error):
			return error.localizedDescription
		case let .unknown(error):
			return error.localizedDescription
		}
	}

	enum KnownDecodingError: Sendable, LocalizedError, Equatable {
		case noProfileSnapshotVersionFoundInJSON
		case decodingError(FailedToDecodeProfile)

		public var errorDescription: String? {
			switch self {
			case .noProfileSnapshotVersionFoundInJSON:
				return L10n.ProfileLoad.decodingError("Unknown version")
			case let .decodingError(error):
				return error.localizedDescription
			}
		}
	}

	// Swift.DecodingError made `Equatable` inside `EngineToolkitModels`
	struct FailedToDecodeProfile: Sendable, LocalizedError, Equatable {
		public let decodingError: Swift.DecodingError
		public init(decodingError: DecodingError) {
			self.decodingError = decodingError
		}

		public var errorDescription: String? { L10n.ProfileLoad.decodingError(decodingError) }
	}

	struct UnknownDecodingError: Sendable, LocalizedError, Equatable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			lhs.errorDescription == rhs.errorDescription
		}

		public let error: Swift.Error
		public var errorDescription: String? { L10n.ProfileLoad.decodingError(error) }

		public init(error: Error) {
			self.error = error
		}
	}
}
