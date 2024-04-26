import Foundation
import Sargon

// MARK: - Header + Identifiable
extension Header: Identifiable {
	public typealias ID = ProfileID
}

extension ProfileSnapshotVersion {
	public static let minimum = Self(rawValue: 100)!
}

// MARK: - ProfileSnapshotVersion + Comparable
extension ProfileSnapshotVersion: Comparable {}

extension Header {
	public typealias Version = ProfileSnapshotVersion

	public struct IncompatibleProfileVersion: LocalizedError, Equatable {
		public let decodedVersion: Version
		public let minimumRequiredVersion: Version
		public var errorDescription: String? {
			"\(Self.self): decodedVersion: \(decodedVersion), but Profile requires a minimum version of: \(minimumRequiredVersion)"
		}
	}

	public func validateCompatibility() throws {
		let minimumRequiredVersion: ProfileSnapshotVersion = .minimum

		guard snapshotVersion >= minimumRequiredVersion else {
			throw IncompatibleProfileVersion(
				decodedVersion: snapshotVersion,
				minimumRequiredVersion: minimumRequiredVersion
			)
		}
	}

	public func isVersionCompatible() -> Bool {
		do {
			try validateCompatibility()
			return true
		} catch {
			return false
		}
	}
}
