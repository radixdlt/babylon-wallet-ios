import Foundation
import Resources

// MARK: - Profile.LoadingFailure
extension Profile {
	public enum LoadingFailure: Sendable, Swift.Error, Hashable {
		case profileVersionOutdated(
			json: Data,
			version: ProfileSnapshot.Version
		)

		case decodingFailure(json: Data, JSONDecodingError)

		// This might happen to due to incompatible version, and some
		// potential discrepancy in version check, or due to some internal
		// error when creating a profile from a snapshot.
		case failedToCreateProfileFromSnapshot(FailedToCreateProfileFromSnapshot)
	}
}

extension Profile {
	public struct FailedToCreateProfileFromSnapshot: Sendable, LocalizedError, Hashable {
		public let version: ProfileSnapshot.Version
		public let error: Swift.Error
		public init(version: ProfileSnapshot.Version, error: Error) {
			self.version = version
			self.error = error
		}
	}

	public enum JSONDecodingError: Sendable, LocalizedError, Equatable {
		case known(KnownDecodingError)
		case unknown(UnknownDecodingError)
	}
}

extension Profile.FailedToCreateProfileFromSnapshot {
	public static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.version == rhs.version && String(describing: lhs.error) == String(describing: rhs.error)
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(version)
		hasher.combine(String(describing: error))
	}

	public var errorDescription: String? { L10n.ProfileLoad.failedToCreateProfileFromSnapshotError(error, version) }
}

// MARK: - Profile.JSONDecodingError + Hashable
extension Profile.JSONDecodingError: Hashable {
	public var errorDescription: String? {
		switch self {
		case let .known(error):
			return error.localizedDescription
		case let .unknown(error):
			return error.localizedDescription
		}
	}

	public enum KnownDecodingError: Sendable, LocalizedError, Hashable {
		case noProfileSnapshotVersionFoundInJSON
		case decodingError(FailedToDecodeProfile)

		public func hash(into hasher: inout Hasher) {
			hasher.combine(String(describing: self))
		}

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
	public struct FailedToDecodeProfile: Sendable, LocalizedError, Equatable {
		public let decodingError: Swift.DecodingError
		public init(decodingError: DecodingError) {
			self.decodingError = decodingError
		}

		public var errorDescription: String? { L10n.ProfileLoad.decodingError(decodingError) }
	}

	public struct UnknownDecodingError: Sendable, LocalizedError, Hashable {
		public static func == (lhs: Self, rhs: Self) -> Bool {
			String(describing: lhs.error) == String(describing: rhs.error)
		}

		public func hash(into hasher: inout Hasher) {
			hasher.combine(String(describing: self))
		}

		public let error: Swift.Error
		public var errorDescription: String? { L10n.ProfileLoad.decodingError(error) }

		public init(error: Error) {
			self.error = error
		}
	}
}
